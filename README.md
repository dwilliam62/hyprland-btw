

# hyprland-btw — Hyprland-on-NixOS (single-host)

Super simple NixOS + Hyprland configuration derived from the **tony,btw** example,
with a few additions:

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

  outputs = inputs@{ self, nixpkgs, home-manager, nixvim, noctalia, ... }: {
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
            users."dwilliams" = import ./home.nix;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs; };
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

{ pkgs, ... }:

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

  # Define the primary user account. Don't forget to set a password with ‘passwd’.
  users.users."dwilliams" = {
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

{ config, pkgs, inputs, lib, ... }:

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
    username = lib.mkDefault "dwilliams";
    homeDirectory = lib.mkDefault "/home/dwilliams";
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
├── [4.7K]  "CHANGELOG.md"
├── [4.0K]  "config"
│   ├── [4.0K]  "editors"
│   │   ├── [ 13K]  "nixvim.nix"
│   │   ├── [ 11K]  "nvf.nix"
│   │   └── [2.6K]  "vscode.nix"
│   ├── [4.0K]  "fastfetch"
│   │   ├── [2.6K]  "config.jsonc"
│   │   └── [ 78K]  "nixos.png"
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
│   │   ├── [1.5K]  "appearance.conf"
│   │   ├── [3.9K]  "binds.conf"
│   │   ├── [ 539]  "env.conf"
│   │   ├── [ 781]  "hyprland.conf"
│   │   ├── [  95]  "hyprpaper.conf"
│   │   ├── [ 647]  "input.conf"
│   │   ├── [ 395]  "startup.conf"
│   │   └── [ 662]  "WindowRules.conf"
│   ├── [4.0K]  "images"
│   │   ├── [237K]  "config-menu.png"
│   │   ├── [1.2M]  "kitty-bg.png"
│   │   ├── [789K]  "rofi-menu.png"
│   │   ├── [782K]  "ScreenShot-htop-noctalia.png"
│   │   ├── [422K]  "ScreenShot-htop-waybar.png"
│   │   ├── [885K]  "ScreenShot-Noctalia.png"
│   │   └── [1.1M]  "ScreenShot-waybar.png"
│   ├── [ 871]  "noctalia.nix"
│   ├── [1.1K]  "packages.nix"
│   ├── [4.0K]  "rofi"
│   │   ├── [1.6K]  "config-menu.rasi"
│   │   ├── [2.5K]  "legacy.config.rasi"
│   │   ├── [1.5M]  "legacy-rofi.jpg"
│   │   └── [ 125]  "rofi-legacy.menu.nix"
│   ├── [4.0K]  "scripts"
│   │   ├── [2.6K]  "config-menu.nix"
│   │   ├── [1.5K]  "keybinds.nix"
│   │   └── [ 121]  "rofi-legacy.menu.nix"
│   ├── [3.8K]  "starship.toml"
│   ├── [4.0K]  "terminals"
│   │   ├── [ 566]  "alacritty.nix"
│   │   ├── [4.0K]  "foot"
│   │   │   └── [ 698]  "foot.ini"
│   │   ├── [6.3K]  "ghostty.nix"
│   │   ├── [4.0K]  "ghostty-themes"
│   │   │   └── [ 475]  "catppuccin-mocha"
│   │   ├── [4.0K]  "kitty"
│   │   │   └── [ 769]  "kitty.conf"
│   │   ├── [9.5K]  "kitty.nix"
│   │   ├── [3.2K]  "tmux.conf"
│   │   └── [4.5K]  "wezterm.nix"
│   ├── [4.0K]  "wallpapers"
│   │   ├── [629K]  "3d-door.jpg"
│   │   ├── [2.4M]  "a_group_of_wooden_posts_in_water.jpg"
│   │   ├── [2.9M]  "alena-aenami-cloud-sunset.jpg"
│   │   ├── [611K]  "alena-aenami-cold.jpg"
│   │   ├── [491K]  "alena-aenami-endless.jpg"
│   │   ├── [595K]  "alena-aenami-far-from-tomorrow.jpg"
│   │   ├── [7.8M]  "Anime-Lake.png"
│   │   ├── [5.8M]  "Anime-Lanscape.png"
│   │   ├── [1.5M]  "Anime-Purple-eyes.png"
│   │   ├── [2.6M]  "astralbed.png"
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
│   │   ├── [956K]  "Lofi-Cafe.jpg"
│   │   ├── [ 13M]  "lofi-Urban-Nightscape.png"
│   │   ├── [690K]  "midnight-reflections-moonlit-sea.jpg"
│   │   ├── [316K]  "Mily-Way-over-Horse-Head-Rock-New-South-Wales-fog.jpg"
│   │   ├── [698K]  "moonlight.jpg"
│   │   ├── [272K]  "nordwall3.jpg"
│   │   ├── [3.9M]  "Pastel-lake-boat-on-shore.png"
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
│   │   ├── [ 826]  "default.nix"
│   │   ├── [ 25K]  "keymap.nix"
│   │   ├── [ 58K]  "theme.nix"
│   │   ├── [ 36K]  "theme.toml"
│   │   └── [8.8K]  "yazi.nix"
│   └── [5.0K]  "zsh.nix"
├── [3.3K]  "configuration.nix"
├── [5.6K]  "flake.lock"
├── [ 990]  "flake.nix"
├── [1.5K]  "hardware-configuration.nix"
├── [4.7K]  "home.nix"
├── [ 22K]  "install.sh"
├── [ 34K]  "LICENSE"
├── [4.0K]  "modules"
│   └── [4.0K]  "drivers"
│       ├── [ 368]  "amd-drivers.nix"
│       ├── [ 131]  "default.nix"
│       ├── [ 389]  "intel-drivers.nix"
│       ├── [ 566]  "nvidia-drivers.nix"
│       └── [ 395]  "vm-guest-services.nix"
└── [ 26K]  "README.md"

18 directories, 112 files

```
