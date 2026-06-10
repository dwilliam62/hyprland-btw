-- Auto-generated from config/hypr/binds.conf for permanent Lua runtime.
-- Edit this file directly for Lua-native keybinding changes.

local function trim(value)
	return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function chord(mods, key)
	mods = trim(mods):gsub("%s+", " + ")
	key = trim(key)
	if mods == "" then
		return key
	end
	return mods .. " + " .. key
end

local function exec_cmd(cmd)
	return function()
		hl.exec_cmd(cmd)
	end
end
local function direction(value)
	local directions = {
		l = "left",
		r = "right",
		u = "up",
		d = "down",
		left = "left",
		right = "right",
		up = "up",
		down = "down",
	}
	value = trim(value)
	return directions[value] or value
end

local function dispatch(name, args)
	name = trim(name)
	args = trim(args)

	if name == "killactive" and hl.dsp and hl.dsp.window and hl.dsp.window.close then
		return function()
			hl.dispatch(hl.dsp.window.close())
		end
	end

	if name == "exit" and hl.dsp and hl.dsp.exit then
		return function()
			hl.dispatch(hl.dsp.exit())
		end
	end

	if name == "togglefloating" and hl.dsp and hl.dsp.window and hl.dsp.window.float then
		return function()
			hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		end
	end

	if name == "fullscreen" and hl.dsp and hl.dsp.window and hl.dsp.window.fullscreen then
		local mode = (args == "1") and "maximized" or "fullscreen"
		return function()
			hl.dispatch(hl.dsp.window.fullscreen({ mode = mode }))
		end
	end

	if name == "movefocus" and hl.dsp and hl.dsp.focus then
		local dir = direction(args)
		return function()
			hl.dispatch(hl.dsp.focus({ direction = dir }))
		end
	end

	if name == "swapwindow" and hl.dsp and hl.dsp.window and hl.dsp.window.swap then
		local dir = direction(args)
		return function()
			hl.dispatch(hl.dsp.window.swap({ direction = dir }))
		end
	end

	if name == "workspace" then
		local id = tonumber(args)
		if id and hl.dsp and hl.dsp.focus then
			return function()
				hl.dispatch(hl.dsp.focus({ workspace = id }))
			end
		end
		if args == "" then
			return function() end
		end
		return exec_cmd("hyprctl dispatch workspace " .. args)
	end

	if name == "movetoworkspace" and hl.dsp and hl.dsp.window and hl.dsp.window.move then
		local id = tonumber(args)
		return function()
			if id then
				hl.dispatch(hl.dsp.window.move({ workspace = id }))
			end
		end
	end

	local raw = name
	if args ~= "" then
		raw = raw .. " " .. args
	end
	local cmd = "hyprctl dispatch " .. raw
	return exec_cmd(cmd)
end

local function bindd(mods, key, description, dispatcher, args)
	local action
	if dispatcher == "exec" then
		action = exec_cmd(args)
	else
		action = dispatch(dispatcher, args or "")
	end
	local opts = {}
	if description and description ~= "" then
		opts.description = description
	end
	hl.bind(chord(mods, key), action, opts)
end

local function bindm(mods, key, description, dispatcher)
	local action
	if dispatcher == "movewindow" and hl.dsp and hl.dsp.window and hl.dsp.window.drag then
		action = hl.dsp.window.drag()
	elseif dispatcher == "resizewindow" and hl.dsp and hl.dsp.window and hl.dsp.window.resize then
		action = hl.dsp.window.resize()
	elseif hl.dsp and hl.dsp.exec_raw then
		action = hl.dsp.exec_raw(dispatcher)
	else
		action = dispatch(dispatcher, "")
	end
	hl.bind(chord(mods, key), action, { description = description, mouse = true })
end

