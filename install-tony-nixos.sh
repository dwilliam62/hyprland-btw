#!/usr/bin/env bash

######################################
# Install script for tony-nixos Hyprland config
# Author:  Don Williams
# Ported from ddubsOS installer (simplified for single-host setup)
#######################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &> /dev/null && pwd)"
LOG_FILE="${SCRIPT_DIR}/install_$(date +"%Y-%m-%d_%H-%M-%S").log"

mkdir -p "$SCRIPT_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

print_header() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║ ${1} ${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_error() {
  echo -e "${RED}Error: ${1}${NC}"
}

print_success_banner() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║       tony-nixos Hyprland configuration applied successfully!         ║${NC}"
  echo -e "${GREEN}║   Please reboot your system for changes to take full effect.          ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_failure_banner() {
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║         tony-nixos installation failed during nixos-rebuild.          ║${NC}"
  echo -e "${RED}║   Please review the log file for details:                             ║${NC}"
  echo -e "${RED}║   ${LOG_FILE}                                                        ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

NONINTERACTIVE=0

print_usage() {
  cat <<EOF
Usage: $0 [--non-interactive]

Options:
  --non-interactive  Do not prompt; accept defaults and proceed automatically
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --non-interactive)
      NONINTERACTIVE=1
      shift 1
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

print_header "Verifying System Requirements"

if ! command -v git &>/dev/null; then
  print_error "Git is not installed."
  echo -e "Please install git, then re-run the install script."
  echo -e "Example: nix-shell -p git"
  exit 1
fi

if ! command -v lspci &>/dev/null; then
  print_error "pciutils (lspci) is not installed."
  echo -e "Please install pciutils, then re-run the install script."
  echo -e "Example: nix-shell -p pciutils"
  exit 1
fi

if [ -n "$(grep -i nixos </etc/os-release || true)" ]; then
  echo -e "${GREEN}Verified this is NixOS.${NC}"
else
  print_error "This is not NixOS or the distribution information is not available."
  exit 1
fi

# GPU profile detection (VM / amd / intel / nvidia), adapted from ddubsOS.
GPU_PROFILE=""
has_nvidia=false
has_intel=false
has_amd=false
has_vm=false

if lspci | grep -qi 'vga\|3d'; then
  while read -r line; do
    if   echo "$line" | grep -qi 'nvidia'; then
      has_nvidia=true
    elif echo "$line" | grep -qi 'amd'; then
      has_amd=true
    elif echo "$line" | grep -qi 'intel'; then
      has_intel=true
    elif echo "$line" | grep -qi 'virtio\|vmware'; then
      has_vm=true
    fi
  done < <(lspci | grep -i 'vga\|3d')

  if   $has_vm; then
    GPU_PROFILE="vm"
  elif $has_nvidia && $has_intel; then
    GPU_PROFILE="nvidia"  # treat hybrid laptop as primary NVIDIA for this simple setup
  elif $has_nvidia; then
    GPU_PROFILE="nvidia"
  elif $has_amd; then
    GPU_PROFILE="amd"
  elif $has_intel; then
    GPU_PROFILE="intel"
  fi
fi

if [ -n "$GPU_PROFILE" ]; then
  echo -e "${GREEN}Detected GPU profile: $GPU_PROFILE${NC}"
  if [ $NONINTERACTIVE -eq 1 ]; then
    echo -e "Non-interactive: accepting detected GPU profile"
  else
    read -p "Is this GPU profile correct? (Y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}GPU profile not confirmed. Falling back to manual selection.${NC}"
      GPU_PROFILE=""
    fi
  fi
fi

if [ -z "$GPU_PROFILE" ]; then
  if [ $NONINTERACTIVE -eq 1 ]; then
    GPU_PROFILE="vm"
    echo -e "Non-interactive: defaulting GPU profile to $GPU_PROFILE"
  else
    echo -e "${YELLOW}Automatic GPU detection failed or no specific profile found.${NC}"
    echo -e "Available GPU profiles: amd | intel | nvidia | vm"
    read -rp "Enter GPU profile [ vm ]: " GPU_PROFILE
    if [ -z "$GPU_PROFILE" ]; then
      GPU_PROFILE="vm"
    fi
  fi
fi

print_header "Using existing tony-nixos repository"

cd "$SCRIPT_DIR" || exit 1
echo -e "${GREEN}Current directory: $(pwd)${NC}"

print_header "Timezone Configuration"

echo -e "Common timezones:"
echo -e "  America/New_York    (Eastern Time)"
echo -e "  America/Chicago     (Central Time)"
echo -e "  America/Denver      (Mountain Time)"
echo -e "  America/Los_Angeles (Pacific Time)"
echo -e "  Europe/London       (GMT/BST)"
echo -e "  Europe/Paris        (CET/CEST)"
echo -e "  Asia/Tokyo          (JST)"
echo -e "  UTC                 (Coordinated Universal Time)"

defaultTimeZone="America/New_York"

defaultHostName="hyprland-btw"
defaultUserName="${USER:-dwilliams}"
defaultKeyboardLayout="us"
defaultConsoleKeyMap="us"

if [ $NONINTERACTIVE -eq 1 ]; then
  timeZone="$defaultTimeZone"
  hostName="$defaultHostName"
  userName="$defaultUserName"
  keyboardLayout="$defaultKeyboardLayout"
  consoleKeyMap="$defaultConsoleKeyMap"
  echo -e "Non-interactive: defaulting timezone to $timeZone"
  echo -e "Non-interactive: defaulting hostname to $hostName"
  echo -e "Non-interactive: defaulting username to $userName"
  echo -e "Non-interactive: defaulting keyboard layout to $keyboardLayout"
  echo -e "Non-interactive: defaulting console keymap to $consoleKeyMap"
else
  read -rp "Enter your timezone [${defaultTimeZone}]: " timeZone
  if [ -z "$timeZone" ]; then
    timeZone="$defaultTimeZone"
  fi

  echo ""
  read -rp "Enter hostname for this system [${defaultHostName}]: " hostName
  if [ -z "$hostName" ]; then
    hostName="$defaultHostName"
  fi

  echo ""
  read -rp "Enter primary username for this system [${defaultUserName}]: " userName
  if [ -z "$userName" ]; then
    userName="$defaultUserName"
  fi

  echo ""
  echo -e "Common keyboard layouts:"
  echo -e "  us      (US QWERTY - most common)"
  echo -e "  uk      (UK QWERTY)"
  echo -e "  de      (German QWERTZ)"
  echo -e "  fr      (French AZERTY)"
  echo -e "  es      (Spanish QWERTY)"
  echo -e "  it      (Italian QWERTY)"
  echo -e "  dvorak  (Dvorak layout)"
  echo -e "  colemak (Colemak layout)"
  echo ""
  read -rp "Enter your keyboard layout [ ${defaultKeyboardLayout} ]: " keyboardLayout
  if [ -z "$keyboardLayout" ]; then
    keyboardLayout="$defaultKeyboardLayout"
  fi

  echo ""
  echo -e "Console keymap usually matches keyboard layout"
  echo -e "Common console keymaps:"
  echo -e "  us    (US layout)"
  echo -e "  uk    (UK layout)"
  echo -e "  de    (German layout)"
  echo -e "  fr    (French layout)"
  echo ""
  read -rp "Enter your console keymap [ ${keyboardLayout} ]: " consoleKeyMap
  if [ -z "$consoleKeyMap" ]; then
    consoleKeyMap="$keyboardLayout"
  fi
fi

echo -e "${GREEN}Selected timezone: $timeZone${NC}"
echo -e "${GREEN}Selected hostname: $hostName${NC}"
echo -e "${GREEN}Selected username: $userName${NC}"
echo -e "${GREEN}Selected keyboard layout: $keyboardLayout${NC}"
echo -e "${GREEN}Selected console keymap: $consoleKeyMap${NC}"
echo -e "${GREEN}Selected GPU profile: $GPU_PROFILE${NC}"

# Patch configuration.nix with chosen timezone, hostname, username, layouts, and VM profile.
sed -i "s|time.timeZone = \".*\";|time.timeZone = \"$timeZone\";|" ./configuration.nix
sed -i "s|networking.hostName = \".*\";|networking.hostName = \"$hostName\";|" ./configuration.nix
# Update the primary user attribute from users.users.dwilliams to the chosen username.
sed -i "s|users.users\\.dwilliams = {|users.users.\"$userName\" = { |" ./configuration.nix
# Update console keymap and XKB layout.
sed -i "s|console.keyMap = \".*\";|console.keyMap = \"$consoleKeyMap\";|" ./configuration.nix
sed -i "s|xserver.xkb.layout = \".*\";|xserver.xkb.layout = \"$keyboardLayout\";|" ./configuration.nix
# Toggle VM guest services based on GPU profile.
if [ "$GPU_PROFILE" = "vm" ]; then
  sed -i "s|vm.guest-services.enable = .*;|vm.guest-services.enable = true;|" ./configuration.nix
else
  sed -i "s|vm.guest-services.enable = .*;|vm.guest-services.enable = false;|" ./configuration.nix
fi

# Enable the matching GPU driver module and disable the others.
case "$GPU_PROFILE" in
  amd)
    sed -i "s|drivers.amdgpu.enable = .*;|drivers.amdgpu.enable = true;|" ./configuration.nix
    sed -i "s|drivers.intel.enable = .*;|drivers.intel.enable = false;|" ./configuration.nix
    sed -i "s|drivers.nvidia.enable = .*;|drivers.nvidia.enable = false;|" ./configuration.nix
    ;;
  intel)
    sed -i "s|drivers.amdgpu.enable = .*;|drivers.amdgpu.enable = false;|" ./configuration.nix
    sed -i "s|drivers.intel.enable = .*;|drivers.intel.enable = true;|" ./configuration.nix
    sed -i "s|drivers.nvidia.enable = .*;|drivers.nvidia.enable = false;|" ./configuration.nix
    ;;
  nvidia)
    sed -i "s|drivers.amdgpu.enable = .*;|drivers.amdgpu.enable = false;|" ./configuration.nix
    sed -i "s|drivers.intel.enable = .*;|drivers.intel.enable = false;|" ./configuration.nix
    sed -i "s|drivers.nvidia.enable = .*;|drivers.nvidia.enable = true;|" ./configuration.nix
    ;;
  vm|*)
    # VM / unknown: leave all hardware drivers disabled; virtio/VM driver is used.
    sed -i "s|drivers.amdgpu.enable = .*;|drivers.amdgpu.enable = false;|" ./configuration.nix
    sed -i "s|drivers.intel.enable = .*;|drivers.intel.enable = false;|" ./configuration.nix
    sed -i "s|drivers.nvidia.enable = .*;|drivers.nvidia.enable = false;|" ./configuration.nix
    ;;
