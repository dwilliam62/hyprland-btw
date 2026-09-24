{...}: {
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "hyprland-btw-vm";

  drivers = {
    amdgpu.enable = false;
    intel.enable = false;
    nvidia.enable = false;
  };

  vm.guest-services.enable = true;
}
