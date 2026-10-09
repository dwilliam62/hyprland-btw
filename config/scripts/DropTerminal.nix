{pkgs}:
pkgs.writeShellScriptBin "DropTerminal" ''
  #!/usr/bin/env bash
  # Dropdown Terminal for Hyprland (Nix-managed)
  # Source: adapted from Dropterminal.sh by Kiran George (SherLock707)
  #
  # Usage:
  #   DropTerminal [-d|--debug] [-S|--spawn-only] [<terminal_command>]
  #
  # Behavior:
  #   - No argument uses kitty with the dedicated dropdown class.
  #
  # Hyprland 0.56+ exposes dispatchers only through the Lua API: `hyprctl
  # dispatch <dispatcher> <args>` is now shorthand for `hl.dispatch(<lua>)`, so
  # legacy dispatcher names such as `togglefloating address:0x...` fail. Every
  # window operation below therefore goes through the Lua API first and only
  # falls back to the legacy syntax on older Hyprland builds.
  #
  # A tiled dropdown window is worse than a missing one: Hyprland interprets
  # move/resize on a tiled window as a dwindle split-ratio change, which
  # progressively shrinks the window and squeezes the rest of the layout. Every
  # geometry change is therefore gated behind a verified "window is floating"
  # check, and a window that cannot be floated is recreated rather than moved.

  set -euo pipefail

  DEBUG=false
  SPAWN_ONLY=false

  # The hidden state is "parked just above the monitor" on the current
  # workspace. Special workspaces are deliberately NOT used: Hyprland reports
  # windows on a special workspace as fullscreen and then refuses move, resize
  # and pin for them (the fullscreen flag even persists after the window leaves
  # the workspace), which makes the dropdown unusable.

  ADDR_FILE="/tmp/dropdown_terminal_addr"
  STATE_FILE="/tmp/dropdown_terminal_state"
  LOCK_FILE="/tmp/dropdown_terminal_lock"
  LAST_TOGGLE_FILE="/tmp/dropdown_terminal_last_toggle"
  MIN_TOGGLE_INTERVAL_MS=250

  DROPDOWN_CLASS="kitty-dropterm"

  # Dropdown size and position configuration (percentages)
  WIDTH_PERCENT=65  # Width as percentage of screen width
  HEIGHT_PERCENT=65 # Height as percentage of screen height
  Y_PERCENT=10      # Y position as percentage from top (X is auto-centered)

  # Animation settings
  SLIDE_STEPS=5
  SLIDE_DELAY_MS=5

  HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
  JQ="${pkgs.jq}/bin/jq"
  FLOCK="${pkgs.util-linux}/bin/flock"
  DATE="${pkgs.coreutils}/bin/date"
  BC="${pkgs.bc}/bin/bc"

  # ---------------------------------------------------------------------------
  # Logging, timing and JSON helpers
  # ---------------------------------------------------------------------------
  debug_echo() {
    if [ "$DEBUG" = true ]; then
      echo "$@" >&2
    fi
  }

  sleep_ms() {
    local ms="$1"
    if [[ "$ms" =~ ^[0-9]+$ ]]; then
      sleep "$(printf '%d.%03d' $((ms / 1000)) $((ms % 1000)))"
    else
      sleep 0.01
    fi
  }

  # Sanitize Hyprland JSON to strict JSON (work around NaN/Inf issues)
  hyprjson() {
    "$HYPRCTL" "$@" -j 2>/dev/null | sed -E 's/: *nan([,}])/ : null\1/gi; s/: *-nan([,}])/ : null\1/gi; s/: *inf([,}])/ : null\1/gi; s/: *-inf([,}])/ : null\1/gi'
  }

  # ---------------------------------------------------------------------------
  # Hyprland dispatch layer (Lua API first, legacy syntax as fallback)
  # ---------------------------------------------------------------------------

  # Run a Lua dispatch expression, e.g. "hl.dsp.window.float({ ... })".
  # Returns non-zero when neither the Lua dispatch path nor the Lua REPL is
  # available, so callers can fall back to the legacy dispatcher syntax.
  hl_lua() {
    local expr="$1"
    "$HYPRCTL" dispatch "$expr" >/dev/null 2>&1 && return 0
    "$HYPRCTL" repl "return hl.dispatch($expr)" >/dev/null 2>&1
  }

  # NOTE: these helpers are best effort. The Lua API reports "ok" even when the
  # window selector matched nothing, so callers must verify window state
  # instead of trusting the exit status.
  hl_float_on() {
    hl_lua "hl.dsp.window.float({ window = \"address:$1\", action = \"on\" })" ||
      "$HYPRCTL" dispatch togglefloating "address:$1" >/dev/null 2>&1 || true
  }

  # Clear a compositor-side fullscreen state. A window that requested fullscreen
  # itself (for example kitty remembering a fullscreen size) can ignore this, so
  # callers verify the result instead of trusting the exit status.
  hl_unset_fullscreen() {
    hl_lua "hl.dsp.window.fullscreen({ window = \"address:$1\", action = \"unset\" })" ||
      "$HYPRCTL" dispatch fullscreenstate "0 0,address:$1" >/dev/null 2>&1 || true
  }

  hl_pin() {
    hl_lua "hl.dsp.window.pin({ window = \"address:$1\" })" ||
      "$HYPRCTL" dispatch pin "address:$1" >/dev/null 2>&1 || true
  }

  hl_resize() {
    hl_lua "hl.dsp.window.resize({ window = \"address:$1\", x = $2, y = $3, exact = true })" ||
      "$HYPRCTL" dispatch resizewindowpixel "exact $2 $3,address:$1" >/dev/null 2>&1 || true
  }

  hl_move() {
    hl_lua "hl.dsp.window.move({ window = \"address:$1\", x = $2, y = $3, exact = true })" ||
      "$HYPRCTL" dispatch movewindowpixel "exact $2 $3,address:$1" >/dev/null 2>&1 || true
  }

  hl_focus() {
    hl_lua "hl.dsp.focus({ window = \"address:$1\" })" ||
      "$HYPRCTL" dispatch focuswindow "address:$1" >/dev/null 2>&1 || true
  }

  hl_move_to_workspace() {
    local addr="$1" ws="$2" ws_arg
    if [[ "$ws" =~ ^[0-9]+$ ]]; then
      ws_arg="$ws"
    else
      ws_arg="\"$ws\""
    fi
    hl_lua "hl.dsp.window.move({ window = \"address:$addr\", workspace = $ws_arg, follow = false })" ||
      "$HYPRCTL" dispatch movetoworkspacesilent "$ws,address:$addr" >/dev/null 2>&1 || true
  }

  hl_close() {
    hl_lua "hl.dsp.window.close({ window = \"address:$1\" })" ||
      "$HYPRCTL" dispatch killwindow "address:$1" >/dev/null 2>&1 || true
  }

  # Launch a command through Hyprland's exec dispatcher. The command is passed
  # as a Lua long string, so window-rule hints ("[float;size ...;move ...] cmd")
  # and shell quoting survive untouched. The bracket level is raised until the
  # command cannot terminate the long string early.
  hl_exec() {
    local cmd="$1" eq="" i
    for i in 1 2 3 4 5; do
      case "$cmd" in
        *"]$eq]"*) eq="$eq=" ;;
        *) break ;;
      esac
    done
    hl_lua "hl.dsp.exec_cmd([$eq[$cmd]$eq])" && return 0
    "$HYPRCTL" dispatch exec "$cmd" >/dev/null 2>&1 || true
  }

  # ---------------------------------------------------------------------------
  # Window queries. All state decisions are derived from the live window, never
  # from the cached state file (which can go stale after a crash or reload).
  # ---------------------------------------------------------------------------
  # Output columns: float, pinned, workspace, x, y, w, h, monitor, fullscreen
  win_info() {
    hyprjson clients 2>/dev/null | "$JQ" -r --arg ADDR "$1" '
      [.[] | select(.address == $ADDR)] | .[0] // empty |
      [ (.floating // false),
        (.pinned // false),
        (.workspace.name // ((.workspace.id // 0) | tostring)),
        (.at[0] // 0),
        (.at[1] // 0),
        (.size[0] // 0),
        (.size[1] // 0),
        (.monitor // 0),
        (.fullscreen // 0) ] | @tsv' 2>/dev/null || true
  }

  win_field() {
    win_info "$1" | cut -f"$2"
  }

  window_exists() { [ -n "$(win_field "$1" 3)" ]; }
  window_is_float() { [ "$(win_field "$1" 1)" = "true" ]; }
  window_is_pinned() { [ "$(win_field "$1" 2)" = "true" ]; }
  window_is_fullscreen() { [ "$(win_field "$1" 9)" != "0" ]; }
  window_workspace() { win_field "$1" 3; }

  # Top edge (y) of the monitor a window lives on
  monitor_top() {
    local mon_id y
    mon_id=$(win_field "$1" 8)
    if ! [[ "$mon_id" =~ ^-?[0-9]+$ ]]; then
      echo 0
      return 0
    fi
    y=$(hyprjson monitors 2>/dev/null | "$JQ" -r --argjson MID "$mon_id" '.[] | select(.id == $MID) | .y' 2>/dev/null) || true
    if ! [[ "$y" =~ ^-?[0-9]+$ ]]; then
      y=0
    fi
    echo "$y"
  }

  # Hidden means parked fully above its monitor. Multi-monitor aware: uses the
  # monitor top edge rather than assuming y < 0.
  window_is_hidden() {
    local addr="$1" y h mon_y
    y=$(win_field "$addr" 5)
    h=$(win_field "$addr" 7)
    mon_y=$(monitor_top "$addr")
    if [[ "$y" =~ ^-?[0-9]+$ && "$h" =~ ^[0-9]+$ ]]; then
      if [ $((y + h)) -le "$mon_y" ]; then
        return 0
      fi
    fi
    return 1
  }

  # ---------------------------------------------------------------------------
  # Verified state initialization
  # ---------------------------------------------------------------------------
  # 0 = the window is floating (verified, not assumed)
  ensure_floating() {
    local addr="$1" i
    if ! window_exists "$addr"; then
      return 1
    fi
    if window_is_float "$addr"; then
      return 0
    fi
    debug_echo "ensure_floating: floating $addr"
    hl_float_on "$addr"
    for i in $(seq 1 15); do
      sleep_ms 20
      if window_is_float "$addr"; then
        debug_echo "ensure_floating: $addr is floating"
        return 0
      fi
    done
    debug_echo "ensure_floating: could not float $addr"
    return 1
  }

  # A fullscreen window cannot be moved, resized or pinned. Clear the state when
  # possible and report whether the window can be laid out at all.
  ensure_not_fullscreen() {
    local addr="$1" i
    if ! window_is_fullscreen "$addr"; then
      return 0
    fi
    debug_echo "ensure_not_fullscreen: clearing fullscreen on $addr"
    hl_unset_fullscreen "$addr"
    for i in $(seq 1 15); do
      sleep_ms 20
      if ! window_is_fullscreen "$addr"; then
        debug_echo "ensure_not_fullscreen: $addr is no longer fullscreen"
        return 0
      fi
    done
    debug_echo "ensure_not_fullscreen: $addr is still fullscreen"
    return 1
  }

  ensure_pinned() {
    local addr="$1" i
    if window_is_pinned "$addr"; then
      return 0
    fi
    hl_pin "$addr"
    for i in $(seq 1 15); do
      sleep_ms 20
      if window_is_pinned "$addr"; then
        return 0
      fi
    done
    debug_echo "ensure_pinned: could not pin $addr"
    return 1
  }

  # pin is a toggle, so it is only ever called while the window is pinned
  ensure_unpinned() {
    local addr="$1" i
    if ! window_is_pinned "$addr"; then
      return 0
    fi
    hl_pin "$addr"
    for i in $(seq 1 15); do
      sleep_ms 20
      if ! window_is_pinned "$addr"; then
        return 0
      fi
    done
    debug_echo "ensure_unpinned: could not unpin $addr"
    return 1
  }

  # Geometry is only ever applied to a floating window. This is the guard that
  # keeps a stuck tiled dropdown from mangling the tiling layout.
  apply_dropdown_layout() {
    local addr="$1" x="$2" y="$3" w="$4" h="$5"
    if ! ensure_not_fullscreen "$addr"; then
      debug_echo "apply_dropdown_layout: $addr is fullscreen, refusing to resize/move"
      return 1
    fi
    if ! ensure_floating "$addr"; then
      debug_echo "apply_dropdown_layout: $addr is not floating, refusing to resize/move"
      return 1
    fi
    hl_resize "$addr" "$w" "$h"
    hl_move "$addr" "$x" "$y"
    return 0
  }

  # ---------------------------------------------------------------------------
  # Slide animations (only meaningful while floating)
  # ---------------------------------------------------------------------------
  animate_slide_down() {
    local addr="$1" target_x="$2" target_y="$3" height="$4"
    local start_y=$((target_y - height - 50))
    local step_y=$(((target_y - start_y) / SLIDE_STEPS))
    local i current_y

    debug_echo "slide down: $addr to $target_x,$target_y"

    hl_move "$addr" "$target_x" "$start_y"
    sleep_ms 50
    for i in $(seq 1 "$SLIDE_STEPS"); do
      current_y=$((start_y + (step_y * i)))
      hl_move "$addr" "$target_x" "$current_y"
      sleep_ms "$SLIDE_DELAY_MS"
    done
    hl_move "$addr" "$target_x" "$target_y"
  }

  animate_slide_up() {
    local addr="$1" start_x="$2" start_y="$3" height="$4"
    local end_y=$((start_y - height - 50))
    local step_y=$(((start_y - end_y) / SLIDE_STEPS))
    local i current_y

    debug_echo "slide up: $addr from $start_x,$start_y"

    for i in $(seq 1 "$SLIDE_STEPS"); do
      current_y=$((start_y - (step_y * i)))
      hl_move "$addr" "$start_x" "$current_y"
      sleep_ms "$SLIDE_DELAY_MS"
    done
    hl_move "$addr" "$start_x" "$end_y"
  }

  # ---------------------------------------------------------------------------
  # Monitor / position helpers
  # ---------------------------------------------------------------------------
  get_monitor_info() {
    local monitor_data
    monitor_data=$(hyprjson monitors | "$JQ" -er 'map(select(.focused == true)) | .[0] | "\(.x) \(.y) \(.width) \(.height) \(.scale // 1) \(.name)"' 2>/dev/null) || monitor_data=""
    if [ -z "$monitor_data" ]; then
      monitor_data=$("$HYPRCTL" monitors 2>/dev/null | awk '
        /^Monitor / {name=$2; sub(/\(.*/, "", name); x=y=w=h=scale=""; focused="no"}
        / at / {
          split($1, res, "x"); w=res[1]; split(res[2], tmp, "@"); h=tmp[1]
          split($4, pos, "x"); x=pos[1]; y=pos[2]
        }
        /scale:/ {scale=$2}
        /focused:/ {focused=$2}
        /^$/ {
          if (focused=="yes" && x!="" && y!="" && w!="" && h!="" && scale!="" && name!="") {
            print x, y, w, h, scale, name; exit
          }
        }
        END {
          if (focused=="yes" && x!="" && y!="" && w!="" && h!="" && scale!="" && name!="") {
            print x, y, w, h, scale, name
          }
        }')
    fi
    if [ -z "$monitor_data" ] || [[ "$monitor_data" =~ ^null ]]; then
      debug_echo "Error: could not get focused monitor information"
      return 1
    fi
    echo "$monitor_data"
  }

  # Prints "x y width height monitor monitor_y" in logical coordinates, where
  # monitor_y is the top edge of the focused monitor. Always succeeds: callers
  # rely on a usable position rather than on an exit status.
  calculate_dropdown_position() {
    local monitor_info
    if ! monitor_info=$(get_monitor_info); then
      debug_echo "Warning: failed to read monitor info, using fallback geometry"
      echo "100 100 800 600 fallback-monitor"
      return 0
    fi

    local mon_x mon_y mon_width mon_height mon_scale mon_name
    mon_x=$(echo "$monitor_info" | cut -d' ' -f1)
    mon_y=$(echo "$monitor_info" | cut -d' ' -f2)
    mon_width=$(echo "$monitor_info" | cut -d' ' -f3)
    mon_height=$(echo "$monitor_info" | cut -d' ' -f4)
    mon_scale=$(echo "$monitor_info" | cut -d' ' -f5)
    mon_name=$(echo "$monitor_info" | cut -d' ' -f6)

    debug_echo "Monitor info: x=$mon_x y=$mon_y ''${mon_width}x''${mon_height} scale=$mon_scale"

    if ! [[ "$mon_x" =~ ^-?[0-9]+$ && "$mon_y" =~ ^-?[0-9]+$ && "$mon_width" =~ ^[0-9]+$ && "$mon_height" =~ ^[0-9]+$ ]]; then
      debug_echo "Warning: invalid monitor info, using fallback geometry"
      echo "100 100 800 600 fallback-monitor"
      return 0
    fi

    if [ -z "$mon_scale" ] || [ "$mon_scale" = "null" ] || [ "$mon_scale" = "0" ]; then
      mon_scale="1.0"
    fi

    # Logical dimensions = physical dimensions / scale
    local logical_width logical_height
    if [ -x "$BC" ]; then
      logical_width=$(echo "scale=0; $mon_width / $mon_scale" | "$BC" | cut -d'.' -f1)
      logical_height=$(echo "scale=0; $mon_height / $mon_scale" | "$BC" | cut -d'.' -f1)
    else
      local scale_int
      scale_int=$(echo "$mon_scale" | sed 's/\.//' | sed 's/^0*//')
      if [ -z "$scale_int" ]; then scale_int=100; fi
      logical_width=$(((mon_width * 100) / scale_int))
      logical_height=$(((mon_height * 100) / scale_int))
    fi

    if ! [[ "$logical_width" =~ ^-?[0-9]+$ ]]; then logical_width=$mon_width; fi
    if ! [[ "$logical_height" =~ ^-?[0-9]+$ ]]; then logical_height=$mon_height; fi

    local width=$((logical_width * WIDTH_PERCENT / 100))
    local height=$((logical_height * HEIGHT_PERCENT / 100))
    local y_offset=$((logical_height * Y_PERCENT / 100))
    local x_offset=$(((logical_width - width) / 2))

    local final_x=$((mon_x + x_offset))
    local final_y=$((mon_y + y_offset))

    debug_echo "Dropdown geometry: ''${width}x''${height} at $final_x,$final_y (logical)"
    echo "$final_x $final_y $width $height $mon_name $mon_y"
    return 0
  }

  get_current_workspace() {
    local ws
    ws=$(hyprjson activeworkspace 2>/dev/null | "$JQ" -r '.name // empty' 2>/dev/null) || true
    if [ -z "$ws" ] || [ "$ws" = "null" ]; then
      ws=$(hyprjson activeworkspace 2>/dev/null | "$JQ" -r '.id // empty' 2>/dev/null) || true
    fi
    if [ -z "$ws" ] || [ "$ws" = "null" ]; then
      ws=1
    fi
    echo "$ws"
  }

  # ---------------------------------------------------------------------------
  # Terminal discovery
  # ---------------------------------------------------------------------------
  get_terminal_address() {
    if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then
      cut -d' ' -f1 "$ADDR_FILE"
    fi
  }

  get_terminal_monitor() {
    if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then
      cut -d' ' -f2- "$ADDR_FILE"
    fi
  }

  find_terminal_by_class() {
    hyprjson clients 2>/dev/null | "$JQ" -r --arg CLASS "$DROPDOWN_CLASS" '
      first(.[] | select((.class // "") == $CLASS or (.initialClass // "") == $CLASS) | .address) // empty' 2>/dev/null || true
  }

  # Find a dropdown window that did not exist before a launch
  find_new_terminal_by_class() {
    local before="$1"
    hyprjson clients 2>/dev/null | "$JQ" -r --argjson BEFORE "$before" --arg CLASS "$DROPDOWN_CLASS" '
      first(.[] | select((.class // "") == $CLASS or (.initialClass // "") == $CLASS)
                | select(.address as $a | ($BEFORE | index($a)) == null)
                | .address) // empty' 2>/dev/null || true
  }

  resolve_terminal_address() {
    local addr recovered monitor_name
    addr=$(get_terminal_address)
    if [ -n "$addr" ] && window_exists "$addr"; then
      echo "$addr"
      return 0
    fi

    recovered=$(find_terminal_by_class)
    if [ -n "$recovered" ] && [ "$recovered" != "null" ]; then
      monitor_name=$(get_monitor_info | awk '{print $6}') || true
      echo "$recovered $monitor_name" >"$ADDR_FILE"
      echo "$recovered"
      return 0
    fi

    rm -f "$ADDR_FILE"
    return 1
  }

  # ---------------------------------------------------------------------------
  # State transitions
  # ---------------------------------------------------------------------------
  set_hidden_state() {
    echo "$1" >"$STATE_FILE"
  }

  # Park the window just above its monitor, on whatever workspace it already
  # lives on. The hidden state is then derived from geometry alone and the
  # window never occupies tiling space.
  hide_window() {
    local addr="$1" geometry start_x start_y height mon_y hidden_y
    if window_is_hidden "$addr"; then
      ensure_unpinned "$addr" || true
      set_hidden_state "hidden"
      debug_echo "hide_window: $addr is already hidden"
      return 0
    fi

    geometry=$(win_info "$addr")
    if [ -n "$geometry" ]; then
      start_x=$(echo "$geometry" | cut -f4)
      start_y=$(echo "$geometry" | cut -f5)
      height=$(echo "$geometry" | cut -f7)
    fi
    if ! [[ "$start_x" =~ ^-?[0-9]+$ && "$start_y" =~ ^-?[0-9]+$ && "$height" =~ ^[0-9]+$ ]]; then
      local pos_info
      pos_info=$(calculate_dropdown_position)
      start_x=$(echo "$pos_info" | cut -d' ' -f1)
      start_y=$(echo "$pos_info" | cut -d' ' -f2)
      height=$(echo "$pos_info" | cut -d' ' -f4)
    fi

    mon_y=$(monitor_top "$addr")
    hidden_y=$((mon_y - height - 50))

    if window_is_float "$addr" && ! window_is_fullscreen "$addr"; then
      animate_slide_up "$addr" "$start_x" "$start_y" "$height"
    else
      debug_echo "hide_window: $addr cannot be animated, parking it directly"
    fi

    # Absolute move, so the window always ends up fully off-screen
    hl_move "$addr" "$start_x" "$hidden_y"
    ensure_unpinned "$addr" || true
    set_hidden_state "hidden"
    debug_echo "hide_window: $addr parked at $start_x,$hidden_y"
    return 0
  }

  show_window() {
    local addr="$1" pos_info x y w h mon mon_y current_ws hidden_y
    current_ws=$(get_current_workspace)
    pos_info=$(calculate_dropdown_position)
    x=$(echo "$pos_info" | cut -d' ' -f1)
    y=$(echo "$pos_info" | cut -d' ' -f2)
    w=$(echo "$pos_info" | cut -d' ' -f3)
    h=$(echo "$pos_info" | cut -d' ' -f4)
    mon=$(echo "$pos_info" | cut -d' ' -f5)
    mon_y=$(echo "$pos_info" | cut -d' ' -f6)
    if ! [[ "$mon_y" =~ ^-?[0-9]+$ ]]; then
      mon_y=0
    fi
    hidden_y=$((mon_y - h - 50))

    # A fullscreen window ignores move/resize, and a tiled window turns them
    # into dwindle split changes: neither may be laid out.
    if ! ensure_not_fullscreen "$addr"; then
      debug_echo "show_window: $addr is fullscreen, refusing to resize/move"
      return 1
    fi
    if ! ensure_floating "$addr"; then
      debug_echo "show_window: $addr is not floating, refusing to resize/move"
      return 1
    fi

    # Size it and park it above the screen before bringing it to the workspace
    hl_resize "$addr" "$w" "$h"
    hl_move "$addr" "$x" "$hidden_y"
    hl_move_to_workspace "$addr" "$current_ws"
    echo "$addr $mon" >"$ADDR_FILE"

    ensure_pinned "$addr" || true
    animate_slide_down "$addr" "$x" "$y" "$h"
    hl_focus "$addr"
    set_hidden_state "shown"
    debug_echo "show_window: $addr shown at $x,$y ''${w}x''${h} on $mon"
    return 0
  }

  # A dropdown window that cannot be floated is unusable and would corrupt the
  # tiling layout, so it is killed and recreated on the next press.
  reset_terminal() {
    local addr="$1" i
    debug_echo "reset_terminal: recreating dropdown terminal $addr"
    ensure_unpinned "$addr" || true
    hl_close "$addr"
    for i in $(seq 1 20); do
      sleep_ms 25
      if ! window_exists "$addr"; then
        break
      fi
    done
    rm -f "$ADDR_FILE" "$STATE_FILE"
  }

  # ---------------------------------------------------------------------------
  # Spawn
  # ---------------------------------------------------------------------------
  spawn_terminal() {
    local pos_info x y w h mon mon_y hidden_y before_addrs launch_cmd new_addr i
    pos_info=$(calculate_dropdown_position)
    x=$(echo "$pos_info" | cut -d' ' -f1)
    y=$(echo "$pos_info" | cut -d' ' -f2)
    w=$(echo "$pos_info" | cut -d' ' -f3)
    h=$(echo "$pos_info" | cut -d' ' -f4)
    mon=$(echo "$pos_info" | cut -d' ' -f5)
    mon_y=$(echo "$pos_info" | cut -d' ' -f6)
    if ! [[ "$mon_y" =~ ^-?[0-9]+$ ]]; then
      mon_y=0
    fi
    hidden_y=$((mon_y - h - 50))

    debug_echo "spawn: $TERMINAL_CMD -> ''${w}x''${h} at $x,$y on $mon (parked at y=$hidden_y)"

    before_addrs=$(hyprjson clients 2>/dev/null | "$JQ" -c '[.[].address]' 2>/dev/null) || true
    if [ -z "$before_addrs" ]; then
      before_addrs='[]'
    fi

    # Window-rule hints make the window float at the dropdown size and park it
    # above the monitor from birth, so it never joins the tiling layout even for
    # a frame. Special workspaces are not used here: Hyprland reports windows on
    # a special workspace as fullscreen and then rejects move/resize/pin.
    launch_cmd="[float;size $w $h;move $x $hidden_y] $TERMINAL_CMD"
    hl_exec "$launch_cmd"

    new_addr=""
    for i in $(seq 1 40); do
      sleep_ms 50
      new_addr=$(find_new_terminal_by_class "$before_addrs")
      if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
        break
      fi
      new_addr=""
    done

    # Older Hyprland builds may not support exec rule hints; retry plainly
    if [ -z "$new_addr" ]; then
      debug_echo "spawn: hinted launch produced no window, retrying without hints"
      hl_exec "$TERMINAL_CMD"
      for i in $(seq 1 40); do
        sleep_ms 50
        new_addr=$(find_new_terminal_by_class "$before_addrs")
        if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
          break
        fi
        new_addr=""
      done
    fi

    if [ -z "$new_addr" ]; then
      debug_echo "spawn: failed to detect the dropdown terminal window"
      return 1
    fi

    echo "$new_addr $mon" >"$ADDR_FILE"
    debug_echo "spawn: window created at $new_addr"

    # Normalize the new window: not fullscreen, floating, sized, positioned,
    # unpinned and parked above the monitor.
    if ! ensure_not_fullscreen "$new_addr"; then
      debug_echo "spawn: new window is fullscreen, killing it to protect the layout"
      hl_close "$new_addr"
      rm -f "$ADDR_FILE" "$STATE_FILE"
      return 1
    fi
    if ! ensure_floating "$new_addr"; then
      debug_echo "spawn: new window is not floating, killing it to protect the layout"
      hl_close "$new_addr"
      rm -f "$ADDR_FILE" "$STATE_FILE"
      return 1
    fi
    hl_resize "$new_addr" "$w" "$h"
    hl_move "$new_addr" "$x" "$hidden_y"
    hide_window "$new_addr"
    return 0
  }

  # ---------------------------------------------------------------------------
  # Argument parsing
  # ---------------------------------------------------------------------------
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d | --debug)
        DEBUG=true
        shift
        ;;
      -S | --spawn-only)
        SPAWN_ONLY=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  # Env override for startup usage
  if [ "''${DROPTERM_SPAWN_ONLY-}" = "1" ]; then
    SPAWN_ONLY=true
  fi

  # Terminal command: default to kitty with the dropdown class.
  # kitty >= 0.49 defaults to remember_window_size yes, which makes a new kitty
  # window come up fullscreen here; such a window ignores the move/resize/pin
  # dispatches the dropdown depends on. Pin the size explicitly so the dropdown
  # does not depend on the global kitty config.
  KITTY_CMD="kitty --class $DROPDOWN_CLASS --override remember_window_size=no"

  TERMINAL_CMD="$*"
  if [ -z "$TERMINAL_CMD" ] || [ "$TERMINAL_CMD" = "ghostty" ] || [ "$TERMINAL_CMD" = "kitty" ]; then
    TERMINAL_CMD="$KITTY_CMD"
  elif [[ "$TERMINAL_CMD" == foot* ]]; then
    TERMINAL_CMD="foot --app-id=$DROPDOWN_CLASS"
  elif [[ "$TERMINAL_CMD" == alacritty* ]]; then
    TERMINAL_CMD="alacritty --class $DROPDOWN_CLASS"
  elif [[ "$TERMINAL_CMD" == wezterm* ]]; then
    TERMINAL_CMD="wezterm start --class $DROPDOWN_CLASS"
  elif [[ "$TERMINAL_CMD" != *"$DROPDOWN_CLASS"* ]]; then
    TERMINAL_CMD="$KITTY_CMD"
  fi

  debug_echo "DropTerminal start (debug enabled): spawn_only=$SPAWN_ONLY"

  # Ensure only one instance runs at a time (prevents overlapping animations).
  # The lock is released when the script exits and fd 9 is closed.
  exec 9>"$LOCK_FILE"
  if ! "$FLOCK" -n 9; then
    debug_echo "DropTerminal: lock held, exiting"
    exit 0
  fi

  # Debounce rapid toggles
  now_ms=""
  if "$DATE" +%s%3N >/dev/null 2>&1; then
    now_ms=$("$DATE" +%s%3N)
  else
    now_ms=$(( $("$DATE" +%s) * 1000 ))
  fi
  if [ -f "$LAST_TOGGLE_FILE" ]; then
    last_ms=$(cat "$LAST_TOGGLE_FILE" 2>/dev/null || echo 0)
    if [ -n "$last_ms" ] && [ "$last_ms" -ge 0 ] 2>/dev/null; then
      delta_ms=$((now_ms - last_ms))
      if [ "$delta_ms" -lt "$MIN_TOGGLE_INTERVAL_MS" ] 2>/dev/null; then
        debug_echo "Toggle debounced (''${delta_ms}ms)"
        exit 0
      fi
    fi
  fi
  echo "$now_ms" >"$LAST_TOGGLE_FILE"

  # ---------------------------------------------------------------------------
  # Main logic
  # ---------------------------------------------------------------------------
  TERMINAL_ADDR=$(resolve_terminal_address || true)

  # Self-heal: a dropdown that is stuck fullscreen or tiled (for example because
  # a keybind toggled it, or because an older kitty came up fullscreen) is
  # recreated instead of being moved, because move/resize on such a window either
  # does nothing or corrupts the tiling layout.
  if [ -n "$TERMINAL_ADDR" ]; then
    if ! ensure_not_fullscreen "$TERMINAL_ADDR" || ! ensure_floating "$TERMINAL_ADDR"; then
      debug_echo "Existing dropdown window is unusable (fullscreen or tiled), recreating it"
      reset_terminal "$TERMINAL_ADDR"
      TERMINAL_ADDR=""
    fi
  fi

  if [ -z "$TERMINAL_ADDR" ]; then
    debug_echo "No dropdown terminal found, creating one"
    if spawn_terminal; then
      TERMINAL_ADDR=$(get_terminal_address)
    fi
  fi

  if [ -z "$TERMINAL_ADDR" ]; then
    debug_echo "No dropdown terminal available"
    exit 1
  fi

  if [ "$SPAWN_ONLY" = true ]; then
    debug_echo "Spawn-only: leaving the dropdown hidden"
    hide_window "$TERMINAL_ADDR"
    exit 0
  fi

  if window_is_hidden "$TERMINAL_ADDR"; then
    show_window "$TERMINAL_ADDR"
  else
    hide_window "$TERMINAL_ADDR"
  fi
''
