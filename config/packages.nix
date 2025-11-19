{ pkgs, ... }:

{
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
    inxi
    kitty
    bibata-cursors
    lunarvim # Alternate neovim (lvim)
    luarocks # LUA for nevoim
    mesa-demos # needed for inxi
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
    zig
  ];

} 
