{pkgs, ...}: {
  #  Add packages below.

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
    #app2unit # launcher
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
    wl-clipboard
    # Qt6 dependencies for quickshell-overview
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtmultimedia

    # Add your packages here
    alejandra
    #assaultcube
    atop
    bat
    bibata-cursors
    btop
    bottom
    cargo
    clang
    curl
    coreutils
    #dino # Jabber XMPP Client
    direnv # needed for zsh plugin and vscode
    #discord
    #discord-canary
    fastfetch
    foot
    #gajim # Japper XMPP client
    gcc
    ghostty
    git
    gping
    google-chrome
    gnumake
    htop
    hyfetch
    inxi # diagnostic utils
    kitty
    luarocks # LUA for nevoim
    mdcat
    mesa-demos # needed for inxi
    mpv # video player
    nemo-with-extensions # nemo file mgr
    ncdu # show diskusage
    nh # Nix Helper
    nixd # nix lsp
    #nvtopPackages.full # nvtop all GPUs
    onefetch # git repo fetch
    onlyoffice-desktopeditors
    pciutils
    ripgrep
    #rustup
    starship # custom prompt
    tmux #Terminal mux with hybridd ddubs-tonybtw config
    ugrep
    vlc # Video Player
    warp-terminal # AI and Terminal
    wezterm # Terminal
    wget
    zig # Compiler
  ];
}
