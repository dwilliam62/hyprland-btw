-- Auto-generated from config/hypr/WindowRules.conf for permanent Lua runtime.
-- Edit this file directly for Lua-native window rule changes.

local function apply_window_rule(rule)
  if hl.window_rule then
    hl.window_rule(rule)
  end
end

apply_window_rule({
  name = "rofi-keybinds",
  match = {
    class = "^rofi$",
    title = "^Keybinds$",
  },
  float = true,
  size = "60% 60%",
  center = true,
})

apply_window_rule({
  name = "legacy-float-modal",
  match = {
    modal = 1,
  },
  float = true,
})

apply_window_rule({
  name = "legacy-center-modal",
  match = {
    modal = 1,
  },
  center = true,
})

apply_window_rule({
  name = "xwayland",
  match = {
    xwayland = 1,
  },
  no_blur = true,
})

apply_window_rule({
  name = "Resolve",
  match = {
    class = "^(\\bresolve\\b)$",
    xwayland = 1,
  },
  no_blur = true,
})

apply_window_rule({
  name = "foot-floating",
  match = {
    class = "^(foot-floating)$",
  },
  center = true,
  float = true,
  size = "60% 60%",
  no_blur = false,
})

apply_window_rule({
  name = "emacs-floating",
  match = {
    initial_title = "^(emacs-floating)$",
  },
  center = true,
  float = true,
  size = "70% 70%",
})

apply_window_rule({
  name = "boxbuddy",
  match = {
    title = "^(BoxBuddy)$",
  },
  center = true,
  float = true,
  size = "70% 70%",
})

apply_window_rule({
  name = "gearlever",
  match = {
    title = "^(it.mijorus.gearlever)$",
  },
  center = true,
  float = true,
})

apply_window_rule({
  name = "Bazaar",
  match = {
    class = "^(io.github.kolunmi.Bazaar)$",
  },
  center = true,
  float = true,
  size = "70% 70%",
})

apply_window_rule({
  name = "mpv",
  match = {
    class = "mpv",
  },
  content = "none",
})

apply_window_rule({
  name = "Thunar",
  match = {
    class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$",
  },
  tag = "+file-manager",
})

apply_window_rule({
  name = "Terminals",
  match = {
    class = "^(com.mitchellh.ghostty|org.wezfurlong.wezterm|Alacritty|kitty|kitty-dropterm)$",
  },
  tag = "+terminal",
})

apply_window_rule({
  name = "kitty-dropterm",
  match = {
    class = "^(kitty-dropterm)$",
  },
  float = true,
})

apply_window_rule({
  name = "Brave-browser",
  match = {
    class = "^(Brave-browser(-beta|-dev|-unstable)?)$",
  },
  tag = "+browser",
})

apply_window_rule({
  name = "Firefox",
  match = {
    class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$",
  },
  tag = "+browser",
})

apply_window_rule({
  name = "Google-chrome",
  match = {
    class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$",
  },
  tag = "+browser",
})

apply_window_rule({
  name = "Thorium-browser",
  match = {
    class = "^([Tt]horium-browser|[Cc]achy-browser)$",
  },
  tag = "+browser",
})

apply_window_rule({
  name = "VideoLan",
  match = {
    class = "^(vlc|mpv)$",
  },
  tag = "+video",
})

apply_window_rule({
  name = "vscodium",
  match = {
    class = "^(codium|codium-url-handler|VSCodium)$",
  },
  tag = "+projects",
})

apply_window_rule({
  name = "vscode",
  match = {
    class = "^(VSCode|code-url-handler)$",
  },
  tag = "+projects",
})

apply_window_rule({
  name = "Discord",
  match = {
    class = "^([Dd]iscord|[Dd]iscordcanary|[Ww]ebCord|[Vv]esktop)$",
  },
  tag = "+im",
})

apply_window_rule({
  name = "Ferdium",
  match = {
    class = "^([Ff]erdium)$",
  },
  center = true,
  float = true,
  size = "60% 70%",
  tag = "+im",
})

apply_window_rule({
  name = "Whatsapp",
  match = {
    class = "^([Ww]hatsapp-for-linux)$",
  },
  tag = "+im",
})

