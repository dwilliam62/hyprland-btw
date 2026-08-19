{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Pin Neovim to nixpkgs-stable (0.11.x) to avoid regressions
      neovim = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.neovim;
      neovim-unwrapped =
        inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.neovim-unwrapped;

      synfetch = inputs.synfetch.packages.${final.stdenv.hostPlatform.system}.default;

      # Temporary hotfix: dwarfs (gearlever dep) / bundled folly fails on GCC with
      # missing std::memcpy/std::memset (cstring) and treats warnings as errors.
      # Pin fmt_11 and force-include cstring.
      dwarfs =
        (prev.dwarfs.override {
          fmt = prev.fmt_11;
        }).overrideAttrs (old: {
          env =
            (old.env or {})
            // {
              CXXFLAGS = (old.env.CXXFLAGS or "") + " -include cstring -Wno-error";
            };
          cmakeFlags = (old.cmakeFlags or []) ++ ["-DENABLE_WERROR=OFF"];
        });
    })
  ];
}
