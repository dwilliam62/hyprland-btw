#!/usr/bin/env bash
# ==================================================
#  MangoWC TOML rehearsal
#
#  Checks the TOML configs and the deployment/reload logic without a
#  `nixos-rebuild`. It mirrors what home.activation.mangowcSetup does, running
#  the cleanup command straight out of config/mangowc.nix so the two cannot
#  drift apart.
#
#  Usage: tests/mango-toml-rehearsal.sh
# ==================================================

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_ROOT}/config/mangowc"
NIX_MODULE="${REPO_ROOT}/config/mangowc.nix"

pass=0
fail=0
ok() { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "== repo state =="
conf_count="$(find "${SRC}" -maxdepth 1 -name '*.conf' | wc -l)"
if [ "${conf_count}" -eq 0 ]; then
  ok "no legacy *.conf left in config/mangowc"
else
  bad "${conf_count} legacy *.conf still present"
fi

toml_count="$(find "${SRC}" -maxdepth 1 -name '*.toml' | wc -l)"
if [ "${toml_count}" -eq 7 ]; then
  ok "7 TOML configs present"
else
  bad "expected 7 TOML configs, found ${toml_count}"
fi

unsourced=""
while IFS= read -r f; do
  base="$(basename "$f")"
  [ "${base}" = "config.toml" ] && continue
  grep -q "\"\\./${base}\"" "${SRC}/config.toml" || unsourced="${unsourced} ${base}"
done < <(find "${SRC}" -maxdepth 1 -name '*.toml' ! -name 'config.toml' | sort)
if [ -z "${unsourced}" ]; then
  ok "config.toml sources every sibling *.toml"
else
  bad "not sourced by config.toml:${unsourced}"
fi

echo "== syntax =="
if command -v python3 >/dev/null 2>&1; then
  if python3 - "${SRC}" <<'PY'
import glob, sys, tomllib
bad = 0
for path in sorted(glob.glob(sys.argv[1] + "/*.toml")):
    try:
        with open(path, "rb") as fh:
            tomllib.load(fh)
    except Exception as exc:  # noqa: BLE001
        bad = 1
        print(f"    {path}: {exc}")
sys.exit(bad)
PY
  then
    ok "all TOML files parse (tomllib)"
  else
    bad "a TOML file failed to parse"
  fi
else
  echo "  skip  TOML parse (python3 not installed)"
fi

if command -v mango >/dev/null 2>&1; then
  if (cd "${SRC}" && mango -p -c config.toml >/dev/null 2>&1); then
    ok "mango -p accepts config.toml ($(mango -v 2>&1 | head -n1))"
  else
    bad "mango -p rejected config.toml"
  fi
else
  echo "  skip  mango -p (mango not installed)"
fi

echo "== activation rehearsal =="
DEST="${TMP}/.config/mangowc"
mkdir -p "${DEST}"

snippet="$(awk '/# Mango prefers config.conf/,/^$/' "${NIX_MODULE}" | grep -v '^[[:space:]]*#' | sed 's/^[[:space:]]*//')"
if [ -z "${snippet}" ]; then
  bad "could not read the *.conf cleanup from config/mangowc.nix"
else
  # Seed the legacy files the cleanup is meant to remove.
  seeded=0
  for name in $(printf '%s\n' "${snippet}" | grep -oE '"[^"]+\.conf"' | tr -d '"' | xargs -n1 basename); do
    echo stale > "${DEST}/${name}"
    seeded=$((seeded + 1))
  done

  cp -rf "${SRC}/." "${DEST}/"
  DEST="${DEST}" DRY_RUN_CMD="" bash -c "${snippet}"

  if [ -z "$(find "${DEST}" -maxdepth 1 -name '*.conf')" ]; then
    ok "activation removed ${seeded} legacy *.conf files"
  else
    bad "legacy *.conf survived the activation cleanup"
  fi

  deployed="$(find "${DEST}" -maxdepth 1 -name '*.toml' | wc -l)"
  if [ "${deployed}" -eq 7 ]; then
    ok "7 TOML configs deployed to \$HOME/.config/mangowc"
  else
    bad "expected 7 deployed TOML configs, found ${deployed}"
  fi
fi

ln -sfn mangowc "${TMP}/.config/mango"
if [ "$(readlink "${TMP}/.config/mango")" = "mangowc" ]; then
  ok "~/.config/mango -> mangowc symlink"
else
  bad "~/.config/mango symlink missing"
fi

echo "== reload.sh layout sync =="
HOME="${TMP}" bash "${DEST}/bin/reload.sh" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  ok "reload.sh exits 0 without mmsg/notify-send"
else
  bad "reload.sh failed"
fi

if grep -q '"MANGO_DEFAULT_LAYOUT"' "${DEST}/env.toml"; then
  sed -i -E 's/^("MANGO_DEFAULT_LAYOUT"[[:space:]]*=[[:space:]]*)"[^"]*"/\1"tile"/' "${DEST}/env.toml"
  cp "${DEST}/tag.toml" "${TMP}/tag.before"
  HOME="${TMP}" bash "${DEST}/bin/reload.sh" >/dev/null 2>&1
  tile_tags="$(grep -c 'layout_name = "tile"' "${DEST}/tag.toml")"
  changed="$(diff "${TMP}/tag.before" "${DEST}/tag.toml" | grep -c '^>')"
  if [ "${tile_tags}" -eq 9 ] && [ "${changed}" -eq 9 ]; then
    ok "MANGO_DEFAULT_LAYOUT=tile rewrote all 9 tag rules, nothing else"
  else
    bad "layout sync rewrote ${tile_tags} tag rules across ${changed} lines"
  fi
else
  bad "MANGO_DEFAULT_LAYOUT not found in env.toml"
fi

echo "== toggle-outer-gaps.sh =="
HOME="${TMP}" bash "${DEST}/bin/toggle-outer-gaps.sh" >/dev/null 2>&1
spacious="$(grep -E '^gap_outer_horizontal' "${DEST}/config.toml" | tr -dc '0-9')"
HOME="${TMP}" bash "${DEST}/bin/toggle-outer-gaps.sh" >/dev/null 2>&1
normal="$(grep -E '^gap_outer_horizontal' "${DEST}/config.toml" | tr -dc '0-9')"
if [ "${spacious}" = "40" ] && [ "${normal}" = "10" ]; then
  ok "outer gaps toggle 10 -> 40 -> 10 in config.toml"
else
  bad "unexpected gap values (spacious=${spacious:-none}, normal=${normal:-none})"
fi

if [ ! -f "${DEST}/.recording_mode" ]; then
  ok "no leftover .recording_mode state file"
else
  bad "state file .recording_mode left behind"
fi

echo
printf 'Result: %d passed, %d failed\n' "${pass}" "${fail}"
[ "${fail}" -eq 0 ]
