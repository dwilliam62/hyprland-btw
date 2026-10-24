local session = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function exec_once(cmd)
  local key = tostring(cmd):gsub("[^%w_.-]", "_"):sub(1, 80)
  local marker = "/tmp/hypr-lua-exec-once-" .. session .. "-" .. key
  local log = "/tmp/hypr-lua-startup-" .. key .. ".log"

  local script = "[ -e "
    .. shell_quote(marker)
    .. " ] || { touch "
    .. shell_quote(marker)
    .. " && sh -lc "
    .. shell_quote(cmd)
    .. " >>"
    .. shell_quote(log)
    .. " 2>&1 & }"

  os.execute("sh -lc " .. shell_quote(script))
end

local startup_commands = {
  "hyprpaper",
  "qs -c overview",
  -- noctalia is started by the noctalia.service systemd user unit
  -- (config/noctalia.nix), which waits for the Wayland socket and sets
  -- the correct NOCTALIA_CONFIG_HOME/NOCTALIA_STATE_HOME for the WM.
  -- Do NOT also exec it here: a raw instance launched before that env
  -- setup races the systemd-managed one for noctalia's single-instance
  -- lock, causing repeated "noctalia is already running" restarts and
  -- an unpredictable winner (sometimes without the Hyprland-specific
  -- config), which is why panels like Settings can behave oddly.
  --
  -- We do have to ask systemd for the unit, though. WantedBy=default.target
  -- only starts it the first time the user manager reaches default.target,
  -- and that manager outlives the graphical session: on logout noctalia sees
  -- the Wayland socket die and exits 0, which Restart=on-failure ignores, so
  -- nothing brings it back on the next login. Import the live session's
  -- variables first (the way mangowc/autostart.sh does) so the unit cannot
  -- inherit a stale HYPRLAND_INSTANCE_SIGNATURE/WAYLAND_DISPLAY.
  "systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true; systemctl --user start noctalia.service",
  "systemctl --user start hyprpolkitagent",
}

local function run_startup_commands()
  for _, cmd in ipairs(startup_commands) do
    exec_once(cmd)
  end
end

if hl and hl.on then
  hl.on("hyprland.start", run_startup_commands)
else
  run_startup_commands()
end