esac

# Update flake.nix and home.nix to avoid hardcoded username.
sed -i "s|users.dwilliams = import ./home.nix;|users.$userName = import ./home.nix;|" ./flake.nix
sed -i "s|home.username = \"dwilliams\";|home.username = \"$userName\";|" ./home.nix
sed -i "s|home.homeDirectory = \"/home/dwilliams\";|home.homeDirectory = \"/home/$userName\";|" ./home.nix

print_header "Hardware Configuration"

TARGET_HW="./hardware-configuration.nix"

if [ -f /etc/nixos/hardware-configuration.nix ]; then
  echo -e "${GREEN}Found existing /etc/nixos/hardware-configuration.nix${NC}"
  if [ $NONINTERACTIVE -eq 1 ]; then
    echo -e "Non-interactive: using existing hardware-configuration.nix"
    sudo cp /etc/nixos/hardware-configuration.nix "$TARGET_HW"
  else
    read -p "Use existing /etc/nixos/hardware-configuration.nix? (Y=use existing, N=generate new) [Y]: " -n 1 -r
    echo
    if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Copying existing hardware-configuration.nix into this repo${NC}"
      sudo cp /etc/nixos/hardware-configuration.nix "$TARGET_HW"
    else
      echo -e "${YELLOW}Generating a new hardware-configuration.nix with: sudo nixos-generate-config --root /${NC}"
      sudo nixos-generate-config --root /
      if [ -f /etc/nixos/hardware-configuration.nix ]; then
        echo -e "${GREEN}Copying newly generated hardware-configuration.nix into this repo${NC}"
        sudo cp /etc/nixos/hardware-configuration.nix "$TARGET_HW"
      else
        print_error "hardware-configuration.nix still not found after generation."
        exit 1
      fi
    fi
  fi
