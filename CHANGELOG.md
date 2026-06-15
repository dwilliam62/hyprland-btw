# CHANGELOG for Hyprland-btw project

## Started: 11/17/25

## Author: Don Williams (ddubs)

## Inspired by: Tony,btw YouTube Video. (See README.md)

#### Hyprland-btw v0.4.5

- Changed `fastfetch` logo
- Added `cliamp` and `shortwave`

### Hyprland-btw v0.4.4

- Updated noctalia to v5.0.0
- Added systemd user service to start noctalia
- Updated keybinds for new version

#### Hyprland-btw v0.4.3

- Add: `wayle` Alternaive waybar option
- Updated `yazi` config for current version
  - Using HomeMgr to copy source files right now
  - Will convert to NIX later

#### Hyprland-btw v0.4.2

- Replaced noctalia flake with nixpkgs
- Replaced `quickshell` with `noctalia-qs`
- Add: `synfech`
- Replaced noctalia flake with nixpkgs
- Replaced `quickshell` with `noctalia-qs`
- Fixed workspace bindings

#### Hyprland-btw v0.4.1

- Added `appimage-run` and `gearlever`
- Removed `onlyoffice`
- Updated Hyprland to v0.55
- Migrated to LUA completely!
- Disabled `systemd gpt auto`
  - It enables swap partitions automatically
  - Converted to `zramswap` instead
- Updated to 7.0.x kernel
- Disable `webdav` it fails to build
- Fixed write permission errors w/`bigvim` on rebuild
  - HomeMgr now makes dir writeable
- Added `noctalia-qs` Their forked version of `quickshell`
- Pinned `neovim` to v11.5 from v12.0
  - NeoVIM v12.x breaks inline images for snacks plugin and markdown
  - Also pinned `tree-sitter` to v25.x

#### Hyprland-btw v0.4.0

- Added support for Intel-NVIDIA Hybrid laptops in `install.sh`
- Created branches for `hyprland-btw` VM and `XPS15` laptop
- Main branch is a copy of the VM branch
- Added config file for `btop`
- Added `bugsvim` NeoVIM configuration
- Fixed `overview` bindings
- Added volume controls

#### Hyprland-btw v0.3.9

- Added `SUPERALT Arrow`` keybinds for `swapwindow` L/R, U/D
- Hyprland v0.54.3
- Added `scolling` and `monocle` layouts
- Added layout toggle `SUPERALT + L`
- `SUPERALT + 1..4` for specific layouts
  - `SUPERALT + 1` = `dwindle`
  - `SUPERALT + 2` = `master`
  - `SUPERALT + 3` = `scrolling`
  - `SUPERALT + 4` = `monocle`
  - `SUPER J/K` now maps to current layout mode
  - Added notifications for layouts
- Added NixOS icon to notifications

#### Hyprland-btw v0.3.8

- Disabled `noctalia-shell` systemd service
- It would load an older version of `noctalia-shell`
- It's not started from Hyprland `exec-once`
- As aa result the bindings had to be changed

#### Hyprland-btw v0.3.7

- Updated flake, Hyprland v0.53
  - Updated ly to start hyprland with `start-hyprland`
  - Hyprland v0.53+ now has safe-mode on crashes

#### Hyprland-btw v0.3.6

- Added `st` terminal from `gh0st` repo
  - [gh0stzk](https://github.com/gh0stzk/st-terminal)
  - Well featured with image support
  - Fast, low mem usuage

#### Hyprland-btw v0.3.5

- Added `virtualization.nix`
  - Managed docker,podman, libvirt and virtmgr
- Added pipewire `low-latency` configuration
- Noctalia imported twice. (Thanks Prince)
- Moved default login mgr to `tuigreet`
  - `ly` won't mask `nixbldxxx` users
  - Makes the initial login confusing as username not there
  - You have to scroll through users, and change to `hyprland`
  - Hopefully that will get fixed
  - Code is still in place, just disabled
- Added `NeoVIM` to system packages
  - was only in home mgr so root did not have it

#### Hyprland-btw v0.3.4

- Removed Java from `bugsvim.nix`
- Updated `nixvim.nix` to current configuration
  - nearly identical to `bugsvim`
- Added user systemd service for `noctalia-shell`
- Updated Hyprland bindings to accommodate the change

#### Hyprland-btw v0.3.3

- `bugsvim` to current version with `blink-cmp`
- Icons changed from nixpkgs `candy-icons` to local `al-beautyline`
- Disabled `nh` garbage collect
  - Enabled `nic.gc` in `configuration.nix`
  - `nh` didn't seem to be purging old generations
- Set home manager to backup conflicting files during rebuilds
- Updated version to v0.3.3

#### Hyprland-btw v0.3.2

- Removed: duplicate rofi-legacy.menu.nix file
  - Thanks @Ducky for finding this
- Added: `upower.enable=true;
  - Resolves issue with noctalia-shell and laptop batteries
  - Thanks @Prince for fixing this

#### Hyprland-btw v0.3.1

- Added `alejandra` as formatter in `flake.nix`
  - Ran `nix fmt ./`
- Removed permit insecure package for electron.
  - No longer needed
- Removed duplicate home mgr config in flake.nix

#### Hyprland-btw v0.3.0

- `nixvim` now uses `alejandra` for NIX formatting
- Updated Noctalia to current build
- Updated Flake

#### Hyprland-btw v0.2.9

- `nixvim` now uses `alejandra` for NIX formatting
- Updated Noctalia to current build

- Ported `nixvim` updates from ddubsOS
  - Added image preview via chafa
  - `leader fm` to search
  - Currently not supporting `webp` formats
    - nixpkg wasn't compiled with libwebp
  - Eventually will switch to `viu`
    - Better quality
    - More image format support
    - Problem is media plugin hardwired for `chafa`
