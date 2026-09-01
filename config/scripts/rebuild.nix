{pkgs}:
pkgs.writeShellScriptBin "rebuild" ''
  #!/usr/bin/env bash
  set -eo pipefail

  # Locate flake directory
  FLAKE_DIR=""
  for candidate in "$PWD" "$HOME/hyprland-btw" "$HOME/Projects/ddubs/hyprland-btw" "$HOME/Projects/LinuxBeginnings/hyprland-btw"; do
    if [ -f "$candidate/flake.nix" ]; then
      FLAKE_DIR="$candidate"
      break
    fi
  done

  if [ -z "$FLAKE_DIR" ]; then
    echo "Error: hyprland-btw flake not found in current directory or standard paths." >&2
    exit 1
  fi

  # Pre-flight fix: prevent systemd-machined socket conflict during live activation
  if systemctl is-active --quiet systemd-machined.service 2>/dev/null; then
    echo "Pre-flight: resetting systemd-machined to prevent socket activation conflict..."
    sudo systemctl stop systemd-machined.service 2>/dev/null || true
    sudo systemctl start systemd-machined.socket 2>/dev/null || true
  fi

  # Perform rebuild
  if command -v nh >/dev/null 2>&1; then
    exec nh os switch "$FLAKE_DIR" "$@"
  else
    exec sudo nixos-rebuild switch --flake "$FLAKE_DIR" "$@"
  fi
''
