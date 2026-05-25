{
  pkgs,
  lib,
  ...
}: let
  noctaliaPkg = pkgs.noctalia-shell;
  configDir = "${noctaliaPkg}/share/noctalia-shell";
in {
  # Install the Noctalia package
  home.packages = [
    noctaliaPkg
    pkgs.noctalia-qs
    pkgs.gpu-screen-recorder
  ];

  # Seed the configuration
  home.activation.seedNoctaliaShellCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    DEST="$HOME/.config/quickshell/noctalia-shell"
    SRC="${configDir}"

    if [ ! -d "$DEST" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/quickshell"
      $DRY_RUN_CMD cp -R "$SRC" "$DEST"
      $DRY_RUN_CMD chmod -R u+rwX "$DEST"
    fi
  '';
}
