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
    #quickshell
    noctalia-shell
    noctalia-qs
    slurp
    nwg-look
    rofi
    #wofi
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
    alacritty
    alejandra
    appimage-run
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
    fd # better find used by emacs, etc
    foot
    #gajim # Japper XMPP client
    gearlever # manage app iamges
    gcc
    ghostty
    git
    gping
    google-chrome
    gnumake
    htop
    hyfetch
    inxi # diagnostic utils
    isd # SystemD tool
    kitty
    kmon # Kernel Monitor
    lstr # Tree like tool with icons, etc
    luarocks # LUA for nevoim
    mdcat
    mesa-demos # needed for inxi
    mpv # video player
    nemo-with-extensions # nemo file mgr
    neovide # gui for neovim
    ncdu # show diskusage
    nh # Nix Helper
    nixd # nix lsp
    #nvtopPackages.full # nvtop all GPUs
    onefetch # git repo fetch
    #onlyoffice-desktopeditors
    pciutils
    ripgrep
    #rustup
    starship # custom prompt
    synfetch
    tmux #Terminal mux with hybridd ddubs-tonybtw config
    ttop # resource monitor
    ugrep
    vlc # Video Player
    #warp-terminal # AI and Terminal
    wezterm # Terminal
    wget
    zenith # Btop/htop/bottom style monitor
    zig # Compiler
  ];
}
