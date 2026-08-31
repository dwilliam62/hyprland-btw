{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    kernelParams = [
      "video=HDMI-A-1:e" # Enable HDMI-A-1
      "video=eDP-1:d" # Disable laptop display (eDP-1) when docked
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/cb4507b1-5b71-4a6f-bde8-acaa8db24725";
    fsType = "btrfs";
    options = ["subvol=@"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/cb4507b1-5b71-4a6f-bde8-acaa8db24725";
    fsType = "btrfs";
    options = ["subvol=@home"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/cb4507b1-5b71-4a6f-bde8-acaa8db24725";
    fsType = "btrfs";
    options = ["subvol=@nix"];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/disk/by-uuid/cb4507b1-5b71-4a6f-bde8-acaa8db24725";
    fsType = "btrfs";
    options = ["subvol=@snapshots"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4514-89CB";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  fileSystems."/mnt/nas" = {
    device = "192.168.40.11:/volume1/DiskStation54TB";
    fsType = "nfs";
    options = ["rw" "bg" "soft" "tcp" "_netdev"];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
