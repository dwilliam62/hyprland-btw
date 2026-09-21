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

    # Give compositor a split second to set up sockets and systemd environment
    ${pkgs.coreutils}/bin/sleep 0.5

    # Detect active compositor / window manager
    wm="hyprland"
    if [ -d "$runtime_dir/hypr" ] || [ -d "/tmp/hypr" ] || ${pkgs.procps}/bin/pgrep -x Hyprland >/dev/null 2>&1; then
      wm="hyprland"
    elif ${pkgs.procps}/bin/pgrep -x mango >/dev/null 2>&1; then
      wm="mango"
    fi

    # Import user session environment from systemd manager if available
    if command -v systemctl >/dev/null 2>&1; then
      eval "$(systemctl --user show-environment 2>/dev/null | grep -E '^(PATH|USER|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|XDG_SESSION_ID)=' | sed 's/^/export /')"
    fi

    if [ "''${XDG_CURRENT_DESKTOP:-}" = "mango" ] || [ "''${XDG_SESSION_DESKTOP:-}" = "mango" ]; then
      wm="mango"
    elif [ "''${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ] || [ "''${XDG_SESSION_DESKTOP:-}" = "Hyprland" ]; then
      wm="hyprland"
    fi

    if [ "$wm" = "mango" ]; then
      export XDG_CURRENT_DESKTOP="mango"
      export XDG_SESSION_DESKTOP="mango"
      export NOCTALIA_CONFIG_HOME="$HOME/.config/mango"
      export NOCTALIA_STATE_HOME="$HOME/.local/state/mango"
    else
      export XDG_CURRENT_DESKTOP="Hyprland"
      export XDG_SESSION_DESKTOP="Hyprland"
      export NOCTALIA_CONFIG_HOME="$HOME/.config/hypr"
      export NOCTALIA_STATE_HOME="$HOME/.local/state/hypr"
    fi

    mkdir -p "''${NOCTALIA_CONFIG_HOME}/noctalia"
    mkdir -p "''${NOCTALIA_STATE_HOME}/noctalia"

    export WAYLAND_DISPLAY="$display"
    export PATH="$HOME/.local/bin:${lib.makeBinPath [pkgs.systemd pkgs.procps pkgs.coreutils pkgs.hyprland pkgs.mango]}:$PATH"
    exec ${pkgs.noctalia}/bin/noctalia
  '';
in {
  home.packages = [
    pkgs.noctalia
    pkgs.gpu-screen-recorder
  ];

  # Ensure declarative v5 per-WM config directories exist
  home.activation.ensureNoctaliaConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    mkdir -p "$HOME/.config/hypr/noctalia"
    mkdir -p "$HOME/.config/mango/noctalia"
    mkdir -p "$HOME/.local/state/hypr/noctalia"
    mkdir -p "$HOME/.local/state/mango/noctalia"
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
