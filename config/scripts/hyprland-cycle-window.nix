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

  # Hyprland 0.56 removed the legacy bare-word dispatchers: `hyprctl dispatch
  # <dispatcher> <args>` is now shorthand for `hl.dispatch(<lua>)`, so the old
  # `layoutmsg "cycle$action"` / `cyclenext [prev]` forms silently did nothing.
  if [[ "$layout" == "master" || "$layout" == "monocle" ]]; then
    # Layout messages keep their lowercase legacy spelling ("cyclenext").
    ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.layout('cycle$action')"
  else
    if [[ "$action" == "next" ]]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.window.cycle_next({ next = true })"
    else
      ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.window.cycle_next({ next = false })"
    fi
  fi
''
