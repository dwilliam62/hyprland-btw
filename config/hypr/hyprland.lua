local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local hypr_dir = config_home .. "/hypr"

local function load_module(name)
  dofile(hypr_dir .. "/lua/" .. name .. ".lua")
end

load_module("monitors")
load_module("startup")
load_module("env")
load_module("settings")
load_module("decorations")
load_module("animations")
load_module("window_rules")
load_module("keybinds")
load_module("workspaces")
load_module("user_overrides")
