{pkgs}:
pkgs.writeShellScriptBin "noctalia-msg" ''
  #!/usr/bin/env bash
  set -euo pipefail

  candidate_displays=()

  add_candidate_display() {
    local candidate="$1"
    [ -n "$candidate" ] || return 0

    local existing=""
    for existing in "''${candidate_displays[@]}"; do
      if [ "$existing" = "$candidate" ]; then
        return 0
      fi
    done

    candidate_displays+=("$candidate")
  }

  collect_wayland_displays() {
    candidate_displays=()

    if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      add_candidate_display "$WAYLAND_DISPLAY"
    fi

    local runtime_dir="''${XDG_RUNTIME_DIR:-}"
    if [ -z "$runtime_dir" ]; then
      runtime_dir="/run/user/$(${pkgs.coreutils}/bin/id -u)"
    fi

    local sock=""
    for sock in "$runtime_dir"/noctalia-wayland-*.sock; do
      if [ -S "$sock" ]; then
        local base
        base="$(${pkgs.coreutils}/bin/basename "$sock")"
        base="''${base#noctalia-}"
        base="''${base%.sock}"
        add_candidate_display "$base"
      fi
    done
  }

  run_noctalia_msg() {
    local display="$1"
    shift

    if [ -n "$display" ]; then
      WAYLAND_DISPLAY="$display" noctalia msg "$@"
    else
      noctalia msg "$@"
    fi
  }

  run_with_display_fallbacks() {
    local -a args=("$@")
    local output=""
    local status=1
    local display=""

    if [ "''${#candidate_displays[@]}" -eq 0 ]; then
      if output="$(run_noctalia_msg "" "''${args[@]}" 2>&1)"; then
        if [ -n "$output" ]; then
          printf '%s\n' "$output"
        fi
        return 0
      fi

      status=$?
      if [ -n "$output" ]; then
        printf '%s\n' "$output" >&2
      fi
      return "$status"
    fi

    for display in "''${candidate_displays[@]}"; do
      if output="$(run_noctalia_msg "$display" "''${args[@]}" 2>&1)"; then
        if [ -n "$output" ]; then
          printf '%s\n' "$output"
        fi
        return 0
      fi
      status=$?
    done

    if [ -n "$output" ]; then
      printf '%s\n' "$output" >&2
    fi
    return "$status"
  }

  if [ "$#" -eq 0 ]; then
    exec noctalia msg --help
  fi

  collect_wayland_displays
  if run_with_display_fallbacks "$@"; then
    exit 0
  fi

  exec noctalia msg "$@"
''
