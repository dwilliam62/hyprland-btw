{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.kitty = {
    enable = true;

    # 2025-09-30: Workaround for kitty 0.42.2 integration tests failing in Nix build sandbox.
    # The upstream kitty test suite runs shell integration tests (including fish)
    # that expect a real terminal to respond to a primary device attributes (DA1) query.
    # In the headless/sandboxed builder, fish prints a warning and the tests fail.
    # This is independent of the user's login shell or Home Manager fish settings.
    # To avoid blocking builds, disable both checkPhase and installCheckPhase.
    # Remove this override once upstream fixes the tests or when pinning a kitty
    # version that does not run these tests in the builder.
    package = pkgs.kitty.overrideAttrs (_old: {
      doCheck = false;
      checkPhase = "";
      doInstallCheck = false;
      installCheckPhase = "";
    });
    settings = {
      font_family = "Maple Mono NF";
      font_size = 12;
      wheel_scroll_min_lines = 1;
      window_padding_width = 4;
      confirm_os_window_close = 0;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      cursor_trail = 1;
      tab_fade = 1;
      active_tab_font_style = "bold";
      inactive_tab_font_style = "bold";
      tab_bar_edge = "top";
      tab_bar_margin_width = 0;
      tab_bar_style = "powerline";
      #tab_bar_style = "fade";
      enabled_layouts = "splits";
      open_url_with_default = true;
      detect_urls = true;
      allow_remote_control = false;
    };

    shellIntegration.enableZshIntegration = true;
    shellIntegration.enableFishIntegration = true;
    shellIntegration.enableBashIntegration = true;
    shellIntegration.mode = "enabled";

    extraConfig = ''

      #open_url_with default
      url_prefixes file ftp ftps gemini git gopher http https irc ircs kitty sftp ssh
      #detect_urls yes

        # Clipboard
        map ctrl+shift+v        paste_from_selection
        map shift+insert        paste_from_selection

        # Scrolling
        map ctrl+shift+up        scroll_line_up
        map ctrl+shift+down      scroll_line_down
        map ctrl+shift+k         scroll_line_up
        map ctrl+shift+j         scroll_line_down
        map ctrl+shift+page_up   scroll_page_up
        map ctrl+shift+page_down scroll_page_down
        map ctrl+shift+home      scroll_home
        map ctrl+shift+end       scroll_end
        map ctrl+shift+h         show_scrollback

        # Window management
        map alt+n               new_window_with_cwd
        #map alt+n              new_os_window
        map alt+w               close_window
        map ctrl+shift+enter    launch --location=hsplit
        map ctrl+shift+s        launch --location=vsplit
        map ctrl+shift+]        next_window
        map ctrl+shift+[        previous_window
        map ctrl+shift+f        move_window_forward
        map ctrl+shift+b        move_window_backward
        map ctrl+shift+`        move_window_to_top
        map ctrl+shift+1        first_window
        map ctrl+shift+2        second_window
        map ctrl+shift+3        third_window
        map ctrl+shift+4        fourth_window
        map ctrl+shift+5        fifth_window
        map ctrl+shift+6        sixth_window
        map ctrl+shift+7        seventh_window
        map ctrl+shift+8        eighth_window
        map ctrl+shift+9        ninth_window # Tab management
        map ctrl+shift+0        tenth_window
        map ctrl+shift+right    next_tab
        map ctrl+shift+left     previous_tab
        map ctrl+shift+t        new_tab
        map ctrl+shift+q        close_tab
        map ctrl+shift+l        next_layout
        map ctrl+shift+.        move_tab_forward
        map ctrl+shift+,        move_tab_backward

        # Miscellaneous
        map ctrl+shift+up      increase_font_size
        map ctrl+shift+down    decrease_font_size
        map ctrl+shift+backspace restore_font_size

        #Manually set color scheme to catpuccin-mocha
        #Disabled stylix support

        ## name:     Catppuccin Kitty Mocha
        ## author:   Catppuccin Org
        ## license:  MIT
        ## upstream: https://github.com/catppuccin/kitty/blob/main/themes/mocha.conf
        ## blurb:    Soothing pastel theme for the high-spirited!

        # The basic colors
        foreground              #cdd6f4
        background              #1e1e2e
        selection_foreground    #1e1e2e
        selection_background    #f5e0dc

        # Cursor colors
        cursor                  #f5e0dc
        cursor_text_color       #1e1e2e

        # URL underline color when hovering with mouse
        url_color               #f5e0dc

        # Kitty window border colors
        active_border_color     #b4befe
        inactive_border_color   #6c7086
        bell_border_color       #f9e2af

        # OS Window titlebar colors
        wayland_titlebar_color system
        macos_titlebar_color system

        # Tab bar colors
        active_tab_foreground   #11111b
        active_tab_background   #cba6f7
        inactive_tab_foreground #cdd6f4
        inactive_tab_background #181825
        tab_bar_background      #11111b

        # Colors for marks (marked text in the terminal)
        mark1_foreground #1e1e2e
        mark1_background #b4befe
        mark2_foreground #1e1e2e
        mark2_background #cba6f7
        mark3_foreground #1e1e2e
        mark3_background #74c7ec

        # The 16 terminal colors

        # black
        color0 #45475a
        color8 #585b70

        # red
        color1 #f38ba8
        color9 #f38ba8

        # green
        color2  #a6e3a1
        color10 #a6e3a1

        # yellow
        color3  #f9e2af
        color11 #f9e2af

        # blue
        color4  #89b4fa
        color12 #89b4fa

        # magenta
        color5  #f5c2e7
        color13 #f5c2e7

        # cyan
        color6  #94e2d5
        color14 #94e2d5

        # white
        color7  #bac2de
        color15 #a6adc8


    '';
  };

  # Background image is applied at launch time by the kitty-bg wrapper via --override flags; no extra config file is written.

  # Wrapper to select a random wallpaper, update the symlink, and launch kitty with kitty-bg.conf
  home.packages = [
    (pkgs.writeShellScriptBin "kitty-bg" ''
            #!/usr/bin/env bash
            set -euo pipefail

            # Defaults
            SOURCE_DIR="$HOME/Pictures/Wallpapers"
            LINK_PATH="$HOME/Pictures/current_image"
            LAUNCH=1
            FOREGROUND=0

            # Parse basic options (stop at first positional or --)
            while [[ $# -gt 0 ]]; do
              case "$1" in
                -s|--source)
                  [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
                  SOURCE_DIR="$2"; shift 2;;
                -l|--link)
                  [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
                  LINK_PATH="$2"; shift 2;;
                --no-launch)
                  LAUNCH=0; shift;;
                --foreground)
                  FOREGROUND=1; shift;;
                -h|--help)
                  cat <<'EOF'
      Usage: kitty-bg [options] [--] [kitty_args...]

      Defaults: Launches kitty in the background with ~/.config/kitty/kitty-bg.conf

      Options:
        -s, --source DIR   Source directory of images (default: ~/Pictures/Wallpapers)
        -l, --link PATH    Symlink path (default: ~/Pictures/current_image)
            --no-launch    Only update symlink; do not launch kitty
            --foreground   Run kitty in the foreground (default is background)
        -h, --help         Show this help
      EOF
                  exit 0;;
                --)
                  shift; break;;
                -*)
                  echo "Unknown option: $1" >&2; exit 2;;
                *)
                  break;;
              esac
            done

            # Validate source dir and choose a random image (no Bash arrays to avoid Nix string issues)
            if [[ ! -d "$SOURCE_DIR" ]]; then
              echo "Source directory not found: $SOURCE_DIR" >&2
              exit 1
            fi

            CHOSEN="$(${pkgs.findutils}/bin/find -L "$SOURCE_DIR" -type f \
              \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \) \
              -print0 | ${pkgs.coreutils}/bin/shuf -z -n 1 | ${pkgs.coreutils}/bin/tr -d '\0')"
            if [[ -z "$CHOSEN" ]]; then
              echo "No images found in: $SOURCE_DIR" >&2
              exit 1
            fi

            # Update symlink
            mkdir -p "$(dirname "$LINK_PATH")"
            ln -sfn "$CHOSEN" "$LINK_PATH"

            # Build overrides for background image settings
            OVERRIDES=(
              --override "background_image=$LINK_PATH"
              --override "background_image_layout=scaled"
              --override "background_tint=0.95"
              --override "background_opacity=1.0"
            )

            # Launch kitty (background by default) with background image overrides
            if (( LAUNCH )); then
              if (( FOREGROUND )); then
                exec kitty "''${OVERRIDES[@]}" "$@"
              else
                setsid -f kitty "''${OVERRIDES[@]}" "$@" >/dev/null 2>&1 < /dev/null &
              fi
            fi
    '')
  ];

  # Desktop file for kitty-bg so it shows up in application launchers
  xdg.desktopEntries.kitty-bg = {
    name = "Kitty with Random Wallpaper";
    comment = "Launch Kitty terminal with a random wallpaper";
    exec = "kitty-bg";
    icon = "utilities-terminal";
    terminal = false;
    categories = ["System" "Utility" "TerminalEmulator"];
  };
}
