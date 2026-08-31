{
  description = "Hyprland on Nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synfetch = {
      url = "github:SXSLVT/synfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra.url = "github:kamadorueda/alejandra";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    nixvim,
    alejandra,
    ...
  }: let
    system = "x86_64-linux";

    # Generic host generator
    mkHost = {
      hostName,
      hostPath ? ./hosts/${hostName},
      userName ? "dwilliams",
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs hostName userName;};
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
          }
          ./modules/overlays.nix
          ./configuration.nix
          ./config/nh.nix
          ./modules/drivers/default.nix
          hostPath
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${userName} = import ./home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {inherit inputs hostName userName;};
            };
          }
        ];
      };

    # Auto-discover all host subdirectories in ./hosts
    hostsDir = ./hosts;
    hostsAttr = builtins.readDir hostsDir;
    discoveredHosts = builtins.attrNames (
      nixpkgs.lib.filterAttrs (_name: type: type == "directory") hostsAttr
    );

    autoHosts = nixpkgs.lib.genAttrs discoveredHosts (hn: mkHost {hostName = hn;});
  in {
    nixosConfigurations =
      autoHosts
      // {
        # Host aliases for compatibility with current hostname on the VM
        "hyprland-btw" =
          if builtins.hasAttr "vm" autoHosts
          then autoHosts."vm"
          else if builtins.hasAttr "default" autoHosts
          then autoHosts."default"
          else
            mkHost {
              hostName = "hyprland-btw";
              hostPath = ./hosts/default;
            };
      };

    # Code formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
