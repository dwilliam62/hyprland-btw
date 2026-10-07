{
  pkgs,
  lib,
  ...
}: let
  # Reference the local Mango config directory in this repo
  mangowcSrc = ./mangowc;
  # Shared Noctalia config template; @HOME@ is substituted at activation so
  # the wallpaper path follows the real home directory.
  noctaliaConfig = ./noctalia/noctalia-config.toml;
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

    # Deploy the Noctalia config with the real home directory substituted in.
    $DRY_RUN_CMD mkdir -p "$HOME/.config/mangowc/noctalia"
    $DRY_RUN_CMD cp ${noctaliaConfig} "$HOME/.config/mangowc/noctalia/config.toml"
    $DRY_RUN_CMD chmod u+w "$HOME/.config/mangowc/noctalia/config.toml"
    $DRY_RUN_CMD sed -i "s|@HOME@|$HOME|g" "$HOME/.config/mangowc/noctalia/config.toml"
  '';

  # polkit-gnome is the Mango-compatible polkit authentication agent used by
  # ~/.config/mangowc/autostart.sh (xfce-polkit is not packaged in nixpkgs).
  home.packages = with pkgs; [
    polkit_gnome
    fzf # optional selector used by ~/.config/mangowc/bin/set-icons
  ];
}
