#!/usr/bin/env bash
# ==================================================
#  MangoWC - (2026)
#  Screenshot script for Mango
# ==================================================

set -euo pipefail

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "${HOME}/Pictures")"
mkdir -p "${PICTURES_DIR}"
FILE="${PICTURES_DIR}/screenshot_$(date +%Y%m%d_%H%M%S).png"

if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
    GEOM="$(slurp 2>/dev/null || true)"
    if [[ -n "${GEOM}" ]]; then
        grim -g "${GEOM}" "${FILE}"
        if command -v wl-copy >/dev/null 2>&1; then
            wl-copy < "${FILE}"
        fi
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Screenshot Captured" "Saved to ${FILE} and copied to clipboard"
        fi
    fi
fi