- Updated flake -`noctalia-shell` updates:
  - start up from `qs-c noctalia-shell` to `noctalia-shell`
  - Results in starting most current version installed
  - Changed keybindings to match

#### Hyprland-btw v0.2.8

- NEW: Added `quickshell-overview` integration
  - Workspace overview with live window previews
  - Toggled via `SUPER + Tab` keybind
  - Drag-and-drop workspace navigation
  - Uses IPC for seamless Hyprland integration
  - QML code managed via Home Manager activation script

#### Hyprland-btw v0.2.7

- Updated flake
- Moved termainls NIX files to own subdir `config/terminals`
- Moved Editors/IDE NIX files to own subdir `config/editors`
- Added `nvf.nix` Alternate NeoVIM configurator.
  - It's commented out in `home.nix`
- Added:
  - `dino` and `gajim` Jappber/XMPP clients
  - `wl-copy`, `wl-paste`
  - Added `code-runner` plugin to `vscode.nix`

#### Hyprland-btw v0.2.6

- Added `keybinds` rofi search menu

#### Hyprland-btw v0.2.5

- Created desktop file for `kitty-bg`
- Made `kitty-bg` alternmate terminal `SUPERSHIFT+ENTER`

#### Hyprland-btw v0.2.4

- Code cleanup
  - Removed old unused code
  - Moved scripts in home.nix to own dir (config/scripts)
- Added TokyoNight theme (commented out currently)
- Change vscode.nix theme to Nero Hyrland

#### Hyprland-btw v0.2.3

- Code cleanup
  - Moved scripts to own directory `config/scripts`
  - Removed old unused code
- Added TokyoNight theme as option. (commented out )

#### Hyprland-btw v0.2.2

- Added:
  - Kitty
  - Kitty-bg (random background in terminal)
  - Wezterm
  - Alacritty
- Set vscode to Nero Hyprland theme
- Set GTK to Dracula theme
- Set icons to candy-icons
- Re-enabled `symbola` font
- Added legacy rofi menu
- Added rofi menu to edit system files

#### Hyprland-btw v0.2.1

- Added animations directory
- Broke up Hyprland into sourced files
  - `appearnace.conf`
  - `binds.conf`
  - `env.conf`
  - `input.conf`
  - `startup.conf`
  - `WindowRules.conf`

#### Hyprland-btw v0.2.0

- Fixed noctalia not starting on first login after install
- Switched Noctalia to Home Manger config
- Added noctalia systemd service
- DISABLED symbola font in fonts.nix
  - It doesn't download (again)
  - This occurs periodicaly until a new source can be found

#### Hyprland-btw v0.1.3

- Fixed preserving existing users
- Fixed new users get home creation

#### Hyprland-btw v0.1.2

- Fixed username hardcoded to dwilliams
- Fixed hostname not getting updated
- Added check for valid username and prompt to add to enter again
- Addded root password check, prompt to optionally set if not

#### Hyprland-btw v0.1.1

- Merged dev branch to main
- Renamed the last of the tony-nixos to Hyprland-btw
- Fixed install.sh username conflicts causing install failure
- Added sleep to noctalia-shell on first login it doesn't start
- Fixed username not getting set correctly
- Added wallpapers
- Set astralbed.png as hyprpaper default
- Set dock to exclusive by default (no window overlap)
- Enabled wallpaper theming in noctalia-shell as default

## Renamed to `Hyprland-btw`

#### Hyprland-btw-v0.1.0

- Merged dev branch to main
- Renamed project hyprland-btw
- Updated all references
- Add modular GPU drivers (AMD, Intel, NVIDIA) under modules/drivers.
- Add vm.guest-services module to manage QEMU/Spice guest services behind vm.guest-services.enable.
- Wire the drivers stack into flake.nix and move QEMU/Spice services out of configuration.nix.
- Added install.sh as a simple single-host installer
  - Sets:
  - GPU type
  - Hostname
  - Username
  - Timezone
  - Hyprland keymap
  - Console keymap
  - checks for /etc/nixos/hardware-configuration.nix
  - Prompts to copy or regenerate
  - Installs ly login manager
  - Does sudo nixos-rebuild boot --flake
  - Safer than switch

> Note: I.e if you have a LDM it will restart that switching to ly
> Resulting in black screen and you have to re-run the rebuild

- Refreshed `README.md`` with scripted/manual install instructions and drivers documentation.
- Documented a VM-centric GPU profile and how to toggle drivers and VM guest services in configuration.nix.

### Tony-NixOS-v0.0.5

#### Release v0.0.5

- Added modules
- packages.nix
- fonts.nix
- yazi.nix
- Updated README.md
- Summaries for major packages
- Annotated Directory Layout

### Tony-NixOS-v0.0.4

#### Release v0.0.4

- Added flatpak service and added flathub by default
- Added seatd service
- Added gnome keyring
- Added configured vscode

### Tony-NixOS-v0.0.3

#### Release v0.0.3

- Made zsh default shell
  - Added Plugins
  - syntax highlighting
  - autosuggestion
  - git
  - direnv
  - history
  - sudo
  - colored-man-pages
  - command-not-found
  - Added @JustAGuylinux ZSH config
  - Fixed nixos maint aliases for zsh
- Added zoxide shell integration
  - zsh
  - bash
  - fish
- Added EZA shell integration
  - zsh
  - bash
  - fish
- Updated configuration.nix and hardware-configuration.nix NIX formattiung

### Tony-NixOS-v0.0.1

#### Initial Release v0.0.1

- Simple Hyprland Config
- Flake.nix, configuration.nix, hardware.nix
- Noctalia Shell by default
- Simple Waybar alternative
- Ly login manager
- Low memory overhead around 600MB