apply_window_rule({
  name = "Telegram-desktop",
  match = {
    class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$",
  },
  tag = "+im",
})

apply_window_rule({
  name = "teams-for-linux",
  match = {
    class = "^(teams-for-linux)$",
  },
  tag = "+im",
})

apply_window_rule({
  name = "obs-studio",
  match = {
    class = "^(com.obsproject.Studio)$",
  },
  tag = "+obs",
})

apply_window_rule({
  name = "gamescope",
  match = {
    class = "^(gamescope)$",
  },
  tag = "+games",
})

apply_window_rule({
  name = "steam-app",
  match = {
    class = "^(steam_app\\\\d+)$",
  },
  tag = "+games",
})

apply_window_rule({
  name = "Steam",
  match = {
    class = "^([Ss]team)$",
  },
  tag = "+gamestore",
})

apply_window_rule({
  name = "Lutris",
  match = {
    title = "^([Ll]utris)$",
  },
  tag = "+gamestore",
})

apply_window_rule({
  name = "heroicgameslauncher",
  match = {
    class = "^(com.heroicgameslauncher.hgl)$",
  },
  tag = "+gamestore",
})

apply_window_rule({
  name = "gnome-disks",
  match = {
    class = "^(gnome-disks|wihotspot(-gui)?)$",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "rofi",
  match = {
    class = "^([Rr]ofi)$",
  },
  tag = "+settings",
  no_blur = false,
})

apply_window_rule({
  name = "FileRoller",
  match = {
    class = "^(file-roller|org.gnome.FileRoller)$",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "NetworkManger",
  match = {
    class = "^(nm-applet|nm-connection-editor|blueman-manager)$",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "Pulse Audio",
  match = {
    class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
  },
  center = true,
  tag = "+settings",
  no_blur = false,
})

apply_window_rule({
  name = "nwg-look",
  match = {
    class = "^(nwg-look|qt5ct|qt6ct|[Yy]ad)$",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "xdg-desktop-portal-gtk",
  match = {
    class = "(xdg-desktop-portal-gtk)",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "blueman",
  match = {
    class = "(.blueman-manager-wrapped)",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "nwg-displays",
  match = {
    class = "(nwg-displays)",
  },
  tag = "+settings",
})

apply_window_rule({
  name = "Picture-in-Picture",
  match = {
    title = "^(Picture-in-Picture)$",
  },
  float = true,
  move = "72% 7%",
  opacity = "0.95 0.75",
  pin = false,
})

apply_window_rule({
  name = "ThunarFileMgr",
  match = {
    class = "([Tt]hunar)",
    title = "negative:(.*[Tt]hunar.*)",
  },
  center = true,
  float = true,
})

apply_window_rule({
  name = "Authentication-Required",
  match = {
    title = "^(Authentication Required)$",
  },
  center = true,
  float = true,
})

apply_window_rule({
  name = "IdleInhibit-fullscreen-1",
  match = {
    class = ".*",
  },
  idle_inhibit = "fullscreen",
})

apply_window_rule({
  name = "IdleInhibit-fullscreen-2",
  match = {
    title = ".*",
  },
  idle_inhibit = "fullscreen",
})

apply_window_rule({
  name = "IdleInhibit-fullscreen-3",
  match = {
    fullscreen = 1,
  },
  idle_inhibit = "fullscreen",
})

apply_window_rule({
  name = "Settings-Tag",
  match = {
    tag = "settings*",
  },
  float = true,
  opacity = "0.8 0.7",
  size = "70% 70%",
  no_blur = false,
})

apply_window_rule({
  name = "WayPaper",
  match = {
    class = "^([Ww]aypaper)$",
  },
  float = true,
  no_blur = false,
})

apply_window_rule({
  name = "Remmina",
  match = {
    class = "^(org.remmina.Remmina)$",
  },
  float = true,
})

apply_window_rule({
  name = "QS-Wallpapers",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Wallpapers)$",
  },
  border_size = 0,
  float = true,
  no_blur = true,
  rounding = 12,
})

apply_window_rule({
  name = "QA-Video-Wallpapers",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Video Wallpapers)$",
  },
  border_size = 0,
  center = true,
  float = true,
  no_blur = true,
  rounding = 12,
})

apply_window_rule({
  name = "QS-wlogout",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(qs-wlogout)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "1.0 1.0",
  rounding = 20,
})

apply_window_rule({
  name = "QA-Panels",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Panels)$",
  },
  center = true,
  float = true,
  no_blur = true,
  rounding = 12,
})

