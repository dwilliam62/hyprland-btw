{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      synfetch = inputs.synfetch.packages.${final.stdenv.hostPlatform.system}.default;
    })
  ];
}
