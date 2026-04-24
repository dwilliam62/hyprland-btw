{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e5fc1006-4d0b-41db-8c43-22b3cb8110c6";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9287-3738";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  fileSystems."/mnt/nas" = {
    device = "192.168.40.11:/volume1/DiskStation54TB";
    fsType = "nfs";
    options = ["rw" "bg" "soft" "tcp" "_netdev"];
  };

  #swapDevices = [
  #  {device = "/dev/disk/by-uuid/a6e9dd8b-6767-44f4-84fa-30d02d90d087";}
  #];

  networking.useDHCP = lib.mkDefault true;

  security.sudo.wheelNeedsPassword = lib.mkForce false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
