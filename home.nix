{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
  rofiLegacyMenu = import ./config/scripts/rofi-legacy.menu.nix {inherit pkgs;};
  DropTerminal = import ./config/scripts/DropTerminal.nix {inherit pkgs;};
  configMenu = import ./config/scripts/config-menu.nix {inherit pkgs;};
  keybindsMenu = import ./config/scripts/keybinds.nix {inherit pkgs;};
  hyprlandChangeLayout = import ./config/scripts/hyprland-change-layout.nix {inherit pkgs;};
  hyprlandCycleWindow = import ./config/scripts/hyprland-cycle-window.nix {inherit pkgs;};
in {
  imports = [
    ./config/terminals/alacritty.nix
    ./config/editors/bugsvim.nix # bugsvim NeoVIM config
    ./config/cli/cava.nix # Audio visualize Dracula theme (others in file)
    ./config/yazi/default.nix # TUI File Manager
    ./config/terminals/ghostty.nix # Ghostty and ghostty-bg
    ./config/cli/git.nix #config git settings AND username/EMail
    ./config/cli/htop.nix # htop monitor
    ./config/cli/btop.nix # btop monitor
    ./config/terminals/kitty.nix #kitty term and kitty-bg (background in kitty)
    ./config/noctalia.nix # Noctalia QuickShell wiring (fronm ddubsos)
    ./config/overview.nix # Quickshell-overview workspace preview
    ./config/terminals/wezterm.nix # Wezterm terminal
    ./config/editors/vscode.nix # w/plugins and nero hyprland theme
    ./config/zsh.nix # Cfg zsh from @justaguylinux
    # Build and install gh0stzk/st (st-graphics) on rebuilds
    ./config/terminals/st-gh0stzk.nix
    ######################################################################
    # These are two alternate nvim configs
    # Nixvim is now nearly idendtical to bugsvim
    # In future I will most likely switch to nixvim
    #./config/editors/nixvim.nix # Nixvim NeoVIM config
    #./config/editors/nvf.nix # nvf alternate NVIM config
    ######################################################################
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
      DropTerminal
      configMenu
      keybindsMenu
      hyprlandChangeLayout
      hyprlandCycleWindow
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
          exec start-hyprland
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
        "-all"
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
      name = "al-beautyline";
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
    gtk4 = {
      theme = config.gtk.theme;
      extraConfig = {
        "gtk-application-prefer-dark-theme" = 1;
      };
    };
  };

  # Seed wallpapers
  home.activation.seedWallpapers = lib.hm.dag.entryAfter ["writeBoundary"] ''
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

  # Link local icon theme
  home.file.".local/share/icons/al-beautyline".source = ./config/local.icons/al-beautyline;

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
  home.file.".config/swaync/images".source = ./config/swaync/images;
}
