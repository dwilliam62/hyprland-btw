{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.drivers.nvidia;
in {
  options.drivers.nvidia = {
    enable = mkEnableOption "Enable Nvidia drivers";
    prime = {
      enable = mkEnableOption "Enable NVIDIA PRIME (hybrid Intel/NVIDIA)";
      offload.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable PRIME render offload (recommended for hybrid laptops).";
      };
      sync.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable PRIME sync (use NVIDIA as the primary renderer).";
      };
      intelBusId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Intel GPU PCI bus ID (e.g., PCI:0:2:0).";
      };
      nvidiaBusId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "NVIDIA GPU PCI bus ID (e.g., PCI:1:0:0).";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          (!cfg.prime.enable)
          || (cfg.prime.intelBusId != null && cfg.prime.nvidiaBusId != null);
        message =
          "drivers.nvidia.prime.enable requires both drivers.nvidia.prime.intelBusId and drivers.nvidia.prime.nvidiaBusId.";
      }
      {
        assertion = !(cfg.prime.offload.enable && cfg.prime.sync.enable);
        message = "Enable either PRIME offload or PRIME sync, not both.";
      }
    ];

    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
      # Use the stable NVIDIA driver package by default; adjust here if needed.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = mkIf cfg.prime.enable {
        offload.enable = cfg.prime.offload.enable;
        sync.enable = cfg.prime.sync.enable;
        intelBusId = cfg.prime.intelBusId;
        nvidiaBusId = cfg.prime.nvidiaBusId;
      };
    };
  };
}
