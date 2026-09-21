{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      synfetch = inputs.synfetch.packages.${final.stdenv.hostPlatform.system}.default;

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
