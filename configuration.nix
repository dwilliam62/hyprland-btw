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

  # Add services 
  services = {
    # Enabled VM guest services
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
    spice-webdavd.enable = true;
    spice-autorandr.enable = true;
    getty.autologinUser = null; # disable auto-login
    openssh.enable = true;
    tumbler.enable = true;
    envfs.enable = true;
    seatd.enable = true;
    gnome.gnome-keyring.enable = true;
    libinput.enable = true;
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
    firefox.enable = true;
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dwilliams = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh; # default login shell
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
    lunarvim
    luarocks
    ncdu
    nh
    onefetch
    pciutils
    ranger
    ripgrep
    starship
    tmux
    ugrep
    vim
    wget
    yazi
    zig
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

