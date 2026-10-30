{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Local build of synfetch (github:SXSLVT/synfetch).
      #
      # The upstream flake's package reads the deprecated `pkgs.stdenv.isLinux`
      # attribute, so pulling in `inputs.synfetch.packages.<system>.default`
      # makes every evaluation print:
      #   evaluation warning: stdenv.isLinux is deprecated, use stdenv.hostPlatform.isLinux instead
      #
      # Rebuilding the same writeShellApplication here, using the script from the
      # input, keeps the tool and drops the warning. Go back to the input package
      # once upstream is fixed.
      synfetch = prev.writeShellApplication {
        name = "synfetch";
        runtimeInputs = with prev;
          [
            coreutils
            ncurses
          ]
          ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
            pciutils
            procps
          ];
        checkPhase = "";
        text = builtins.readFile "${inputs.synfetch}/synfetch";
      };
      ghee = inputs.ghee.packages.${final.stdenv.hostPlatform.system}.ghee;
      butterview = inputs.butterview.packages.${final.stdenv.hostPlatform.system}.butterview;

      # Mango ships its Wayland session entry with a bare `Exec=mango`. greetd's
      # service PATH does not include the system profile, so noctalia-greeter
      # cannot resolve/inspect the executable and silently falls back to the
      # first resolvable session (Hyprland). Patch it to an absolute path.
      mango = prev.mango.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            substituteInPlace $out/share/wayland-sessions/mango.desktop \
              --replace 'Exec=mango' "Exec=$out/bin/mango"
          '';
      });
    })
  ];
}
