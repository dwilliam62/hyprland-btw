{lib, ...}: {
  imports = [
    ./hardware.nix
  ];

  networking.hostName = lib.mkDefault "hyprland-btw";

  drivers = {
    amdgpu.enable = lib.mkDefault false;
    intel.enable = lib.mkDefault false;
    nvidia.enable = lib.mkDefault false;
  };

  vm.guest-services.enable = lib.mkDefault false;
}
