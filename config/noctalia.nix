{
  pkgs,
  inputs,
  lib,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPkg = inputs.noctalia.packages.${system}.default;
in {
  home.packages = [
    noctaliaPkg
    pkgs.gpu-screen-recorder
  ];

  # Ensure declarative v5 config directory exists
  home.activation.ensureNoctaliaConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    DEST="$HOME/.config/noctalia"

    if [ ! -d "$DEST" ]; then
      $DRY_RUN_CMD mkdir -p "$DEST"
    fi
  '';
}
