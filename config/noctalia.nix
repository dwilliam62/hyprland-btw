{
  pkgs,
  lib,
  ...
}: let
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

    # Import active compositor and user environment from systemd manager
    if command -v systemctl >/dev/null 2>&1; then
      eval "$(systemctl --user show-environment 2>/dev/null | grep -E '^(PATH|USER|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|XDG_SESSION_ID)=' | sed 's/^/export /')"
    fi

    export WAYLAND_DISPLAY="$display"
    export PATH="${lib.makeBinPath [pkgs.systemd pkgs.procps pkgs.coreutils pkgs.hyprland pkgs.mango]}:$PATH"
    exec ${pkgs.noctalia}/bin/noctalia
  '';
in {
  home.packages = [
    pkgs.noctalia
    pkgs.gpu-screen-recorder
  ];

  # Ensure declarative v5 config directory exists and configure session-logout
  home.activation.ensureNoctaliaConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    DEST="$HOME/.config/noctalia"
    mkdir -p "$DEST"
    SETTINGS="$DEST/settings.json"
    if [ -f "$SETTINGS" ] && command -v ${pkgs.jq}/bin/jq >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq 'if .sessionMenu?.powerOptions then .sessionMenu.powerOptions |= map(if .action == "logout" and (.command == "" or .command == null) then .command = "session-logout" else . end) else . end' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
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
        "XDG_SESSION_TYPE=wayland"
        "QT_QPA_PLATFORM=wayland;xcb"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
