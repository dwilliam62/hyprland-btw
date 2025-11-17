{ ... }:
{
  imports = [
    ./amd-drivers.nix
    ./intel-drivers.nix
    ./nvidia-drivers.nix
    ./vm-guest-services.nix
  ];
}
