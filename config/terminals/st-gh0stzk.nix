{
  pkgs,
  lib,
  ...
}: let
  st-gh0stzk = pkgs.stdenv.mkDerivation rec {
    pname = "st-gh0stzk";
    version = "0.9.2-graphics";
    src = pkgs.fetchFromGitHub {
      owner = "gh0stzk";
      repo = "st-terminal";
      rev = "2cff9e2559932245ec7d13302a52212d4d823e54"; # pinned 2025-12-30
      sha256 = "02mqwp4x1kvqm9x07s1xfd124j7f0j0nvwjw15fswx7154ihhpwh";
    };

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.ncurses
    ];
    buildInputs = [
      pkgs.zlib
      pkgs.imlib2
      pkgs.harfbuzz
      pkgs.freetype
      pkgs.fontconfig
      pkgs.libx11
      pkgs.libxft
      pkgs.libxrender
      pkgs.libxinerama
    ];

    # Make the default font match your setup (Maple Mono NF is already used elsewhere in this repo)
    postPatch = ''
      substituteInPlace config.def.h \
        --replace 'JetBrainsMono Nerd Font:pixelsize=13:antialias=true:autohint=true' \
                  'Maple Mono NF:size=12:antialias=true:autohint=true';
    '';

    # The upstream Makefile installs terminfo globally via `tic`. We install into $out
    # and place desktop/man under $out as well, so the package is self-contained.
    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/share/applications" "$out/share/man/man1" "$out/share/terminfo"
      install -m 0755 st "$out/bin/st"
      sed "s/VERSION/${version}/g" < st.1 > "$out/share/man/man1/st.1"
      install -m 0644 st.desktop "$out/share/applications/st.desktop"
      # Compile terminfo into the output tree
      ${pkgs.ncurses}/bin/tic -sx -o "$out/share/terminfo" st.info
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "gh0stzk's patched st (st-graphics) with Kitty graphics protocol and other patches";
      homepage = "https://github.com/gh0stzk/st-terminal";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = [];
    };
  };
in {
  # Install the terminal for the user/session. You can move this to system packages if preferred.
  home.packages = [
    st-gh0stzk
    # Optional: alternate launcher name to avoid collisions
    (pkgs.writeShellScriptBin "st-gh0stzk" ''
      exec st "$@"
    '')
  ];

  # Ensure a .desktop file exists in ~/.local/share/applications so rofi (drun) sees it.
  xdg.desktopEntries.st-gh0stzk = {
    name = "st (gh0stzk)";
    genericName = "Terminal";
    comment = "Simple Terminal (suckless) — gh0stzk build";
    exec = "st";
    icon = "utilities-terminal";
    terminal = false;
    categories = ["System" "TerminalEmulator"];
    # Extra keys not modeled by HM go under `settings`
    settings = {
      TryExec = "st";
      Keywords = "terminal;st;suckless;shell;cli;";
      StartupWMClass = "st-256color";
    };
  };
}
