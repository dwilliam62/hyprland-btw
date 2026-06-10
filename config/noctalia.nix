{
  pkgs,
  inputs,
  lib,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPkg = inputs.noctalia.packages.${system}.default;
  noctaliaLauncher = pkgs.writeShellScript "noctalia-launcher" ''
    set -eu

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    display="''${WAYLAND_DISPLAY:-}"
    attempts=0

    if [ -z "$display" ]; then
      while [ "$attempts" -lt 50 ]; do
        for sock in "$runtime_dir"/wayland-*; do
          if [ -S "$sock" ]; then
            display="''${sock##*/}"
            break
          fi
        done

        if [ -n "$display" ]; then
          break
        fi

        attempts=$((attempts + 1))
        ${pkgs.coreutils}/bin/sleep 0.2
      done
    fi

    if [ -z "$display" ]; then
      echo "noctalia-launcher: unable to find WAYLAND_DISPLAY under $runtime_dir" >&2
      exit 1
    fi

    export WAYLAND_DISPLAY="$display"
    exec ${noctaliaPkg}/bin/noctalia
  '';
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

  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia shell";
    };
    Service = {
      Type = "simple";
      ExecStart = "${noctaliaLauncher}";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
      Environment = [
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_TYPE=wayland"
        "QT_QPA_PLATFORM=wayland;xcb"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
