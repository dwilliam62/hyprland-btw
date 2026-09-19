#!/usr/bin/env bash
# ==================================================
#  MangoWC - (2026)
#  Toggle outer gaps
# ==================================================

set -euo pipefail

CONFIG_FILE="${HOME}/.config/mangowc/config.conf"
TAG_FILE="${HOME}/.config/mangowc/tag.conf"
STATE_FILE="${HOME}/.config/mangowc/.recording_mode"

STRUCTS=0

if [[ -f "${STATE_FILE}" ]]; then
    NEW_GAPPOH=10
    MODE="Normal"
    rm -f "${STATE_FILE}"
else
    NEW_GAPPOH=40
    MODE="Spacious"
    touch "${STATE_FILE}"
fi

if [[ -f "${CONFIG_FILE}" ]]; then
    sed -i "s/^scroller_structs=.*/scroller_structs=${STRUCTS}/" "${CONFIG_FILE}" 2>/dev/null || true
    sed -i "s/^gappoh=.*/gappoh=${NEW_GAPPOH}/" "${CONFIG_FILE}" 2>/dev/null || true
fi

if command -v mmsg >/dev/null 2>&1; then
    mmsg dispatch reload_config 2>/dev/null || true
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Mode: ${MODE}" "Structs: ${STRUCTS}px | Gaps: ${NEW_GAPPOH}px" 2>/dev/null || true
fi
