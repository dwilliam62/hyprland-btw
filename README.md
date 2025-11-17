## Project:

## Super Simple NixOS config for Hyprland with USWM

## This configuration was taken directly from `tony,btw` YouTube video

https://www.youtube.com/watch?v=7QLhCgDMqgw&t=138s

### Hyprland:

- Autoloin
- Simple flake
- Simple Home Manager
- noctalis shell
- Simple waybar as alternative
- NeoVIM configured by nixvim
- Tony,BTWs TMUX configuration

### `Flake.nix`

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
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.dwilliams = import ./home.nix;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs; };
          };
        }
      ];
    };
  };
}
```

## `home.nix`

```nix

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./config/nixvim.nix # your Nixvim HM module
    inputs.noctalia.homeModules.default # Noctalia’s Home Manager module
  ];
  home = {
    username = "dwilliams";
    homeDirectory = "/home/dwilliams";
    stateVersion = "25.11";
    sessionVariables = {
      # Making sure dark theme is set
      GTK_THEME = "Adwaita:dark";
    };
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
        rebuild = "sudo nixos-rebuild switch --flake ~/tony-nixos/";
        update = "nix flake update --flake ~/tony-nixos && sudo nixos-rebuild switch --flake ~/tony-nixos/";
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
          export GTK_THEME=Adwaita:dark
          exec Hyprland
        fi
      '';
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
  };

  # Config apps
  home.file.".config/hypr".source = ./config/hypr;
  home.file.".config/waybar".source = ./config/waybar;
  home.file.".config/fastfetch".source = ./config/fastfetch;
  home.file.".config/kitty".source = ./config/kitty;
  home.file.".config/foot".source = ./config/foot;
  home.file.".bashrc-personal".source = ./config/.bashrc-personal;
  home.file.".config/tmux/tmux.conf".source = ./config/tmux.conf;
  home.file.".config/starship.toml".source = ./config/starship.toml;
}

```

## `configuration.nix`

```nix

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "hyprland-btw";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  # Add services
  services = {
    getty.autologinUser = "dwilliams";
    openssh.enable = true;
    tumbler.enable = true;
    envfs.enable = true;
    libinput.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = false;
    };
    firefox.enable = true;
    thunar.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";



  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dwilliams = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

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
    quickshell
    clipman
    grim
    slurp
    nwg-look
    nwg-dock-hyprland
    nwg-menu
    nwg-panel
    nwg-launchers
    rofi
    wofi
    waybar
    waypaper
    matugen

    atop
    bat
    btop
    clang
    curl
    eza
    fastfetch
    foot
    git
    gcc
    git
    gping
    google-chrome
    hyfetch
    kitty
    lunarvim
    luarocks
    ncdu
    nh
    onefetch
    pciutils
    ripgrep
    starship
    tmux
    ugrep
    vim
    wget
    yazi
    zig
    zoxide
  ];
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


  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.sudo.wheelNeedsPassword = true;
  system.stateVersion = "25.11"; # Did you read the comment?

}




```
