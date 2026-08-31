{pkgs, ...}: {
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "xps15";

  drivers = {
    amdgpu.enable = false;
    intel.enable = true;
    nvidia = {
      enable = true;
      prime = {
        enable = true;
        offload.enable = false;
        sync.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  vm.guest-services.enable = false;

  # Laptop specific hardware / GPU configs
  hardware.nvidia.open = false;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      ocl-icd
    ];
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      openssl
      zlib
      bzip2
      expat
      ocl-icd
    ];
  };
}
