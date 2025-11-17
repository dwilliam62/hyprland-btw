{ config, pkgs, ... }:

{
  home.username = "dwilliams";
  home.homeDirectory = "/home/dwilliams";
  home.stateVersion = "25.11";
  programs = {
     neovim = {
        enable = true;
        defaultEditor = true;
        };
     bash = {
       enable = true;
       shellAliases = {
         ll = "eza -la --group-dirs-first --icons";
         v = "nvim";
         rebuild = "sudo nixos-rebuild switch --flake ~/tony-nixos/";
         update  = "nix flake update --flake ~/tony-nixos && sudo nixos-rebuild switch --flake ~/tony-nixos/";
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
        exec Hyprland
      fi
    '';
  };
 };
    home.file.".config/hypr".source = ./config/hypr;
    home.file.".config/waybar".source = ./config/waybar;
    home.file.".config/fastfetch".source = ./config/fastfetch;
    home.file.".config/foot".source = ./config/foot;
    home.file.".bashrc-personal".source = ./config/.bashrc-personal;
    home.file.".config/starship.toml".source = ./config/starship.toml;
}
