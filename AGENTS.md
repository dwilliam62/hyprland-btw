# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Commands

### Building and Deploying
- **Build system toplevel (dry build / verification without switching):**
  ```bash
  nix build .#nixosConfigurations.hyprland-btw.config.system.build.toplevel
  ```
- **Apply configuration switch:**
  ```bash
  sudo nixos-rebuild switch --flake .#hyprland-btw
  ```
- **Apply configuration on next boot (used by installer):**
  ```bash
  sudo nixos-rebuild boot --flake .#hyprland-btw
  ```
- **Test configuration without adding boot entry:**
  ```bash
  sudo nixos-rebuild test --flake .#hyprland-btw
  ```
- **Apply using `nh` (Nix Helper):**
  ```bash
  nh os switch .
  nh os test .
  ```

### Flake Checks and Maintenance
- **Check flake evaluation:**
  ```bash
  nix flake check
  ```
- **Update flake lock inputs:**
  ```bash
  nix flake update
  ```

### Formatting
- **Format Nix files (using Alejandra):**
  ```bash
  nix fmt
  ```

### Installation
- **Run automated setup script:**
  ```bash
  ./install.sh
  # Or non-interactive
  ./install.sh --non-interactive
  ```

---

## High-Level Architecture & Structure

This repository provides a single-host NixOS + Hyprland configuration managed as a Nix Flake with integrated Home Manager.

```
hyprland-btw/
├── flake.nix                  # Flake entrypoint & inputs (nixpkgs, home-manager, nixvim, noctalia, alejandra)
├── configuration.nix          # System-level NixOS configuration
├── hardware-configuration.nix # Machine-specific hardware generation (imported by configuration.nix)
├── home.nix                   # User-level Home Manager entrypoint for primary user ('dwilliams')
├── install.sh                 # Provisioning script (hardware detection, config patching, build)
├── modules/
│   ├── drivers/               # Modular GPU & VM driver toggles (amd, intel, nvidia, vm-guest-services)
│   └── overlays.nix           # Nixpkgs overlays (pinned Neovim from stable, synfetch, dwarfs hotfix)
└── config/                    # Modular application configs, dotfiles, and scripts
    ├── cli/                   # CLI tool configurations (btop, cava, git, htop)
    ├── editors/               # Editor modules (bugsvim.nix [active], nixvim.nix, nvf.nix, vscode.nix)
    ├── hypr/                  # Hyprland Lua/Conf configs, animations, keybinds, window rules
    ├── noctalia.nix           # Noctalia QuickShell systemd user service and launcher
    ├── overview.nix           # Quickshell workspace overview
    ├── packages.nix           # System-wide package declarations
    ├── fonts.nix              # Font packages configuration
    ├── nh.nix                 # Nix Helper (nh) configuration
    ├── scripts/               # Custom shell/Rofi scripts packaged via pkgs.writeShellScriptBin
    ├── terminals/             # Terminal modules (alacritty, ghostty, kitty, wezterm, foot, st)
    ├── wallpapers/            # Bundled wallpapers seeded to ~/Pictures/Wallpapers on activation
    ├── waybar/                # Alternative Waybar status bar configuration
    ├── yazi/                  # Yazi file manager configuration and theme
    └── zsh.nix                # Zsh shell setup and plugins
```

### Key Architectural Concepts

1. **Flake & System Integration (`flake.nix` & `configuration.nix`)**
   - The primary system target is `nixosConfigurations.hyprland-btw` on `x86_64-linux`.
   - Home Manager is loaded as a NixOS module (`home-manager.nixosModules.home-manager`) rather than standalone, applying `useGlobalPkgs = true` and `useUserPackages = true`.
   - `specialArgs = { inherit inputs; };` propagates flake inputs into system and Home Manager modules.

2. **Modular Driver Toggles (`modules/drivers/`)**
   - GPU and VM drivers are configured via module flags in `configuration.nix`:
     - `drivers.amdgpu.enable = true|false;`
     - `drivers.intel.enable = true|false;`
     - `drivers.nvidia.enable = true|false;` (supports PRIME offload/sync settings)
     - `vm.guest-services.enable = true|false;` (QEMU/Spice guest agent)
   - The single-host model expects exactly one primary GPU driver profile active (or VM guest services if virtualized).

3. **Neovim & Package Overlays (`modules/overlays.nix`)**
   - Neovim is pinned to `nixpkgs-stable` (`nixos-25.05` channel) to prevent breaking changes from `nixpkgs-unstable`.
   - Active Neovim configuration is driven by `config/editors/bugsvim.nix` (with `nixvim.nix` and `nvf.nix` available as alternative configurations in `config/editors/`).
   - Contains a C++ compiler flag overlay hotfix for `dwarfs` (gearlever dependency).

4. **Desktop Shell & Hyprland (`config/noctalia.nix` & `config/hypr/`)**
   - Hyprland is enabled system-wide (`programs.hyprland.enable = true`) and configured primarily through Lua (`config/hypr/hyprland.lua` and `config/hypr/lua/*.lua`), symlinked to `~/.config/hypr`.
   - `noctalia.nix` manages the Noctalia QuickShell desktop shell via a systemd user service (`noctalia.service`), running a polling wrapper script that waits for `WAYLAND_DISPLAY` availability.
   - Display manager defaults to `displayManager.ly` with Matrix animation; `greetd`/`tuigreet` configuration is available as an alternative in `configuration.nix`.

5. **Home Manager Activation Hooks (`home.nix`)**
   - Wallpaper seeding: `home.activation.seedWallpapers` copies images from `./config/wallpapers` into `~/Pictures/Wallpapers` on activation without overwriting existing files.
   - User dotfiles (`.config/hypr`, `.config/waybar`, `.config/fastfetch`, `.config/tmux/tmux.conf`, `.config/starship.toml`, etc.) are declaratively managed via `home.file`.
