local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local hypr_dir = config_home .. "/hypr"

local function source_legacy(relative_path)
  local file_path = hypr_dir .. "/" .. relative_path
  local ok = os.execute("hyprctl keyword source " .. string.format("%q", file_path))
  if not ok then
    print("[WARN] failed to source legacy Hyprland file: " .. file_path)
  end
end

source_legacy("binds.conf")
source_legacy("WindowRules.conf")
