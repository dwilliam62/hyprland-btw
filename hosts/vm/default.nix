{...}: {
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "vm";

  drivers = {
    amdgpu.enable = false;
    intel.enable = false;
    nvidia.enable = false;
  };

  vm.guest-services.enable = true;
}
