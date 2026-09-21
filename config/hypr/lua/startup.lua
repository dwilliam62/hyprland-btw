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
