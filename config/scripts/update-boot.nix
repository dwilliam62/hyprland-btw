{pkgs}:
pkgs.writeShellScriptBin "update-boot" ''
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

  # No systemd-machined pre-flight here, unlike update: `boot` only builds and
  # sets the boot entry, so nothing is activated in the running session and the
  # socket activation conflict cannot happen.

  # Perform update & boot, activated on next boot
  if command -v nh >/dev/null 2>&1; then
    exec nh os boot --update "$FLAKE_DIR" "$@"
  else
    echo "Updating flake inputs in $FLAKE_DIR..."
    nix flake update --flake "$FLAKE_DIR"
    exec sudo nixos-rebuild boot --flake "$FLAKE_DIR" "$@"
  fi
''
