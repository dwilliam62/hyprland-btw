{pkgs}:
pkgs.writeShellScriptBin "session-logout" ''
  set -euo pipefail

  is_hyprland=0
  is_mango=0

  if [ "''${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ] || pgrep -x Hyprland >/dev/null 2>&1; then
    is_hyprland=1
  fi

  if [ "''${XDG_CURRENT_DESKTOP:-}" = "mango" ] || pgrep -x mango >/dev/null 2>&1; then
    is_mango=1
  fi

  # 1. Exit Hyprland cleanly
  if [ "$is_hyprland" -eq 1 ]; then
    echo "hl.dispatch(hl.dsp.exit())" | ${pkgs.hyprland}/bin/hyprctl repl >/dev/null 2>&1 || true
    ${pkgs.hyprland}/bin/hyprctl dispatch exit >/dev/null 2>&1 || true
    ${pkgs.procps}/bin/pkill -u "''${USER:-$(${pkgs.coreutils}/bin/id -un)}" -x Hyprland 2>/dev/null || true
  fi

  # 2. Exit Mango cleanly
  if [ "$is_mango" -eq 1 ]; then
    if command -v mmsg >/dev/null 2>&1; then
      mmsg dispatch quit >/dev/null 2>&1 || true
    elif [ -x /run/current-system/sw/bin/mmsg ]; then
      /run/current-system/sw/bin/mmsg dispatch quit >/dev/null 2>&1 || true
    fi
    ${pkgs.procps}/bin/pkill -u "''${USER:-$(${pkgs.coreutils}/bin/id -un)}" -x mango 2>/dev/null || true
  fi

  # 3. Terminate seat session via loginctl
  if command -v loginctl >/dev/null 2>&1; then
    cur_user="''${USER:-$(${pkgs.coreutils}/bin/id -un)}"
    for s in $(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="''$cur_user" '($3==u || $2==u){print $1}'); do
      loginctl terminate-session "''$s" 2>/dev/null || true
    done
  fi

  # 4. Fallback process termination
  sleep 0.5
  ${pkgs.procps}/bin/pkill -u "''${USER:-$(${pkgs.coreutils}/bin/id -un)}" -x "Hyprland|mango" 2>/dev/null || true
''