apply_window_rule({
  name = "QS-Hyprland-Keybinds",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Hyprland Keybinds)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-Niri-Keybinds",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Niri Keybinds)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-i3-Keybinds",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(i3 Keybinds)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-DWM-Keybinds",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(DWM Keybinds)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "EMACs-Leader",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Emacs Leader Keybinds)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-Kitty-Config",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Kitty Configuration)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-Wezterm-Config",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(WezTerm Configuration)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-Yazi-Config",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Yazi Configuration)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.85",
  rounding = 12,
})

apply_window_rule({
  name = "QS-Cheatsheets",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Cheatsheets Viewer)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "QS-Documentation-Viewer",
  match = {
    class = "^(org\\\\.qt-project\\\\.qml)$",
    title = "^(Documentation Viewer)$",
  },
  border_size = 0,
  center = true,
  float = true,
  opacity = "0.95 0.95",
  rounding = 12,
})

apply_window_rule({
  name = "Clapper",
  match = {
    class = "^(com.github.rafostar.Clapper)$",
  },
  float = true,
})

apply_window_rule({
  name = "netpeek",
  match = {
    class = "^(io.github.zingytomato.netpeek)$",
  },
  center = true,
  float = true,
})

apply_window_rule({
  name = "codium-url-handler",
  match = {
    class = "(codium|codium-url-handler|VSCodium)",
    title = "negative:(.*codium.*|.*VSCodium.*)",
  },
  float = true,
})

apply_window_rule({
  name = "heroicgameslauncher-1",
  match = {
    class = "^(com.heroicgameslauncher.hgl)$",
    title = "negative:(Heroic Games Launcher)",
  },
  float = true,
})

apply_window_rule({
  name = "Steam",
  match = {
    class = "^([Ss]team)$",
    title = "negative:^([Ss]team)$",
  },
  float = true,
})

apply_window_rule({
  name = "Add-Folder",
  match = {
    initial_title = "(Add Folder to Workspace)",
  },
  float = true,
  size = "70% 60%",
})

apply_window_rule({
  name = "Open-File",
  match = {
    initial_title = "(Open Files)",
  },
  float = true,
  size = "70% 60%",
})

apply_window_rule({
  name = "Wants-to-Save",
  match = {
    initial_title = "(wants to save)",
  },
  float = true,
})

apply_window_rule({
  name = "Browsers",
  match = {
    tag = "browser*",
  },
  opacity = "1.0 1.0",
  workspace = 2,
})

apply_window_rule({
  name = "Video",
  match = {
    tag = "video*",
  },
  opacity = "1.0 1.0",
})

apply_window_rule({
  name = "Projects",
  match = {
    tag = "projects*",
  },
  opacity = "0.9 0.8",
})

apply_window_rule({
  name = "Instant-Messaging",
  match = {
    tag = "im*",
  },
  opacity = "0.94 0.86",
  workspace = 3,
})

apply_window_rule({
  name = "File-Managers",
  match = {
    tag = "file-manager*",
  },
  opacity = "0.9 0.8",
})

apply_window_rule({
  name = "Terminals-opacity",
  match = {
    tag = "terminal*",
  },
  opacity = "0.94 0.7",
  no_blur = false,
})

apply_window_rule({
  name = "Misc editors",
  match = {
    class = "^(gedit|org.gnome.TextEditor|mousepad)$",
  },
  opacity = "0.8 0.7",
})

apply_window_rule({
  name = "seahorse",
  match = {
    class = "^(seahorse)$",
  },
  opacity = "0.9 0.8",
})

apply_window_rule({
  name = "games",
  match = {
    tag = "games*",
  },
  no_blur = true,
})

apply_window_rule({
  name = "Reminna",
  match = {
    class = "org.remmina.Reminna",
  },
  workspace = 8,
})

apply_window_rule({
  name = "obs",
  match = {
    tag = "obs*",
  },
  workspace = 10,
})

