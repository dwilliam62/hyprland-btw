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
  "noctalia",
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
