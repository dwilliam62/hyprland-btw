#!/usr/bin/env bash
# ==================================================
#  MangoWC - (2026)
#  Reload script for Mango + Noctalia
# ==================================================

set +e

# Sync default layout from env.toml to tag.toml if set
ENV_TOML="${HOME}/.config/mangowc/env.toml"
TAG_TOML="${HOME}/.config/mangowc/tag.toml"

if [[ -f "${ENV_TOML}" && -f "${TAG_TOML}" ]]; then
    DEF_LAYOUT="$(sed -nE 's/^[[:space:]]*"?MANGO_DEFAULT_LAYOUT"?[[:space:]]*=[[:space:]]*"?([A-Za-z0-9_]+)"?[[:space:]]*$/\1/p' "${ENV_TOML}" | head -n1)"
    if [[ -n "${DEF_LAYOUT}" ]]; then
        sed -i -E "s/^([[:space:]]*layout_name[[:space:]]*=[[:space:]]*)\"[^\"]*\"/\1\"${DEF_LAYOUT}\"/" "${TAG_TOML}"
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
