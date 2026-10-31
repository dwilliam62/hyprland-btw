

# hyprland-btw — Hyprland-and-Mango-on-NixOS (Multi-host)

Super simple NixOS + Hyprland configuration derived from the **tony,btw** example,
with a few additions:  MangoWC is from my own configuration.

- Modular drivers for AMD/Intel/NVIDIA GPUs and VM guest services
- Small install script for first-time setup on a single host
- Home Manager wiring for user-level config
- Added Noctalia-shell

### Inspiration

- Video: [`tony,btw` — Hyprland on NixOS](https://www.youtube.com/watch?v=7QLhCgDMqgw&t=138s)
- Config: [tony,btw GitHub](https://github.com/tonybanters)
- GUI: [Noctalia-shell](https://github.com/noctalia-dev/noctalia-shell)

> Default target is **a single host**, often running in a VM.
>
> - QEMU/KVM with VirtIO and 3D acceleration enabled
> - Can be installed from a live NixOS ISO [See Tony's Vidoe: Stop Using MacOS](https://www.youtube.com/watch?v=7QLhCgDMqgw&t=140s)
> - This repo now includes basic AMD/Intel/NVIDIA/Hybrid GPU + VM support out of the box.

### Important:

> Note: Currently the first-time you login `noctalia-shell` doesn't start
> Logout: `SUPER+SHIFT+Q` then back in. It will start normally after that
> I am working to resolve this issue

## Features:

### Hyprland

- `ly` login Manager
- Simple flake
- Simple Home Manager
- Noctalia shell
- Flatpak + AppImage support
- Simple waybar as alternative
- NeoVIM configured by `nixvim`
- Tony,BTW's TMUX configuration

**Noctalia Shell**

![Noctalia Shell](config/images/ScreenShot-Noctalia.png)

![Noctalia Shell htop](config/images/ScreenShot-htop-noctalia.png)

**Waybar**

![Waybar](config/images/ScreenShot-waybar.png)

![htop](config/images/ScreenShot-htop-waybar.png)

![Kitty Background](config/images/kitty-bg.png)

![Rofi Menu](config/images/rofi-menu.png)

![Config menu](config/images/config-menu.png)

## Installation:

### Quick install (script)

From a NixOS live system or an existing NixOS install:

```bash
nix-shell -p git
cd ~
git clone https://gitlab.com/your-remote/hyprland-btw.git
cd hyprland-btw
chmod +x ./install.sh
./install.sh
```

- The script:
  - Verifies you are on NixOS
  - Copies `/etc/nixos/hardware-configuration.nix` into this repo
  - Lets you set the timezone (or defaults to `America/New_York`)
  - Runs `sudo nixos-rebuild switch --flake .#hyprland-btw`

Non-interactive usage:

```bash
./install.sh --non-interactive
```

### Manual install

If you prefer to do things by hand:

```bash
nix-shell -p git
cd ~
git clone https://gitlab.com/your-remote/hyprland-btw.git
cd hyprland-btw
sudo cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
sudo nixos-rebuild switch --flake .#hyprland-btw
```

## Drivers

Drivers are now modular, inspired by `ddubsos/modules/drivers`:

- `drivers.amdgpu.enable = true;` — AMD GPU support (ROCm symlink + `services.xserver.videoDrivers = [ "amdgpu" ]`)
- `drivers.intel.enable = true;` — Intel GPU support (VAAPI / VDPAU packages)
- `drivers.nvidia.enable = true;` — NVIDIA GPU support (`hardware.nvidia` + stable driver package)
- `vm.guest-services.enable = true;` — QEMU/Spice guest services (moved out of `services` in `configuration.nix`)

This project assumes **a single host**; there is no `specialArgs.host` logic or
per-host branching like in [ddubsOS](https://gitlab.com/dwilliam62/ddubsos).
Toggle only the one driver you actually need.

## Nix configuration files:

Below you can expand each Nix file to view its full contents.

<details>
<summary><code>flake.nix</code> – Flake entrypoint</summary>

```nix

{
  description = "Hyprland on Nixos";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixvim, noctalia, ... }: let
    userCfg = import ./user.nix;
  in {
    nixosConfigurations.hyprland-btw = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./modules/drivers/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${userCfg.userName} = import ./home.nix;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs; userName = userCfg.userName; };
          };
        }
      ];
    };
  };
}

```

</details>

<details>
<summary><code>configuration.nix</code> – System configuration</summary>

```nix

{ pkgs, userName, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./config/fonts.nix
      ./config/packages.nix
    ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 40; # use ~50% of RAM for compressed swap (tweak as you like)
    priority = 100; # higher than any disk-based swap
  };

  networking = {
    hostName = "hyprland-btw";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  # GPU/VM profile for this single-host system
  # Current host: VM with virtio GPU (no dedicated AMD/Intel/NVIDIA module enabled).
  # The installer will set exactly ONE of these to true based on your GPU profile:
  drivers.amdgpu.enable = false;  # AMD GPUs
  drivers.intel.enable  = false;  # Intel iGPU
  drivers.nvidia.enable = false;  # NVIDIA GPUs

  # Enable VM guest services via the drivers module when running in a VM.
  # Disable this if you are installing on bare metal without QEMU/Spice.
  vm.guest-services.enable = true;

  # Add services
  services = {
    getty.autologinUser = null; # disable auto-login
    openssh.enable = true;
    tumbler.enable = true;
    envfs.enable = true;
    seatd.enable = true;
    gnome.gnome-keyring.enable = true;
    libinput.enable = true;
    # Default XKB layout for Hyprland/X11 (overridden by installer).
    xserver.xkb.layout = "us";
    flatpak.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    displayManager.ly = {
      enable = true;
      settings = {
        animation = "matrix";
      };
    };
  };

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = false;
    };
    firefox.enable = false;
    thunar.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true; # ensure system zsh is configured for login shells
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Default console keymap (overridden by installer).
  console.keyMap = "us";

  # Define the primary user account (name comes from ./user.nix).
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh; # default login shell
    packages = with pkgs; [
      tree
    ];
  };

  # Example: add additional users (uncomment and adjust as needed)
  # users.users."seconduser" = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  #   shell = pkgs.zsh;
  #   packages = with pkgs; [
  #     git
  #     htop
  #   ];
  # };

  systemd.services.flatpak-add-flathub = {
    description = "Add Flathub Flatpak remote";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "flatpak-system-helper.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };


  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.11"; # Did you read the comment?

}

```

</details>

<details>
<summary><code>home.nix</code> – Home Manager configuration</summary>

```nix

{ config, pkgs, inputs, lib, userName, ... }:

let
  rofiLegacyMenu = import ./config/scripts/rofi-legacy.menu.nix { inherit pkgs; };
  configMenu = import ./config/scripts/config-menu.nix { inherit pkgs; };
  keybindsMenu = import ./config/scripts/keybinds.nix { inherit pkgs; };
in
{
  imports = [
    ./config/editors/nixvim.nix # Nixvim NeoVIM config
    #./config/editors/nvf.nix # nvf alternate NVIM config
    ./config/noctalia.nix # Noctalia QuickShell wiring (fronm ddubsos)
    ./config/editors/vscode.nix # w/plugins and nero hyprland theme
    ./config/terminals/kitty.nix #kitty term and kitty-bg (background in kitty)
    ./config/terminals/ghostty.nix
    ./config/terminals/wezterm.nix
    ./config/terminals/alacritty.nix
    ./config/zsh.nix # Cfg zsh from @justaguylinux
    ./config/yazi/default.nix
  ];
  home = {
    username = lib.mkDefault userName;
    homeDirectory = lib.mkDefault "/home/${userName}";
    stateVersion = "25.11";
    sessionVariables = {
      # GTK_THEME = "Adwaita:dark";
      GTK_THEME = "Dracula";
    };
    packages = [
      rofiLegacyMenu
      configMenu
      keybindsMenu
      pkgs.dracula-theme
    ];
  };

  programs = {
    neovim = {
      enable = false; # Now managed by nixvim.nix
      defaultEditor = true;
    };
    bash = {
      enable = true;
      shellAliases = {
        ll = "eza -la --group-dirs-first --icons";
        v = "nvim";
        rebuild = "sudo nixos-rebuild switch --flake ~/hyprland-btw/";
        update = "nix flake update --flake ~/hyprland-btw && sudo nixos-rebuild switch --flake ~/hyprland-btw/";
      };
      # The block below is for commands that should run every time a terminal starts.
      initExtra = ''
        # Source the personal file for all interactive shell sessions
        if [ -f ~/.bashrc-personal ]; then
         source ~/.bashrc-personal
        fi
      '';
      profileExtra = ''
        if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
          #exec uwsm start -S hyprland-uwsm.desktop
          # export GTK_THEME=Adwaita:dark
          export GTK_THEME=Dracula
          exec Hyprland
        fi
      '';
    };

    #  Enables seemless zoxide integration
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

    eza = {
      enable = true;
      icons = "auto";
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      git = true;
      extraOptions = [
        "--group-directories-first"
        "--no-quotes"
        "--header" # Show header row
        "--git-ignore"
        "--classify" # append indicator (/, *, =, @, |)
        "--hyperlink" # make paths clickable in some terminals
      ];
    };
  };

  # Dracula theme configuration
  gtk = {
    enable = true;
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
      #package = pkgs.tokyonight-gtk-theme;
      #Dark (Blue Accent): "Tokyonight-Dark-B"
      #Dark (Moon Accent): "Tokyonight-Dark-Moon"
      #Storm (Gray/Muted Accent): "Tokyonight-Storm-B"
    };
    # Optional: uncomment for Dracula icons
    iconTheme = {
      name = "candy-icons";
      package = pkgs.candy-icons;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
  };

  # Seed wallpapers once into ~/Pictures/Wallpapers (Noctalia default), without overwriting user changes
  home.activation.seedWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    SRC=${./config/wallpapers}
    DEST="$HOME/Pictures/Wallpapers"
    mkdir -p "$DEST"
    # Copy each file only if it doesn't already exist
    find "$SRC" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' f; do
      bn="$(basename "$f")"
      if [ ! -e "$DEST/$bn" ]; then
        cp "$f" "$DEST/$bn"
      fi
    done
  '';

  # Config apps
  home.file.".config/hypr".source = ./config/hypr;
  home.file.".config/waybar".source = ./config/waybar;
  home.file.".config/fastfetch".source = ./config/fastfetch;
  home.file.".config/foot".source = ./config/terminals/foot;
  home.file.".bashrc-personal".source = ./config/.bashrc-personal;
  home.file.".zshrc-personal".source = ./config/.zshrc-personal;
  home.file.".config/tmux/tmux.conf".source = ./config/terminals/tmux.conf;
  home.file.".config/starship.toml".source = ./config/starship.toml;
  home.file.".config/rofi/legacy.config.rasi".source = ./config/rofi/legacy.config.rasi;
  home.file.".config/rofi/legacy-rofi.jpg".source = ./config/rofi/legacy-rofi.jpg;
  home.file.".config/rofi/config-menu.rasi".source = ./config/rofi/config-menu.rasi;
}
```

</details>

<details>
<summary><code>config/packages.nix</code> – Install Apps</summary>

```nix

{ pkgs, ... }:

{

environment.systemPackages = with pkgs; [

    ## Hyprland specific
    hyprpaper
    hyprshot
    hypridle
    hyprlock
    hyprpicker
    libnotify # send alerts
    xdg-desktop-portal-hyprland

    # Hyprland Related
    app2unit # launcher
    clipman
    cliphist
    grim
    quickshell
    slurp
    nwg-look
    rofi
    wofi
    waybar
    matugen

    # Add your packages here
    atop
    bat
    btop
    bottom
    cargo
    clang
    curl
    direnv # needed for zsh plugin and vscode
    fastfetch
    foot
    git
    gcc
    git
    gping
    google-chrome
    htop
    hyfetch
    kitty
    lunarvim # Alternate neovim (lvim)
    luarocks # LUA for nevoim
    ncdu
    nh # Nix Helper
    nixd # nix lsp
    onefetch
    pciutils
    ranger
    ripgrep
    rustup
    starship
    tmux #Terminal mux with hybridd ddubs-tonybtw config
    ugrep
    wget
    yazi
    zig

];

}

```

</details>

<details>
<summary><code>config/fonts.nix</code> – Install Fonts</summary>

```nix
{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      fira-code
      fira-code-symbols
      font-awesome
      hackgen-nf-font
      ibm-plex
      inter
      jetbrains-mono
      material-icons
      maple-mono.NF
      minecraftia
      nerd-fonts.im-writing
      nerd-fonts.blex-mono
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
      powerline-fonts
      roboto
      roboto-mono
      symbola
      terminus_font
    ];
  };
}
```

</details>

## Hyprland keybinds

Default keybinds from <code>config/hypr/hyprland.conf</code> (with <code>$mainMod = SUPER</code>):

| Keys / Modifiers               | Action                                     | Description                                              |
| ------------------------------ | ------------------------------------------ | -------------------------------------------------------- |
| SUPER + Return                 | exec <code>$terminal</code> (foot)         | Open terminal (foot)                                     |
| SUPER + SHIFT + Return         | exec kitty                                 | Open Kitty terminal                                      |
| SUPER + Q                      | killactive                                 | Close focused window                                     |
| SUPER + SHIFT + Q              | exit                                       | Exit Hyprland session                                    |
| SUPER + T                      | exec <code>$fileManager</code> (thunar)    | Launch Thunar file manager                               |
| SUPER + Space                  | togglefloating                             | Toggle floating for focused window                       |
| SUPER + F                      | fullscreen,1                               | Toggle global fullscreen mode                            |
| SUPER + SHIFT + F              | fullscreen                                 | Toggle regular fullscreen                                |
| SUPER + R                      | exec <code>$menu</code> (wofi --show drun) | Application launcher                                     |
| SUPER + S                      | exec <code>$snip</code> (snip)             | Snipping / screenshot tool                               |
|| ALT + SHIFT + S                | exec hyprshot…                             | Region screenshot to <code>~/Pictures/Screenshots</code> |
|| SUPER + Tab                    | exec qs … overview toggle                  | Toggle Quickshell workspace overview with live previews  |
|| SUPER + D                      | exec qs … launcher                         | Toggle Noctalia launcher                                 |
| SUPER + M                      | exec qs … notifications                    | Toggle Noctalia notifications                            |
| SUPER + V                      | exec qs … clipboard                        | Open Noctalia clipboard launcher                         |
| SUPER + SHIFT + ,              | exec qs … settings                         | Toggle Noctalia settings                                 |
| SUPER + ALT + L                | exec qs … lockAndSuspend                   | Lock and suspend                                         |
| SUPER + SHIFT + Y              | exec qs … wallpaper                        | Toggle wallpaper module                                  |
| SUPER + X                      | exec qs … sessionMenu                      | Toggle session menu                                      |
| SUPER + C                      | exec qs … controlCenter                    | Toggle control center                                    |
| SUPER + CTRL + R               | exec qs … screenRecorder                   | Toggle screen recorder                                   |
| SUPER + L                      | movefocus l                                | Move focus left                                          |
| SUPER + H                      | movefocus r                                | Move focus right                                         |
| SUPER + K                      | movefocus u                                | Move focus up                                            |
| SUPER + J                      | movefocus d                                | Move focus down                                          |
| SUPER + 1–0                    | workspace 1–10                             | Switch to workspace 1–10                                 |
| SUPER + SHIFT + 1–0            | movetoworkspace 1–10                       | Move focused window to workspace 1–10                    |
| SUPER + mouse scroll down      | workspace e+1                              | Go to next workspace                                     |
| SUPER + mouse scroll up        | workspace e-1                              | Go to previous workspace                                 |
| SUPER + mouse:272 (drag left)  | movewindow                                 | Drag to move window                                      |
| SUPER + mouse:273 (drag right) | resizewindow                               | Drag to resize window                                    |

## Repository layout:

```text path=null start=null
[4.0K]  "."
├── [8.1K]  "AGENTS.md"
├── [ 15K]  "CHANGELOG.md"
├── [4.0K]  "config"
│   ├── [4.0K]  "cli"
│   │   ├── [ 653]  "btop.nix"
│   │   ├── [1.3K]  "cava.nix"
│   │   ├── [1.1K]  "fzf.nix"
│   │   ├── [2.2K]  "git.nix"
│   │   └── [ 848]  "htop.nix"
│   ├── [4.0K]  "editors"
│   │   ├── [3.3K]  "bugsvim.nix"
│   │   ├── [4.0K]  "bugsvim-nvim"
│   │   │   ├── [  22]  "init.lua"
│   │   │   └── [4.0K]  "lua"
│   │   │       ├── [4.0K]  "config"
│   │   │       │   ├── [2.7K]  "autocmds.lua"
│   │   │       │   ├── [ 319]  "globals.lua"
│   │   │       │   ├── [2.7K]  "keymaps.lua"
│   │   │       │   ├── [1.5K]  "lazy.lua"
│   │   │       │   └── [5.1K]  "options.lua"
│   │   │       ├── [4.0K]  "plugins"
│   │   │       │   ├── [1.7K]  "blink-cmp.lua"
│   │   │       │   ├── [ 536]  "colortheme.lua"
│   │   │       │   ├── [1.9K]  "conform.lua"
│   │   │       │   ├── [2.7K]  "gitsigns.lua"
│   │   │       │   ├── [ 637]  "lazydev.lua"
│   │   │       │   ├── [3.0K]  "lualine.lua"
│   │   │       │   ├── [ 575]  "markdown.lua"
│   │   │       │   ├── [ 890]  "markdown-preview.lua"
│   │   │       │   ├── [1.5K]  "mini-nvim.lua"
│   │   │       │   ├── [1.2K]  "noice.lua"
│   │   │       │   ├── [2.7K]  "nvim-dap.lua"
│   │   │       │   ├── [ 970]  "nvim-lint.lua"
│   │   │       │   ├── [1.2K]  "nvim-lspconfig.lua"
│   │   │       │   ├── [4.6K]  "nvim-treesitter.lua"
│   │   │       │   ├── [1.9K]  "org.lua"
│   │   │       │   ├── [ 854]  "persistance.lua"
│   │   │       │   ├── [ 14K]  "snacks.lua"
│   │   │       │   ├── [1.1K]  "todo-comments.lua"
│   │   │       │   └── [ 660]  "which-key.lua"
│   │   │       ├── [4.0K]  "servers"
│   │   │       │   ├── [ 577]  "bashls.lua"
│   │   │       │   ├── [ 615]  "clangd.lua"
│   │   │       │   ├── [ 677]  "cssls.lua"
│   │   │       │   ├── [ 667]  "html.lua"
│   │   │       │   ├── [ 661]  "hyprls.lua"
│   │   │       │   ├── [ 884]  "init.lua"
│   │   │       │   ├── [ 909]  "lua_ls.lua"
│   │   │       │   ├── [ 616]  "nil_ls.lua"
│   │   │       │   ├── [ 873]  "pyright.lua"
│   │   │       │   ├── [ 750]  "rust_analyzer.lua"
│   │   │       │   ├── [ 675]  "tailwindcss.lua"
│   │   │       │   └── [1.7K]  "ts_ls.lua"
│   │   │       └── [4.0K]  "utils"
│   │   │           ├── [1.2K]  "diagnostics.lua"
│   │   │           └── [1.9K]  "lsp.lua"
│   │   ├── [ 21K]  "nixvim.nix"
│   │   ├── [ 11K]  "nvf.nix"
│   │   └── [2.6K]  "vscode.nix"
│   ├── [4.0K]  "fastfetch"
│   │   ├── [2.2K]  "config.jsonc"
│   │   ├── [ 78K]  "nixos-ori.png"
│   │   └── [123K]  "nixos.png"
│   ├── [ 556]  "fonts.nix"
│   ├── [4.0K]  "hypr"
│   │   ├── [4.0K]  "animations"
│   │   │   ├── [ 882]  "00-default.conf"
│   │   │   ├── [ 867]  "01-default-v2.conf"
│   │   │   ├── [  89]  "03-Disable-Animation.conf"
│   │   │   ├── [1.6K]  "END-4.conf"
│   │   │   ├── [ 711]  "HYDE-default.conf"
│   │   │   ├── [1.1K]  "HYDE-minimal-1.conf"
│   │   │   ├── [ 400]  "HYDE-minimal-2.conf"
│   │   │   ├── [1.6K]  "HYDE-optimized.conf"
│   │   │   ├── [1.1K]  "HYDE-Vertical.conf"
│   │   │   ├── [ 446]  "hyprland-default.conf"
│   │   │   ├── [2.1K]  "Mahaveer-me-1.conf"
│   │   │   ├── [ 942]  "Mahaveer-me-2.conf"
│   │   │   ├── [ 462]  "ML4W-classic.conf"
│   │   │   ├── [ 657]  "ML4W-dynamic.conf"
│   │   │   ├── [ 871]  "ML4W-fast.conf"
│   │   │   ├── [ 653]  "ML4W-high.conf"
│   │   │   ├── [ 638]  "ML4W-moving.conf"
│   │   │   └── [ 463]  "ML4W]-standard.conf"
│   │   ├── [ 47K]  "hl.meta.lua"
│   │   ├── [ 472]  "hyprland.lua"
│   │   └── [4.0K]  "lua"
│   │       ├── [2.8K]  "animations.lua"
│   │       ├── [ 428]  "decorations.lua"
│   │       ├── [ 570]  "env.lua"
│   │       ├── [ 12K]  "keybinds.lua"
│   │       ├── [ 101]  "monitors.lua"
│   │       ├── [1.3K]  "settings.lua"
│   │       ├── [2.2K]  "startup.lua"
│   │       ├── [ 793]  "user_overrides.lua"
│   │       ├── [ 13K]  "window_rules.lua"
│   │       └── [ 175]  "workspaces.lua"
│   ├── [4.0K]  "images"
│   │   ├── [237K]  "config-menu.png"
│   │   ├── [1.2M]  "kitty-bg.png"
│   │   ├── [789K]  "rofi-menu.png"
│   │   ├── [782K]  "ScreenShot-htop-noctalia.png"
│   │   ├── [422K]  "ScreenShot-htop-waybar.png"
│   │   ├── [885K]  "ScreenShot-Noctalia.png"
│   │   └── [1.1M]  "ScreenShot-waybar.png"
│   ├── [ 627]  "lazygit.nix"
│   ├── [4.0K]  "mangowc"
│   │   ├── [3.0K]  "autostart.sh"
│   │   ├── [4.0K]  "bin"
│   │   │   ├── [1013]  "reload.sh"
│   │   │   ├── [ 811]  "screenshot.sh"
│   │   │   ├── [2.8K]  "set-icons"
│   │   │   └── [ 989]  "toggle-outer-gaps.sh"
│   │   ├── [5.5K]  "bind.conf"
│   │   ├── [3.6K]  "config.conf"
│   │   ├── [1.8K]  "env.conf"
│   │   ├── [ 535]  "monitor.conf"
│   │   ├── [ 399]  "noctalia.conf"
│   │   ├── [ 662]  "rule.conf"
│   │   └── [ 958]  "tag.conf"
│   ├── [1.7K]  "mangowc.nix"
│   ├── [ 269]  "nh.nix"
│   ├── [4.0K]  "noctalia"
│   │   └── [1.1K]  "noctalia-config.toml"
│   ├── [3.2K]  "noctalia.nix"
│   ├── [4.0K]  "overview"
│   │   ├── [4.0K]  "assets"
│   │   │   └── [1.4M]  "image.png"
│   │   ├── [4.0K]  "common"
│   │   │   ├── [6.1K]  "Appearance.qml"
│   │   │   ├── [ 488]  "Config.qml"
│   │   │   ├── [4.0K]  "functions"
│   │   │   │   ├── [1.9K]  "ColorUtils.qml"
│   │   │   │   └── [  40]  "qmldir"
│   │   │   ├── [ 326]  "qmldir"
│   │   │   └── [4.0K]  "widgets"
│   │   │       ├── [ 172]  "qmldir"
│   │   │       ├── [ 299]  "StyledRectangularShadow.qml"
│   │   │       ├── [ 412]  "StyledText.qml"
│   │   │       ├── [1.7K]  "StyledToolTipContent.qml"
│   │   │       └── [ 685]  "StyledToolTip.qml"
│   │   ├── [4.0K]  "modules"
│   │   │   └── [4.0K]  "overview"
│   │   │       ├── [5.3K]  "Overview.qml"
│   │   │       ├── [ 16K]  "OverviewWidget.qml"
│   │   │       ├── [4.3K]  "OverviewWindow.qml"
│   │   │       └── [ 102]  "qmldir"
│   │   ├── [6.2K]  "README.md"
│   │   ├── [4.0K]  "services"
│   │   │   ├── [ 198]  "GlobalStates.qml"
│   │   │   ├── [3.8K]  "HyprlandData.qml"
│   │   │   └── [  88]  "qmldir"
│   │   └── [ 290]  "shell.qml"
│   ├── [1.7K]  "overview.nix"
│   ├── [1.9K]  "packages.nix"
│   ├── [4.0K]  "rofi"
│   │   ├── [1.6K]  "config-menu.rasi"
│   │   ├── [2.5K]  "legacy.config.rasi"
│   │   └── [1.5M]  "legacy-rofi.jpg"
│   ├── [4.0K]  "scripts"
│   │   ├── [2.8K]  "config-menu.nix"
│   │   ├── [ 28K]  "DropTerminal.nix"
│   │   ├── [2.1K]  "hyprland-change-layout.nix"
│   │   ├── [1.0K]  "hyprland-cycle-window.nix"
│   │   ├── [1.9K]  "keybinds.nix"
│   │   ├── [2.2K]  "noctalia-msg.nix"
│   │   ├── [1.0K]  "rebuild.nix"
│   │   ├── [ 118]  "rofi-legacy.menu.nix"
│   │   ├── [1.8K]  "session-logout.nix"
│   │   ├── [2.4K]  "touchpadctl"
│   │   └── [1.2K]  "update.nix"
│   ├── [3.8K]  "starship.toml"
│   ├── [4.0K]  "swaync"
│   │   └── [4.0K]  "images"
│   │       └── [ 25K]  "catppuccin-macchiato.png"
│   ├── [4.0K]  "terminals"
│   │   ├── [ 971]  "alacritty.nix"
│   │   ├── [4.0K]  "foot"
│   │   │   └── [ 703]  "foot.ini"
│   │   ├── [6.3K]  "ghostty.nix"
│   │   ├── [4.0K]  "ghostty-themes"
│   │   │   ├── [ 475]  "catppuccin-mocha"
│   │   │   ├── [339K]  "tokyonight_moon.html"
│   │   │   ├── [339K]  "tokyonight_night.html"
│   │   │   └── [339K]  "tokyonight_storm.html"
│   │   ├── [4.0K]  "kitty"
│   │   │   └── [ 769]  "kitty.conf"
│   │   ├── [9.5K]  "kitty.nix"
│   │   ├── [2.8K]  "st-gh0stzk.nix"
│   │   ├── [4.0K]  "st-terminal"
│   │   ├── [3.2K]  "tmux.conf"
│   │   └── [4.5K]  "wezterm.nix"
│   ├── [ 731]  "virtualization.nix"
│   ├── [4.0K]  "wallpapers"
│   │   ├── [629K]  "3d-door.jpg"
│   │   ├── [1.3M]  "a_black_sand_beach_with_waves_and_clouds_above.jpg"
│   │   ├── [2.4M]  "a_group_of_wooden_posts_in_water.jpg"
│   │   ├── [2.9M]  "alena-aenami-cloud-sunset.jpg"
│   │   ├── [611K]  "alena-aenami-cold.jpg"
│   │   ├── [491K]  "alena-aenami-endless.jpg"
│   │   ├── [595K]  "alena-aenami-far-from-tomorrow.jpg"
│   │   ├── [494K]  "alena-aenami-moon-artwork.jpg"
│   │   ├── [7.8M]  "Anime-Lake.png"
│   │   ├── [5.8M]  "Anime-Lanscape.png"
│   │   ├── [1.5M]  "Anime-Purple-eyes.png"
│   │   ├── [2.6M]  "astralbed.png"
│   │   ├── [4.7M]  "Awesome-moon-pastal-landscape.jpeg"
│   │   ├── [752K]  "Beach-at-night-2k.jpg"
│   │   ├── [1.2M]  "beach-ocean-waves-sunset-clouds-scenery-2k-wallpaper.jpg"
│   │   ├── [258K]  "bluehour.jpg"
│   │   ├── [514K]  "CloudRipple.jpg"
│   │   ├── [515K]  "cosmic_blue.jpg"
│   │   ├── [4.9M]  "CuteCat.png"
│   │   ├── [1.3M]  "cyber.jpg"
│   │   ├── [295K]  "DT-Mountain-Lake.jpg"
│   │   ├── [635K]  "flowers-1.jpg"
│   │   ├── [2.5M]  "Hot-Blue-911.jpg"
│   │   ├── [313K]  "lake-dock-fog.jpg"
│   │   ├── [1.8M]  "LightHouse-during-storm.jpeg"
│   │   ├── [956K]  "Lofi-Cafe.jpg"
│   │   ├── [ 13M]  "lofi-Urban-Nightscape.png"
│   │   ├── [690K]  "midnight-reflections-moonlit-sea.jpg"
│   │   ├── [316K]  "Mily-Way-over-Horse-Head-Rock-New-South-Wales-fog.jpg"
│   │   ├── [698K]  "moonlight.jpg"
│   │   ├── [6.1M]  "moon-rise-over-lake2.png"
│   │   ├── [5.5M]  "moon-rise-over-lake.png"
│   │   ├── [316K]  "neon_cat6.jpeg"
│   │   ├── [272K]  "nordwall3.jpg"
│   │   ├── [8.9M]  "odin.jpg"
│   │   ├── [3.9M]  "Pastel-lake-boat-on-shore.png"
│   │   ├── [7.7M]  "Phonebooth-transporter.png"
│   │   ├── [959K]  "Plasma Wallpaper 1955.jpg"
│   │   ├── [2.9M]  "purple-circle-mountain.jpeg"
│   │   ├── [841K]  "purple_gasstation_abstract_dark_night.jpg"
│   │   ├── [326K]  "Purple-Nightmare.jpg"
│   │   ├── [ 12M]  "River-Moutains-Cherry-Blosums.png"
│   │   ├── [103K]  "Seaside-wharf-at-night.avif"
│   │   ├── [ 55K]  "sunrise-horse-head-rock-bermagui-new-south-wales-australia-end-world-172241321.webp"
│   │   └── [7.1M]  "Water-flowing-over-rock.png"
│   ├── [4.0K]  "waybar"
│   │   ├── [1.9K]  "config.jsonc"
│   │   └── [1.6K]  "style.css"
│   ├── [4.0K]  "yazi"
│   │   ├── [ 516]  "default.nix"
│   │   ├── [4.0K]  "flavors"
│   │   │   └── [4.0K]  "catppuccin-macchiato.yazi"
│   │   │       └── [ 68K]  "flavor.toml"
│   │   ├── [4.0K]  "init.lua"
│   │   ├── [ 25K]  "keymap.nix"
│   │   ├── [2.8K]  "keymap.toml"
│   │   ├── [ 758]  "package.toml"
│   │   ├── [4.0K]  "plugins"
│   │   │   ├── [4.0K]  "compress.yazi"
│   │   │   │   ├── [1.0K]  "LICENSE"
│   │   │   │   ├── [ 15K]  "main.lua"
│   │   │   │   └── [5.7K]  "README.md"
│   │   │   ├── [4.0K]  "full-border.yazi"
│   │   │   │   ├── [1.0K]  "LICENSE"
│   │   │   │   ├── [1.5K]  "main.lua"
│   │   │   │   └── [ 613]  "README.md"
│   │   │   ├── [4.0K]  "git.yazi"
│   │   │   │   ├── [1.0K]  "LICENSE"
│   │   │   │   ├── [6.5K]  "main.lua"
│   │   │   │   ├── [1.9K]  "README.md"
│   │   │   │   └── [ 593]  "types.lua"
│   │   │   ├── [4.0K]  "smart-filter.yazi"
│   │   │   │   ├── [1.0K]  "LICENSE"
│   │   │   │   ├── [ 919]  "main.lua"
│   │   │   │   └── [ 705]  "README.md"
│   │   │   ├── [4.0K]  "yatline-githead.yazi"
│   │   │   │   ├── [1.1K]  "LICENSE"
│   │   │   │   ├── [ 15K]  "main.lua"
│   │   │   │   └── [7.7K]  "README.md"
│   │   │   └── [4.0K]  "yatline.yazi"
│   │   │       ├── [1.1K]  "LICENSE"
│   │   │       ├── [ 47K]  "main.lua"
│   │   │       └── [ 691]  "README.md"
│   │   ├── [ 58K]  "theme.nix"
│   │   ├── [  39]  "theme.toml"
│   │   ├── [8.8K]  "yazi.nix"
│   │   └── [2.9K]  "yazi.toml"
│   └── [5.0K]  "zsh.nix"
├── [6.9K]  "configuration.nix"
├── [8.1K]  "flake.lock"
├── [3.2K]  "flake.nix"
├── [9.1K]  "home.nix"
├── [4.0K]  "hosts"
│   ├── [4.0K]  "default"
│   │   ├── [ 302]  "default.nix"
│   │   └── [ 670]  "hardware.nix"
│   ├── [4.0K]  "hyprland-btw-vm"
│   │   ├── [ 229]  "default.nix"
│   │   └── [ 899]  "hardware.nix"
│   ├── [4.0K]  "macbook"
│   │   ├── [ 297]  "default.nix"
│   │   └── [1.5K]  "hardware.nix"
│   └── [4.0K]  "xps15"
│       ├── [ 742]  "default.nix"
│       └── [1.6K]  "hardware.nix"
├── [6.7K]  "HOWTO-Manage-Hosts.md"
├── [ 23K]  "install.sh"
├── [ 34K]  "LICENSE"
├── [4.0K]  "modules"
│   ├── [4.0K]  "drivers"
│   │   ├── [ 374]  "amd-drivers.nix"
│   │   ├── [ 129]  "default.nix"
│   │   ├── [ 397]  "intel-drivers.nix"
│   │   ├── [2.0K]  "nvidia-drivers.nix"
│   │   └── [ 402]  "vm-guest-services.nix"
│   ├── [1.7K]  "overlays.nix"
│   └── [ 488]  "tumbler-overlay.nix"
├── [ 26K]  "README.md"
└── [ 342]  "user.nix"

54 directories, 260 files
```

`config/local.icons/` is a vendored icon theme (~14.8k files, mostly symlinks) and is omitted above for readability.
