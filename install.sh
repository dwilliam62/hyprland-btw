#!/usr/bin/env bash

######################################
# Install script for hyprland-btw Hyprland config
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
  echo -e "${GREEN}║       hyprland-btw Hyprland configuration applied successfully!       ║${NC}"
  echo -e "${GREEN}║   Please reboot your system for changes to take full effect.          ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

prompt_yes_no() {
  # Usage: prompt_yes_no "Question?" [default]
  # default: Y or N (case-insensitive). If omitted, default is Y.
  local question="$1"
  local def="${2:-Y}"
  local ans=""
  local suffix="[Y/n]"
  if [[ "$def" =~ ^[Nn]$ ]]; then suffix="[y/N]"; fi
  while true; do
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
      printf "%s %s " "$question" "$suffix" > /dev/tty
      IFS= read -r ans < /dev/tty || ans=""
    else
      printf "%s %s " "$question" "$suffix"
      IFS= read -r ans || ans=""
    fi
    # Trim whitespace
    ans="${ans//[$'\t\r\n ']}"
    if [[ -z "$ans" ]]; then
      if [[ "$def" =~ ^[Yy]$ ]]; then return 0; else return 1; fi
    fi
    # Lowercase comparison (bash >= 4)
    case "${ans,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

is_valid_username() {
  # POSIX-ish: start with [a-z_], then [a-z0-9_-]; limit to 32 chars
  local u="$1"
  [[ "$u" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]
}

ensure_username() {
  # Reads/validates $userName (already populated) and enforces existence or explicit consent
  while true; do
    if [ -z "$userName" ]; then
      userName="$defaultUserName"
    fi
    if ! is_valid_username "$userName"; then
      echo -e "${RED}Invalid username '$userName'. Use lowercase letters, digits, '_' or '-', starting with a letter or '_' (max 32).${NC}"
      if [ $NONINTERACTIVE -eq 1 ]; then
        exit 1
      fi
      printf "Enter primary username for this system [%s]: " "$defaultUserName"
      IFS= read -r userName
      continue
    fi
    if id -u "$userName" >/dev/null 2>&1 || getent passwd "$userName" >/dev/null 2>&1; then
      echo -e "${GREEN}User '$userName' exists on this system.${NC}"
      break
    fi
    echo -e "${YELLOW}User '$userName' does not currently exist on this system.${NC}"
    echo -e "${YELLOW}It will be created during nixos-rebuild (users.users.\"$userName\" is defined).${NC}"
    if [ $NONINTERACTIVE -eq 1 ]; then
      echo -e "Non-interactive: proceeding with automatic creation."
      break
    fi
    if prompt_yes_no "Proceed with creating '$userName' on switch?" N; then
      break
    fi
    # Reprompt for a different username
    printf "Enter a different username [%s]: " "$defaultUserName"
    IFS= read -r userName
  done
}

print_failure_banner() {
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║         hyprland-btw installation failed during nixos-rebuild.        ║${NC}"
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

print_header "Using existing hyprland-btw repository"

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
defaultUserName="${USER:-your-username}"
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
  ensure_username

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

print_header "User and Root Password Checks"

# Username was validated and confirmed earlier in ensure_username
: # no-op

# 2) Check if root has a usable password; if not, offer to set it now.
#    Root is considered unset/locked if the shadow field is empty or starts with '!' or '*'.
ROOT_FIELD=$(sudo awk -F: '$1=="root"{print $2}' /etc/shadow 2>/dev/null || true)
if [[ -z "$ROOT_FIELD" || "$ROOT_FIELD" == '!'* || "$ROOT_FIELD" == '*'* ]]; then
  echo -e "${YELLOW}Root password appears unset or locked.${NC}"
  if [ $NONINTERACTIVE -eq 1 ]; then
    echo -e "Non-interactive: skipping root password configuration. Use 'sudo passwd root' later."
  else
    read -p "Set the root password now? (Y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "You will be prompted to enter a new password for root."
      if ! sudo passwd root; then
        print_error "Failed to set root password."
        read -p "Continue anyway? (Y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          exit 1
        fi
      fi
    fi
  fi
else
  echo -e "${GREEN}Root password appears to be set.${NC}"
fi

echo -e "${GREEN}Selected timezone: $timeZone${NC}"
echo -e "${GREEN}Selected hostname: $hostName${NC}"
echo -e "${GREEN}Selected username: $userName${NC}"
echo -e "${GREEN}Selected keyboard layout: $keyboardLayout${NC}"
echo -e "${GREEN}Selected console keymap: $consoleKeyMap${NC}"
echo -e "${GREEN}Selected GPU profile: $GPU_PROFILE${NC}"

# Detect existing human users (UID >= 1000) to preserve; exclude the chosen primary user.
PRESERVE_USERS=()
while IFS=: read -r _name _pw _uid _gid _gecos _home _shell; do
  # skip non-numeric or malformed UID entries just in case
  if [[ "${_uid}" =~ ^[0-9]+$ ]] && [ "${_uid}" -ge 1000 ]; then
    # ignore disabled shells
    if [[ "${_shell}" != */nologin && "${_shell}" != */false ]]; then
      if [[ "${_name}" != "${userName}" ]]; then
        PRESERVE_USERS+=("${_name}")
      fi
    fi
  fi
done < <(getent passwd || cat /etc/passwd)

if [ ${#PRESERVE_USERS[@]} -gt 0 ]; then
  echo -e "${YELLOW}Preserving existing users (will not be removed on switch): ${PRESERVE_USERS[*]}${NC}"
  # Ensure we do not delete undeclared users: enable mutable users policy.
  if grep -qE '\busers\.mutableUsers\b' ./configuration.nix; then
    sed -i 's|users\.mutableUsers = .*;|users.mutableUsers = true;|' ./configuration.nix
  else
    # Insert after nix.settings.experimental-features for a stable anchor
    sed -i '/nix\.settings\.experimental-features/a\  users.mutableUsers = true;' ./configuration.nix
  fi
else
  echo -e "${GREEN}No additional existing human users detected to preserve.${NC}"
fi

# Patch configuration.nix with chosen timezone, hostname, username, layouts, and VM profile.
sed -i -E 's|(^\s*time\.timeZone\s*=\s*\").*(\";)|\1'"$timeZone"'\2|' ./configuration.nix
# configuration.nix defines hostName inside the networking attrset (not networking.hostName = ...)
sed -i -E 's|(^\s*hostName\s*=\s*\").*(\";)|\1'"$hostName"'\2|' ./configuration.nix

# Determine the currently-declared primary user in configuration.nix
CURRENT_DECLARED_USER=$(sed -n -E 's/.*users\.users\."([^"]+)"\s*=\s*\{.*/\1/p' ./configuration.nix | head -n1 || true)
if [ -z "$CURRENT_DECLARED_USER" ]; then
  CURRENT_DECLARED_USER="dwilliams"
fi

# If the chosen username differs, do NOT rename the existing user entry.
# Instead, add a new users.users block for the new primary user and force users.mutableUsers = true.
if [ "$userName" != "$CURRENT_DECLARED_USER" ]; then
  echo -e "${YELLOW}Primary user changed: ${CURRENT_DECLARED_USER} -> ${userName}. Adding new user entry and keeping existing users.${NC}"
  # Ensure users.mutableUsers = true so undeclared users are not removed.
  if grep -qE '\busers\.mutableUsers\b' ./configuration.nix; then
    sed -i 's|users\.mutableUsers = .*;|users.mutableUsers = true;|' ./configuration.nix
  else
    sed -i '/nix\.settings\.experimental-features/a\  users.mutableUsers = true;' ./configuration.nix
  fi
  # Only add a new entry if it doesn't already exist
  if ! grep -qE "users\.users\\.\"${userName}\"\s*=\s*\{" ./configuration.nix; then
    # Insert a minimal user definition after the existing primary user block
    awk -v newuser="$userName" '
      BEGIN{added=0}
      {
        print $0
        if(!added && $0 ~ /users\.users\."([^"]+)"\s*=\s*\{/){
          # Wait until we hit the closing brace of that block
          inblk=1
        }
        if(inblk && $0 ~ /^\s*};\s*$/){
          print "\n  users.users.\"" newuser "\" = {";
          print "    isNormalUser = true;";
          print "    extraGroups = [ \"wheel\" \"input\" ];";
          print "    home = \"/home/" newuser "\";";
          print "    createHome = true;";
          print "    shell = pkgs.zsh;";
          print "  };\n";
          added=1; inblk=0
        }
      }
      END{ if(!added){
        print "\n  users.users.\"" newuser "\" = {";
        print "    isNormalUser = true;";
        print "    extraGroups = [ \"wheel\" \"input\" ];";
        print "    home = \"/home/" newuser "\";";
        print "    createHome = true;";
        print "    shell = pkgs.zsh;";
        print "  };";
      }}
    ' ./configuration.nix > ./configuration.nix.tmp && mv ./configuration.nix.tmp ./configuration.nix
  fi
else
  echo -e "${GREEN}Primary username unchanged (${userName}); leaving users.users entries as-is.${NC}"
fi

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

# Update flake.nix: rename the nixosConfigurations.<name> attribute to the chosen hostname
sed -i -E 's|(nixosConfigurations\.)[A-Za-z0-9._-]+(\s*=)|\1'"$hostName"'\2|' ./flake.nix
# Update flake.nix and home.nix to avoid hardcoded username.
sed -i -E 's|users\."[^"]+"\s*=\s*import \./home\.nix;|users."'"$userName"'" = import ./home.nix;|' ./flake.nix
sed -i -E 's|home\.username = lib\.mkDefault ".*";|home.username = lib.mkDefault '"\"$userName\""';|' ./home.nix
sed -i -E 's|home\.homeDirectory = lib\.mkDefault "/home/.*";|home.homeDirectory = lib.mkDefault '"\"/home/$userName\""';|' ./home.nix

print_header "Hardware Configuration"

TARGET_HW="./hardware-configuration.nix"
OWNER_USER="${SUDO_USER:-${USER:-$(whoami)}}"

backup_if_exists() {
  if [ -f "$TARGET_HW" ]; then
    local ts
    ts="$(date +%s)"
    mv "$TARGET_HW" "${TARGET_HW}.backup.${ts}"
    echo -e "${YELLOW}Backed up existing hardware-configuration.nix to ${TARGET_HW}.backup.${ts}${NC}"
  fi
}

copy_from() {
  local src="$1"
  backup_if_exists
  cp "$src" "$TARGET_HW"
  chown "$OWNER_USER":"$OWNER_USER" "$TARGET_HW" 2>/dev/null || true
  echo -e "${GREEN}Wrote $TARGET_HW from $src${NC}"
}

write_from_show() {
  backup_if_exists
  # Prefer writing as the invoking user so the file is not root-owned.
  if nixos-generate-config --show-hardware-config > "$TARGET_HW" 2>/dev/null; then
    chown "$OWNER_USER":"$OWNER_USER" "$TARGET_HW" 2>/dev/null || true
    echo -e "${GREEN}Wrote $TARGET_HW from nixos-generate-config --show-hardware-config${NC}"
    return 0
  fi
  return 1
}

ensure_hw_config() {
  # 1) Prefer existing system file
  if [ -f /etc/nixos/hardware-configuration.nix ]; then
    if [ $NONINTERACTIVE -eq 1 ]; then
      echo -e "Non-interactive: using existing /etc/nixos/hardware-configuration.nix"
      copy_from /etc/nixos/hardware-configuration.nix
      return 0
    else
      read -p "Use existing /etc/nixos/hardware-configuration.nix? (Y=use existing, N=generate new) [Y]: " -n 1 -r
      echo
      if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
        copy_from /etc/nixos/hardware-configuration.nix
        return 0
      fi
    fi
  else
    echo -e "${YELLOW}/etc/nixos/hardware-configuration.nix not found.${NC}"
  fi

  # 2) Try generating directly to repo without touching /etc
  if write_from_show; then
    return 0
  fi

  # 3) If inside installer with target mounted at /mnt, try that path
  if [ -f /mnt/etc/nixos/hardware-configuration.nix ]; then
    echo -e "${GREEN}Found /mnt/etc/nixos/hardware-configuration.nix${NC}"
    copy_from /mnt/etc/nixos/hardware-configuration.nix
    return 0
  fi

  # 4) As a fallback, generate into / (or /mnt if present) and copy
  local root="/"
  if mountpoint -q /mnt 2>/dev/null; then
    root="/mnt"
  fi
  echo -e "${YELLOW}Generating hardware config with: sudo nixos-generate-config --root ${root}${NC}"
  sudo nixos-generate-config --root "$root"
  if [ -f "$root/etc/nixos/hardware-configuration.nix" ]; then
    copy_from "$root/etc/nixos/hardware-configuration.nix"
    return 0
  fi

  return 1
}

if ensure_hw_config; then
  :
else
  print_error "hardware-configuration.nix could not be created."
  echo -e "Tried: existing /etc, --show-hardware-config, /mnt, and --root fallback."
  exit 1
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

FLAKE_TARGET="#${hostName}"
if sudo nixos-rebuild boot --flake .${FLAKE_TARGET} --option accept-flake-config true --refresh; then
  print_success_banner
  echo ""
  if [ $NONINTERACTIVE -eq 1 ]; then
    echo "Non-interactive: please reboot your system to start using ${hostName}."
  else
    read -p "Reboot now to start using ${hostName}? (Y/N): " -n 1 -r
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
