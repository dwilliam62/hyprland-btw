{pkgs}:
pkgs.writeShellScriptBin "config-menu" ''
  #!/usr/bin/env bash
  set -euo pipefail

  EDITOR_BIN="''${EDITOR:-nvim}"
  TERM_BIN="''${TERMINAL:-}"

  pick_term() {
    if [ -n "''${TERM_BIN}" ] && command -v "''$TERM_BIN" >/dev/null 2>&1; then
      echo "''$TERM_BIN"
      return
    fi
    for t in kitty foot alacritty wezterm ghostty; do
      if command -v "''$t" >/dev/null 2>&1; then
        echo "''$t"
        return
      fi
    done
  }

  # Find repo directory
  repo=""
  for candidate in "''$HOME/hyprland-btw" "''$HOME/Hyprland-btw"; do
    if [ -d "''$candidate" ] && [ -f "''$candidate/flake.nix" ]; then
      repo="''$candidate"
      break
    fi
  done
  if [ -z "''$repo" ]; then
    echo "Error: hyprland-btw repo not found in ''$HOME" >&2
    exit 1
  fi

  # Create temp file for name->path mapping
  tmpmap=$(mktemp)
  trap "rm -f $tmpmap" EXIT

  # All config files with their display names
  files_data=(
    "flake.nix:''$repo/flake.nix"
    "home.nix:''$repo/home.nix"
    "configuration.nix:''$repo/configuration.nix"
    "host-default.nix:''$repo/hosts/$(hostname)/default.nix"
    "host-hardware.nix:''$repo/hosts/$(hostname)/hardware.nix"
    "config/hypr/hyprland.lua:''$repo/config/hypr/hyprland.lua"
    "config/hypr/lua/animations.lua:''$repo/config/hypr/lua/animations.lua"
    "config/hypr/lua/decorations.lua:''$repo/config/hypr/lua/decorations.lua"
    "config/hypr/lua/env.lua:''$repo/config/hypr/lua/env.lua"
    "config/hypr/lua/keybinds.lua:''$repo/config/hypr/lua/keybinds.lua"
    "config/hypr/lua/monitors.lua:''$repo/config/hypr/lua/monitors.lua"
    "config/hypr/lua/settings.lua:''$repo/config/hypr/lua/settings.lua"
    "config/hypr/lua/startup.lua:''$repo/config/hypr/lua/startup.lua"
    "config/hypr/lua/user_overrides.lua:''$repo/config/hypr/lua/user_overrides.lua"
    "config/hypr/lua/window_rules.lua:''$repo/config/hypr/lua/window_rules.lua"
    "config/hypr/lua/workspaces.lua:''$repo/config/hypr/lua/workspaces.lua"
    "config/packages.nix:''$repo/config/packages.nix"
    "config/fonts.nix:''$repo/config/fonts.nix"
    "config/.zshrc-personal:''$repo/config/.zshrc-personal"
    "config/.bashrc-personal:''$repo/config/.bashrc-personal"
    #"config/kitty/kitty.conf:''$repo/config/kitty/kitty.conf"
  )

  # Build display list and mapping, only for existing files
  for entry in "''${files_data[@]}"; do
    display=$(echo "''$entry" | cut -d: -f1)
    path=$(echo "''$entry" | cut -d: -f2-)
    if [ -f "''$path" ]; then
      echo "''$display|''$path" >> "''$tmpmap"
    fi
  done

  # Show rofi menu with sorted display names only
  choice=$(cut -d'|' -f1 "''$tmpmap" | sort | rofi -dmenu -i -config "''$HOME/.config/rofi/config-menu.rasi" -p ' Edit Config')
  [ -z "''$choice" ] && exit 0

  # Look up path from mapping
  target=$(grep "^''$choice|" "''$tmpmap" | cut -d'|' -f2)
  [ -z "''$target" ] && exit 1

  term="$(pick_term)"
  if [ -n "''$term" ] && [[ "''$EDITOR_BIN" =~ ^(nvim|vim|vi|nano|helix|hx)$ ]]; then
    exec "''$term" -e "''$EDITOR_BIN" "''$target"
  else
    exec "''$EDITOR_BIN" "''$target"
  fi
''
