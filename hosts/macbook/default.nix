{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "macbook";

  drivers = {
    amdgpu.enable = false;
    intel.enable = true;
    nvidia.enable = false;
  };

  security.sudo.wheelNeedsPassword = lib.mkForce false;

  vm.guest-services.enable = false;
}
