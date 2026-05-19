local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local user_dir = config_home .. "/hypr/UserConfigs"

local function load_optional(path)
  local ok, err = pcall(dofile, path)
  if ok then
    return true
  end
  if err and tostring(err):find("No such file or directory", 1, true) == nil then
    print("[WARN] unable to load user override file " .. path .. ": " .. tostring(err))
  end
  return false
end

local user_files = {
  "user_env.lua",
  "user_startup.lua",
  "user_window_rules.lua",
  "user_layer_rules.lua",
  "user_keybinds.lua",
  "user_settings.lua",
  "user_decorations.lua",
  "user_animations.lua",
  "user_laptops.lua",
  "user_overrides.lua",
}

for _, file in ipairs(user_files) do
  load_optional(user_dir .. "/" .. file)
end
