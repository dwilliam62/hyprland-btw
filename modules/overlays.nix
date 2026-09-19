{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Pin Neovim to nixpkgs-stable (0.11.x) to avoid regressions
      neovim = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.neovim;
      neovim-unwrapped =
        inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.neovim-unwrapped;

      synfetch = inputs.synfetch.packages.${final.stdenv.hostPlatform.system}.default;
    })
  ];
}
