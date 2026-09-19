#!/usr/bin/env bash
# ==================================================
#  MangoWC - (2026)
#  Reload script for Mango + Noctalia
# ==================================================

set +e

# Sync default layout from env.conf to tag.conf if set
ENV_CONF="${HOME}/.config/mangowc/env.conf"
TAG_CONF="${HOME}/.config/mangowc/tag.conf"

if [[ -f "${ENV_CONF}" && -f "${TAG_CONF}" ]]; then
    DEF_LAYOUT="$(grep -E '^env=MANGO_DEFAULT_LAYOUT,' "${ENV_CONF}" | cut -d',' -f2 | tr -d ' ' || true)"
    if [[ -n "${DEF_LAYOUT}" ]]; then
        sed -i -E "s/layout_name:[a-zA-Z0-9_]+/layout_name:${DEF_LAYOUT}/g" "${TAG_CONF}"
    fi
fi

# Reload mango configuration
if command -v mmsg >/dev/null 2>&1; then
    mmsg dispatch reload_config 2>/dev/null || true
fi

# Reload Noctalia Shell
if command -v noctalia >/dev/null 2>&1; then
    noctalia msg config-reload 2>/dev/null || noctalia msg reload 2>/dev/null || true
fi

notify-send "Config Reloaded" "Mango and Noctalia reloaded successfully" 2>/dev/null || true
