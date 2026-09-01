# HOWTO: Managing Multi-Host NixOS Configurations

This guide explains how to add, modify, remove, and manage hosts in the `hyprland-btw` multi-host NixOS Flake.

---

## 1. Multi-Host Architecture Overview

This repository uses a modular layout where common desktop configurations are shared across all machines, while hardware, GPU drivers, and machine-specific tweaks live in dedicated subdirectories under `./hosts/`.

```
hyprland-btw/
├── flake.nix                  # Auto-discovers all directories under ./hosts/
├── configuration.nix          # Shared system configuration (audio, DE, shell, base packages)
├── home.nix                   # Shared user configuration (Hyprland, waybar, terminals, dotfiles)
└── hosts/
    ├── vm/                    # Virtual Machine profile (hostname: vm / hyprland-btw)
    │   ├── default.nix        # VM driver settings & guest services
    │   └── hardware.nix       # QEMU / virtio / ext4 hardware configuration
    ├── xps15/                 # Dell XPS 15 laptop profile (hostname: xps15)
    │   ├── default.nix        # Intel/NVIDIA PRIME drivers, nix-ld, display quirks
    │   └── hardware.nix       # BTRFS subvolumes, laptop kernel params, Intel microcode
    └── default/               # Template / fallback configuration for generic installs
        ├── default.nix
        └── hardware.nix
```

### How Host Auto-Discovery Works
`flake.nix` scans the `./hosts/` directory and creates a `nixosConfigurations.<hostname>` target for every directory it finds. When you run `nh os switch .` or `sudo nixos-rebuild switch --flake .`, Nix automatically checks the machine's current hostname (`$(hostname)`) and applies the matching configuration.

---

## 2. Adding a New Host

To add a new machine (e.g. `desktop-amd`):

### Step 1: Create Host Directory
Create a folder under `./hosts/` matching your desired hostname:
```bash
mkdir -p hosts/desktop-amd
```

### Step 2: Generate Hardware Configuration
Run the following command on the target machine (or copy an existing `/etc/nixos/hardware-configuration.nix`):
```bash
nixos-generate-config --show-hardware-config > hosts/desktop-amd/hardware.nix
```

### Step 3: Create Host `default.nix`
Create `hosts/desktop-amd/default.nix` to import `hardware.nix` and configure host-specific options:

```nix
{...}: {
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "desktop-amd";

  # GPU Driver Selection (enable exactly what this host needs)
  drivers = {
    amdgpu.enable = true;
    intel.enable = false;
    nvidia.enable = false;
  };

  # Set true only if running inside QEMU / KVM
  vm.guest-services.enable = false;
}
```

### Step 4: Stage in Git (Critical for Nix Flakes)
Nix Flakes cannot read untracked files:
```bash
git add hosts/desktop-amd
```

### Step 5: Test Evaluation
Verify that the new host configuration evaluates cleanly without syntax errors:
```bash
nix eval '.#nixosConfigurations.desktop-amd.config.system.build.toplevel.drvPath'
```

---

## 3. Modifying Host Configurations

### Modifying Host-Specific Settings
Edit `hosts/<hostname>/default.nix` or `hosts/<hostname>/hardware.nix`:
* **GPU Drivers & PRIME:** Adjust `drivers.amdgpu`, `drivers.intel`, or `drivers.nvidia.prime`.
* **Host-Specific Services:** Add services specific to one machine (e.g. `services.foldingathome`, `services.syncthing`, `programs.nix-ld`).
* **Kernel Parameters / Boot Options:** Add `boot.kernelParams` or `boot.kernelPackages` in `hosts/<hostname>/default.nix`.
* **Display / Monitor Quirks:** Add kernel video parameters or display-specific overrides.

### Modifying Shared Settings
* **System-Wide Packages & Services:** Edit `configuration.nix` or modular files in `config/` (e.g. `config/packages.nix`, `config/fonts.nix`, `config/virtualization.nix`).
* **User Dotfiles & Hyprland Configs:** Edit `home.nix` or files in `config/hypr/`, `config/terminals/`, `config/yazi/`, etc.

---

## 4. Removing a Host

To retire or remove an existing host configuration (e.g. `hosts/old-host`):

1. Remove the host directory:
   ```bash
   git rm -r hosts/old-host
   ```
2. Test that the remaining hosts evaluate cleanly:
   ```bash
   nix flake check --no-build
   ```
3. Commit the change:
   ```bash
   git commit -m "Remove old-host configuration"
   ```

---

## 5. Building, Rebuilding, and Switching

### Recommended: Using `nh` (Nix Helper)
`nh` provides human-friendly diffs and automatically uses the active hostname:

```bash
# Rebuild and switch on the current machine (auto-detects hostname):
nh os switch .

# Test configuration without adding a bootloader entry:
nh os test .

# Target a specific remote or alternate host profile:
nh os switch . -H xps15
nh os test . -H vm
```

### Standard: Using `nixos-rebuild`
```bash
# Rebuild and switch (auto-detects hostname):
sudo nixos-rebuild switch --flake .

# Explicitly target a host:
sudo nixos-rebuild switch --flake .#xps15
sudo nixos-rebuild switch --flake .#vm

# Test without adding a boot entry:
sudo nixos-rebuild test --flake .

# Apply on next boot (safe deployment):
sudo nixos-rebuild boot --flake .
```

### Dry Run / Build Verification
To compile and verify a system closure without applying it:
```bash
# Build current host:
nix build ".#nixosConfigurations.$(hostname).config.system.build.toplevel"

# Build specific host:
nix build .#nixosConfigurations.vm.config.system.build.toplevel
nix build .#nixosConfigurations.xps15.config.system.build.toplevel
```

---

## 6. Upgrading Packages & Flake Inputs

To update all packages across all hosts to their latest upstream channels:

1. **Update Flake Lockfile:**
   ```bash
   nix flake update
   ```
2. **Verify That All Hosts Still Evaluate Cleanly:**
   ```bash
   nix flake check --no-build
   ```
3. **Apply the Update:**
   ```bash
   nh os switch .
   # or: sudo nixos-rebuild switch --flake .
   ```
4. **Commit the Updated `flake.lock`:**
   ```bash
   git add flake.lock
   git commit -m "chore: update flake inputs"
   ```

---

## 7. Troubleshooting & Tips

* **`error: getting status of '.../hosts/<name>': No such file or directory`:**
  Remember to run `git add hosts/<name>` after creating new host files. Nix Flakes ignore files untracked by git.
* **`error: attribute '<hostname>' missing`:**
  Check that the folder name in `./hosts/<hostname>` matches the output of `hostname` (or specify the host with `-H <name>` or `.#<name>`).
* **Host Aliases:**
  If a machine uses an alternate or legacy hostname (such as `hyprland-btw`), aliases can be maintained in the `nixosConfigurations` block inside `flake.nix`.
