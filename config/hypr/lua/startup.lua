local startup_commands = {
  "hyprpaper",
  "qs -c overview",
  "noctalia-shell",
}

for _, cmd in ipairs(startup_commands) do
  hl.exec_once(cmd)
end
