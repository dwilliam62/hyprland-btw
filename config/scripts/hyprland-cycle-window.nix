{pkgs}:
pkgs.writeShellScriptBin "hyprland-cycle-window" ''
  #!/usr/bin/env bash
  set -euo pipefail

  get_layout() {
    ${pkgs.hyprland}/bin/hyprctl -j getoption general:layout | ${pkgs.jq}/bin/jq -r '.str'
  }

  action="''${1:-next}"
  layout="$(get_layout)"

  case "$action" in
    next|prev) ;;
    *) echo "Usage: $(basename "$0") [next|prev]" >&2; exit 1 ;;
  esac

  if [[ "$layout" == "master" || "$layout" == "monocle" ]]; then
    ${pkgs.hyprland}/bin/hyprctl dispatch layoutmsg "cycle$action"
  else
    if [[ "$action" == "next" ]]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch cyclenext
    else
      ${pkgs.hyprland}/bin/hyprctl dispatch cyclenext prev
    fi
  fi
''
