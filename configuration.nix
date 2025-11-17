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
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.11"; # Did you read the comment?

}

