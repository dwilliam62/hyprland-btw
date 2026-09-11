{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./config/fonts.nix
    ./config/packages.nix
    ./config/virtualization.nix #  Emable docker,podman,virtmgr
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # Pin to a known-good LTS kernel to avoid 7.0 boot failures.
    kernelPackages = pkgs.linuxPackages_latest;
    # Prevent systemd from auto-activating GPT swap partitions.
    kernelParams = ["systemd.gpt_auto=0"];
    #kernelPackages = pkgs.linuxPackages_6_19;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 40; # use ~50% of RAM for compressed swap (tweak as you like)
    priority = 100; # higher than any disk-based swap
  };

  networking = {
    hostName = lib.mkDefault "hyprland-btw";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  # Default driver fallback (overridden per host in hosts/<hostname>/default.nix)
  drivers = {
    amdgpu.enable = lib.mkDefault false;
    intel.enable = lib.mkDefault false;
    nvidia.enable = lib.mkDefault false;
  };

  vm.guest-services.enable = lib.mkDefault false;

  # Add services
  services = {
    getty.autologinUser = null; # disable auto-login
    openssh.enable = true;
    tumbler.enable = true;
    envfs.enable = true;
    seatd.enable = true;
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
    libinput.enable = true;
    # Default XKB layout for Hyprland/X11 (overridden by installer).
    xserver.xkb.layout = "us";
    flatpak.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 256;
        };
      };
      extraConfig.pipewire-pulse."92-low-latency" = {
        context.modules = [
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              pulse.min.req = "256/48000";
              pulse.default.req = "256/48000";
              pulse.max.req = "256/48000";
              pulse.min.quantum = "256/48000";
              pulse.max.quantum = "256/48000";
            };
          }
        ];
      };
    };

    # ly display manager (disabled)
    displayManager.ly.enable = false;

    # Noctalia Greeter (greetd) login manager
    displayManager.noctalia-greeter.enable = true;

    # greetd with tuigreet - TUI display manager alternative (disabled)
    # greetd = {
    #   enable = false;
    #   settings = rec {
    #     initial_session = {
    #       command = "${pkgs.tuigreet}/bin/tuigreet --cmd start-hyprland --user-menu";
    #       user = "greeter";
    #     };
    #     default_session = initial_session;
    #   };
    # };
  };

  programs = {
    dconf.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = false;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
    firefox.enable = false;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    thunar.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true; # ensure system zsh is configured for login shells
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Default console keymap (overridden by installer).
  console.keyMap = "us";

  # Define the primary user account. Don't forget to set a password with ‘passwd’.
  users.users."dwilliams" = {
    isNormalUser = true;
    extraGroups = ["wheel" "input" "docker" "video" "libvirtd"]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh; # default login shell
    packages = with pkgs; [
      tree
    ];
  };

  # Example: add additional users (uncomment and adjust as needed)
  # users.users."seconduser" = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  #   shell = pkgs.zsh;
  #   packages = with pkgs; [
  #     git
  #     htop
  #   ];
  # };

  # trying standard Garbage collection
  #  `nh` might not be working
  #  I disabled GC in config/nh.nix for now

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  systemd.services.flatpak-add-flathub = {
    description = "Add Flathub Flatpak remote";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "flatpak-system-helper.service"];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Qt6 environment for quickshell
  environment.sessionVariables =
    {
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    }
    // (lib.optionalAttrs (config.vm.guest-services.enable || config.drivers.nvidia.enable) {
      WLR_NO_HARDWARE_CURSORS = "1";
    });

  # Fix upside-down / glitchy cursor in wlroots (noctalia-greeter) on VM or NVIDIA
  environment.etc."environment".text = lib.mkIf (config.vm.guest-services.enable || config.drivers.nvidia.enable) ''
    WLR_NO_HARDWARE_CURSORS=1
  '';

  systemd.services.greetd = lib.mkIf (config.vm.guest-services.enable || config.drivers.nvidia.enable) {
    environment = {
      WLR_NO_HARDWARE_CURSORS = "1";
    };
    serviceConfig = {
      EnvironmentFile = ["-/etc/environment"];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  security.sudo.wheelNeedsPassword = true;

  # Home Manager backup extension for conflicting files
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "25.11"; # Did you read the comment?
}
