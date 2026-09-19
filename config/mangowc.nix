{
  pkgs,
  lib,
  ...
}: let
  # Reference the local Mango config directory in this repo
  mangowcSrc = ./mangowc;
in {
  # Mango (mangowm) compositor configuration.
  # Deployed as real (writable) files because the upstream helper scripts
  # (reload.sh, toggle-outer-gaps.sh) edit config.conf in place.
  home.activation.mangowcSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu

    SRC=${mangowcSrc}
    DEST="$HOME/.config/mangowc"

    $DRY_RUN_CMD mkdir -p "$DEST"
    $DRY_RUN_CMD cp -rf "$SRC"/. "$DEST"/
    # Ensure config files are writable so the helper scripts and Home Manager can update them
    $DRY_RUN_CMD chmod -R u+w "$DEST"
    $DRY_RUN_CMD chmod +x "$DEST/autostart.sh" 2>/dev/null || true
    $DRY_RUN_CMD chmod +x "$DEST"/bin/* 2>/dev/null || true

    # Mango reads ~/.config/mango/config.conf; link it to the mangowc config dir
    $DRY_RUN_CMD ln -sfn mangowc "$HOME/.config/mango"
  '';

  # polkit-gnome is the Mango-compatible polkit authentication agent used by
  # ~/.config/mangowc/autostart.sh (xfce-polkit is not packaged in nixpkgs).
  home.packages = with pkgs; [
    polkit_gnome
    fzf # optional selector used by ~/.config/mangowc/bin/set-icons
  ];
}