else
  echo -e "${YELLOW}/etc/nixos/hardware-configuration.nix not found.${NC}"
  if [ $NONINTERACTIVE -eq 1 ]; then
    echo -e "Non-interactive: generating hardware config with: sudo nixos-generate-config --root /"
    sudo nixos-generate-config --root /
  else
    read -p "Generate a new hardware-configuration.nix with 'sudo nixos-generate-config --root /'? (Y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_error "Cannot continue without a hardware-configuration.nix"
      echo -e "Please run: sudo nixos-generate-config --root /"
      exit 1
    fi
    sudo nixos-generate-config --root /
  fi

  if [ -f /etc/nixos/hardware-configuration.nix ]; then
    echo -e "${GREEN}Copying newly generated /etc/nixos/hardware-configuration.nix into this repo${NC}"
    sudo cp /etc/nixos/hardware-configuration.nix "$TARGET_HW"
  else
    print_error "hardware-configuration.nix still not found after generation attempt."
    exit 1
  fi
fi

print_header "Pre-build Verification"

echo -e "About to build configuration with these settings:"
echo -e "  🌍  Timezone: ${GREEN}$timeZone${NC}"

echo -e "${YELLOW}This will build and apply your Hyprland configuration.${NC}"

echo ""
if [ $NONINTERACTIVE -eq 1 ]; then
  echo -e "Non-interactive: proceeding with build"
else
  read -p "Ready to run initial build? (Y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Build cancelled.${NC}"
    exit 1
  fi
fi

print_header "Running nixos-rebuild (boot)"

if sudo nixos-rebuild boot --flake .#hyprland-btw --option accept-flake-config true --refresh; then
  print_success_banner
  echo ""
  if [ $NONINTERACTIVE -eq 1 ]; then
    echo "Non-interactive: please reboot your system to start using tony-nixos."
  else
    read -p "Reboot now to start using tony-nixos? (Y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Rebooting..."
      sudo reboot
    else
      echo "You chose not to reboot now. Please reboot manually when ready."
    fi
  fi
else
  print_failure_banner
  exit 1
fi
