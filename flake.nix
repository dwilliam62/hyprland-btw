{
  description = "Hyprland on Nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra.url = "github:kamadorueda/alejandra";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    noctalia,
    alejandra,
    ...
  }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.hyprland-btw = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
        }
        ./configuration.nix
        ./config/nh.nix
        ./modules/drivers/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # Default: supports the installer-configured user or default 'dwilliams'
            # The installer patches this username when creating a new system
            # For existing clones, add additional users below if needed
            users."dwilliams" = import ./home.nix;
            # To add another user, uncomment and adjust:
            # users."username" = import ./home.nix;
            backupFileExtension = "backup";
            extraSpecialArgs = {inherit inputs;};
          };
        }
      ];
    };

    # Code formatter
    formatter.x86_64-linux = alejandra.defaultPackage.x86_64-linux;
  };
}
