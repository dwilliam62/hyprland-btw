{ config, pkgs, inputs, ... }:

{
  imports = [
    ./config/nixvim.nix # Nixvim HM module
    ./config/noctalia.nix # Noctalia QuickShell wiring (fronm ddubsos)
    ./config/vscode.nix
    ./config/zsh.nix
    ./config/yazi/default.nix
  ];
  home = {
    username = "your-username";
    homeDirectory = "/home/your-username";
    stateVersion = "25.11";
    sessionVariables = {
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
          export GTK_THEME=Adwaita:dark
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
        # "--time-style=long-iso" # ISO 8601 extended format for time
        "--classify" # append indicator (/, *, =, @, |)
        "--hyperlink" # make paths clickable in some terminals
      ];
    };
  };

  #  Help consistently theme appps 
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
  home.file.".zshrc-personal".source = ./config/.zshrc-personal;
  home.file.".config/tmux/tmux.conf".source = ./config/tmux.conf;
  home.file.".config/starship.toml".source = ./config/starship.toml;
}
