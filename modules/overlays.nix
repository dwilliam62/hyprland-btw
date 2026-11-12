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

      # nixpkgs 26.11 made rustPlatform.cargoSetupHook export
      # AWS_LC_SYS_USE_SYSTEM, ZSTD_SYS_USE_PKG_CONFIG, OPENSSL_NO_VENDOR and
      # similar variables for every Rust build (release note rl-2611), so crates
      # are expected to link the Nixpkgs libraries. Packages that do not add
      # pkg-config plus the matching library to their build inputs then panic in
      # a build script. tectonic (installed by config/editors/bugsvim.nix) does,
      # because its aws-lc-sys dependency cannot find a system AWS-LC:
      #   AWS_LC_SYS_USE_SYSTEM=1 requires a system-installed AWS-LC, but none was found.
      # Opt it out so the crate builds its bundled AWS-LC again. Harmless on
      # older nixpkgs, which ignores the flag. Drop once nixpkgs fixes it.
      tectonic-unwrapped = prev.tectonic-unwrapped.overrideAttrs {dontCargoUseSystemLibs = true;};
      butterview = inputs.butterview.packages.${final.stdenv.hostPlatform.system}.butterview;

      # Waybar 0.16.0 from the locked nixpkgs-unstable has no binary-cache
      # entry, so every rebuild compiles it from source instead of substituting
      # it. Take the prebuilt 0.15.0 from the nixpkgs-stable input instead, so
      # config/packages.nix keeps its plain `waybar` entry and nothing is
      # compiled locally. Drop this override once unstable's waybar is cached
      # again.
      waybar = inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}.waybar;

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