bindd("SUPER", "Return", "Launch Terminal", "exec", "ghostty")
bindd("SUPER SHIFT", "Return", "Launch Kitty", "exec", "kitty-bg")
bindd("SUPER", "Q", "Close Active Window", "killactive", "")
bindd("SUPER SHIFT", "Q", "Exit Hyprland", "exit", "")
bindd("SUPER", "T", "Launch FIle Mgr", "exec", "thunar")
bindd("SUPER", "space", "Toggle floating", "togglefloating", "")
bindd("SUPER", "F", "Fullscreen (monitor)", "fullscreen", "1")
bindd("SUPER SHIFT", "F", "Fullscreen (window)", "fullscreen", "")
bindd("SUPER", "R", "Show app menu", "exec", "rofi-legacy.menu")
bindd("SUPER", "S", "Take screenshot", "exec", "snip")
bindd("ALT SHIFT", "S", "Take region screenshot", "exec", "hyprshot -m region -o ~/Pictures/Screenshots")
bindd("SUPER SHIFT", "K", "Search Keybinds", "exec", "keybinds")
bindd("SUPER", "Tab", "QS Overview", "exec", "qs ipc -c overview call overview toggle")
bindd("SUPER", "A", "QS Overview", "exec", "qs ipc -c overview call overview toggle")
bindd("SUPER", "D", "Toggle launcher", "exec", "noctalia msg panel-toggle launcher")
bindd("SUPER", "M", "Toggle notifications", "exec", "noctalia msg panel-toggle control-center notifications")
bindd("SUPER", "V", "Open clipboard", "exec", "noctalia msg panel-toggle clipboard")
bindd("SUPER SHIFT", "comma", "Open settings", "exec", "noctalia msg settings-toggle")
bindd("SUPER CTRL", "L", "Lock screen", "exec", "noctalia msg session lock")
bindd("SUPER SHIFT", "Y", "Toggle wallpaper", "exec", "noctalia msg panel-toggle wallpaper")
bindd("SUPER", "X", "Open session menu", "exec", "noctalia msg panel-toggle session")
bindd("SUPER", "C", "Toggle control center", "exec", "noctalia msg panel-toggle control-center")
bindd("SUPER SHIFT", "C", "Edit config files", "exec", "config-menu")
bindd("SUPER CTRL", "R", "Screenshot region", "exec", "noctalia msg screenshot-region")
bindd("SUPER SHIFT", "T", "Dropdown Terminal", "exec", "sh -lc 'DropTerminal'")
bindd("SUPER ALT", "L", "Toggle Layouts", "exec", "hyprland-change-layout toggle")
bindd("SUPER ALT", "1", "Layout Dwindle", "exec", "hyprland-change-layout dwindle")
bindd("SUPER ALT", "2", "Layout Master", "exec", "hyprland-change-layout master")
bindd("SUPER ALT", "3", "Layout Scrolling", "exec", "hyprland-change-layout scrolling")
bindd("SUPER ALT", "4", "Layout Monocle", "exec", "hyprland-change-layout monocle")
bindd("SUPER", "left", "Focus left", "movefocus", "l")
bindd("SUPER", "right", "Focus right", "movefocus", "r")
bindd("SUPER", "up", "Focus up", "movefocus", "u")
bindd("SUPER", "down", "Focus down", "movefocus", "d")
bindd("SUPER", "l", "Focus left", "movefocus", "l")
bindd("SUPER", "h", "Focus right", "movefocus", "r")
bindd("SUPER", "J", "Cycle next", "exec", "hyprland-cycle-window next")
bindd("SUPER", "K", "Cycle previous", "exec", "hyprland-cycle-window prev")
bindd("", "XF86AudioRaiseVolume", "Volume up", "exec", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
bindd("", "XF86AudioLowerVolume", "Volume down", "exec", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
bindd("", "XF86AudioMute", "Toggle mute", "exec", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
bindd("", "XF86AudioMicMute", "Toggle mic mute", "exec", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
bindd("SUPER ALT", "left", "Swap Window Left", "swapwindow", "l")
bindd("SUPER ALT", "right", "Swap Window Right", "swapwindow", "r")
bindd("SUPER ALT", "up", "Swap Window Up", "swapwindow", "u")
bindd("SUPER ALT", "down", "Swap Window Down", "swapwindow", "d")
bindd("SUPER", "1", "Workspace 1", "workspace", "1")
bindd("SUPER", "2", "Workspace 2", "workspace", "2")
bindd("SUPER", "3", "Workspace 3", "workspace", "3")
bindd("SUPER", "4", "Workspace 4", "workspace", "4")
bindd("SUPER", "5", "Workspace 5", "workspace", "5")
bindd("SUPER", "6", "Workspace 6", "workspace", "6")
bindd("SUPER", "7", "Workspace 7", "workspace", "7")
bindd("SUPER", "8", "Workspace 8", "workspace", "8")
bindd("SUPER", "9", "Workspace 9", "workspace", "9")
bindd("SUPER", "0", "Workspace 10", "workspace", "10")
bindd("SUPER SHIFT", "1", "Move to workspace 1", "movetoworkspace", "1")
bindd("SUPER SHIFT", "2", "Move to workspace 2", "movetoworkspace", "2")
bindd("SUPER SHIFT", "3", "Move to workspace 3", "movetoworkspace", "3")
bindd("SUPER SHIFT", "4", "Move to workspace 4", "movetoworkspace", "4")
bindd("SUPER SHIFT", "5", "Move to workspace 5", "movetoworkspace", "5")
bindd("SUPER SHIFT", "6", "Move to workspace 6", "movetoworkspace", "6")
bindd("SUPER SHIFT", "7", "Move to workspace 7", "movetoworkspace", "7")
bindd("SUPER SHIFT", "8", "Move to workspace 8", "movetoworkspace", "8")
bindd("SUPER SHIFT", "9", "Move to workspace 9", "movetoworkspace", "9")
bindd("SUPER SHIFT", "0", "Move to workspace 10", "movetoworkspace", "10")
bindd("SUPER", "mouse_down", "Scroll next workspace", "workspace", "e+1")
bindd("SUPER", "mouse_up", "Scroll prev workspace", "workspace", "e-1")

bindm("SUPER", "mouse:272", "Move window", "movewindow")
bindm("SUPER", "mouse:273", "Resize window", "resizewindow")
