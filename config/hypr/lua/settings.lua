hl.config({
	dwindle = {
		preserve_split = true,
		force_split = 2,
	},
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	general = {
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},
})

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0,
		repeat_rate = 35,
		repeat_delay = 200,
		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.config({
	cursor = {
		inactive_timeout = 20,
		no_hardware_cursors = true,
	},
})

hl.config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = true,
	},
})

hl.config({
	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
	},
})

-- Advertise the renderer's full dmabuf format list, not just the formats the
-- display can scan out. Hyprland's default (true) narrows the list to the
-- display's scanout set; on virtio-gpu that is XRGB8888 only, so clients that
-- need an alpha config find no matching EGLConfig. kitty and alacritty (GLFW
-- asks for EGL_ALPHA_SIZE 8) then fail with "EGL: No EGLConfigs returned".
hl.config({
	quirks = {
		skip_non_kms_dmabuf_formats = false,
	},
})
