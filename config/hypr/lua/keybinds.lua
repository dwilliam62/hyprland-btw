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

local function parse_resize_delta(value)
	local x, y = trim(value):match("^([%-]?%d+)%s+([%-]?%d+)$")
	return tonumber(x), tonumber(y)
end

local function window_size(window)
	if not window or not window.size then
		return nil, nil
	end
	local width = tonumber(window.size.x or window.size[1])
	local height = tonumber(window.size.y or window.size[2])
	return width, height
end

-- Hyprland 0.56 dropped the legacy `resizeactive` dispatcher, and the Lua
-- replacement has no delta form (`exact = false` is ignored): the value passed
-- to hl.dsp.window.resize() is read as a *delta* against the current size.
--
-- For a tiled window that delta is applied to the split ratio, and when the
-- window is the second child of a split the ratio is anchored on its sibling,
-- so the delta is applied with the opposite sign:
--     new = 2 * current - requested
-- which makes SUPER SHIFT + up grow the window instead of shrinking it. The
-- direction is therefore measured after the first dispatch and, when it is
-- wrong, the request is mirrored to land exactly on the target.
local function resize_active_by(dx, dy)
	if not hl.dsp or not hl.dsp.window or not hl.dsp.window.resize then
		return
	end
	local start_w, start_h = window_size(hl.get_active_window and hl.get_active_window())
	if not start_w or not start_h then
		return
	end

	local target_w = math.max(1, start_w + dx)
	local target_h = math.max(1, start_h + dy)
	hl.dispatch(hl.dsp.window.resize({x = target_w, y = target_h, exact = true}))

	local now_w, now_h = window_size(hl.get_active_window and hl.get_active_window())
	if not now_w or not now_h then
		return
	end

	-- A zero delta or an unchanged size (for example a vertical resize with no
	-- vertical split) is not something a correction can fix.
	local wrong_x = dx ~= 0 and now_w ~= start_w and ((now_w > start_w) ~= (dx > 0))
	local wrong_y = dy ~= 0 and now_h ~= start_h and ((now_h > start_h) ~= (dy > 0))
	if not (wrong_x or wrong_y) then
		return
	end

	local fix_w = wrong_x and (2 * now_w - target_w) or target_w
	local fix_h = wrong_y and (2 * now_h - target_h) or target_h
	hl.dispatch(hl.dsp.window.resize({
		x = math.max(1, fix_w),
		y = math.max(1, fix_h),
		exact = true,
	}))
end

local function dispatch(name, args)
	name = trim(name)
	args = trim(args)

	if name == "killactive" and hl.dsp and hl.dsp.window and hl.dsp.window.close then
		return function()
			hl.dispatch(hl.dsp.window.close())
		end
	end

	-- Logout: use session-logout so it reliably terminates the compositor
	-- and returns to the greetd/Noctalia greeter.
	if name == "exit" then
		return exec_cmd("session-logout")
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

	if name == "workspace" and hl.dsp and hl.dsp.focus then
		-- Relative selectors such as "e+1" / "e-1" (SUPER + mouse wheel) are
		-- passed through as strings; Hyprland resolves them like the legacy
		-- dispatcher did.
		local target = tonumber(args) or args
		if target == "" then
			return function() end
		end
		return function()
			hl.dispatch(hl.dsp.focus({ workspace = target }))
		end
	end

	if name == "movetoworkspace" and hl.dsp and hl.dsp.window and hl.dsp.window.move then
		local target = tonumber(args) or args
		if target == "" then
			return function() end
		end
		return function()
			hl.dispatch(hl.dsp.window.move({ workspace = target }))
		end
	end

	-- Hyprland 0.56 evaluates the argument of `hyprctl dispatch` as Lua, so the
	-- legacy bare-word form ("hyprctl dispatch resizeactive -40 0") is rejected
	-- and the bind silently does nothing.
	if (name == "resizeactive" or name == "resizewindow")
		and hl.dsp and hl.dsp.window and hl.dsp.window.resize
	then
		local dx, dy = parse_resize_delta(args)
		if dx and dy then
			return function()
				resize_active_by(dx, dy)
			end
		end
		return function()
			hl.dispatch(hl.dsp.window.resize())
		end
	end

	-- Anything still unmapped has no native equivalent: every legacy dispatcher
	-- name was removed in 0.56 and hl.dsp.exec_raw is an exec helper, not a
	-- dispatcher passthrough. Report it instead of failing silently.
	local raw = name
	if args ~= "" then
		raw = raw .. " " .. args
	end
	print("[keybinds] unmapped dispatcher: " .. raw .. " (add a hl.dsp.* mapping)")
	return function() end
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
	else
		action = dispatch(dispatcher, "")
	end
	hl.bind(chord(mods, key), action, { description = description, mouse = true })
end

bindd("SUPER", "Return", "Launch Terminal", "exec", "ghostty")
bindd("SUPER SHIFT", "Return", "Launch Kitty", "exec", "kitty-bg")
bindd("SUPER", "Q", "Close Active Window", "killactive", "")
bindd("SUPER SHIFT", "Q", "Exit Hyprland", "exec", "session-logout")
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
bindd("SUPER", "D", "Toggle launcher", "exec", "noctalia-msg panel-toggle launcher")
bindd("SUPER", "M", "Toggle notifications", "exec", "noctalia-msg panel-toggle control-center notifications")
bindd("SUPER", "V", "Open clipboard", "exec", "noctalia-msg panel-toggle clipboard")
bindd("SUPER SHIFT", "comma", "Open settings", "exec", "noctalia-msg settings-toggle")
bindd("SUPER CTRL", "L", "Lock screen", "exec", "noctalia-msg session lock")
bindd("SUPER SHIFT", "Y", "Toggle wallpaper", "exec", "noctalia-msg panel-toggle wallpaper")
bindd("SUPER", "X", "Open session menu", "exec", "noctalia-msg panel-toggle session")
bindd("SUPER", "C", "Toggle control center", "exec", "noctalia-msg panel-toggle control-center")
bindd("SUPER SHIFT", "C", "Edit config files", "exec", "config-menu")
bindd("SUPER CTRL", "R", "Screenshot region", "exec", "noctalia-msg screenshot-region")
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

-- Resize active window with mainMod SHIFT + arrow keys
bindd("SUPER SHIFT", "left", "Resize Window Left", "resizeactive", "-40 0")
bindd("SUPER SHIFT", "right", "Resize Window Right", "resizeactive", "40 0")
bindd("SUPER SHIFT", "up", "Resize Window Up", "resizeactive", "0 -40")
bindd("SUPER SHIFT", "down", "Resize Window Down", "resizeactive", "0 40")
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
