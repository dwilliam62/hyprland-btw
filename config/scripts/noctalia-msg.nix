{pkgs}:
pkgs.writeShellScriptBin "noctalia-msg" ''
  #!/usr/bin/env bash
  set -euo pipefail

  resolve_wayland_display() {
    if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      echo "$WAYLAND_DISPLAY"
      return 0
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
        echo "$base"
        return 0
      fi
    done

    return 1
  }

  if [ "$#" -eq 0 ]; then
    exec noctalia msg --help
  fi

  if display="$(resolve_wayland_display)"; then
    WAYLAND_DISPLAY="$display" exec noctalia msg "$@"
  else
    exec noctalia msg "$@"
  fi
''
