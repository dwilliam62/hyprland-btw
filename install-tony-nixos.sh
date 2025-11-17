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

if [ -n "$(grep -i nixos </etc/os-release || true)" ]; then
  echo -e "${GREEN}Verified this is NixOS.${NC}"
else
  print_error "This is not NixOS or the distribution information is not available."
  exit 1
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

if [ $NONINTERACTIVE -eq 1 ]; then
  timeZone="$defaultTimeZone"
  echo -e "Non-interactive: defaulting timezone to $timeZone"
else
  read -rp "Enter your timezone [${defaultTimeZone}]: " timeZone
  if [ -z "$timeZone" ]; then
    timeZone="$defaultTimeZone"
  fi
fi

echo -e "${GREEN}Selected timezone: $timeZone${NC}"

sed -i "s|time.timeZone = \".*\";|time.timeZone = \"$timeZone\";|" ./configuration.nix

print_header "Hardware Configuration"

TARGET_HW="./hardware-configuration.nix"

if [ -f /etc/nixos/hardware-configuration.nix ]; then
  echo -e "${GREEN}Copying /etc/nixos/hardware-configuration.nix into this repo${NC}"
  sudo cp /etc/nixos/hardware-configuration.nix "$TARGET_HW"
else
  print_error "/etc/nixos/hardware-configuration.nix not found."
  echo -e "Please generate it with: nixos-generate-config --root /"
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

print_header "Running nixos-rebuild"

if sudo nixos-rebuild switch --flake .#hyprland-btw --option accept-flake-config true --refresh; then
  print_success_banner
else
  print_failure_banner
  exit 1
fi
