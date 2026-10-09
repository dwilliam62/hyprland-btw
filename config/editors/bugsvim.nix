{
  config,
  pkgs,
  lib,
  ...
}: let
  # Reference the local bugsvim config directory in this repo
  bugsvimSrc = ./bugsvim-nvim;
in {
  # Disable HM's Neovim module so it doesn't generate ~/.config/nvim/*
  programs.neovim = lib.mkForce {
    enable = false;
  };

  # Install Neovim + required tools via packages so lazy.nvim can manage config
  home.packages = with pkgs; [
    neovim
    # Language Servers
    lua-language-server
    pyright
    typescript-language-server
    tailwindcss-language-server
    clang-tools
    bash-language-server
    rust-analyzer
    vscode-langservers-extracted # html, css, json, eslint
    nil # Nix LSP
    hyprls

    # Formatters
    stylua
    ruff
    prettierd
    prettier
    clang-tools # includes clang-format
    shfmt
    alejandra
    jq # json/jsonc formatter fallback

    # Linters
    ruff
    eslint_d
    luajitPackages.luacheck
    cpplint
    clippy # rust linter

    # Additional tools
    ripgrep
    fd
    tree-sitter # tree-sitter CLI for parser compilation
    git
    curl
    gnumake # provides make/gmake used by LuaSnip build
    pkg-config
    luarocks
    lazygit # Snacks.lazygit
    bat
    wl-clipboard
    (python3.withPackages (ps: [ps.pynvim])) # python provider

    # Docs / preview toolchain
    # Snacks.image shells out to tectonic (or pdflatex) for LaTeX math in
    # markdown previews. mermaid-cli (mmdc) is intentionally omitted upstream
    # too when the toolchain is skipped; add pkgs.mermaid-cli if Mermaid
    # diagram rendering is wanted (it bundles a full browser).
    tectonic
  ];

  # Optional: Ensure directories and undo setup on first activation
  # Also copy bugsvim config as real files so lazy.nvim can update plugins.
  home.activation = {
    bugsvimSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create undo directory if it doesn't exist
      UNDO_DIR="$HOME/.local/share/nvim/undodir"
      if [ ! -d "$UNDO_DIR" ]; then
        $DRY_RUN_CMD mkdir -p "$UNDO_DIR"
        echo "Created NeoVim undo directory at $UNDO_DIR"
      fi

      # org.nvim notes directory. Mirrors the upstream ensure_org_directory step:
      # the plugin spec points org_directory/agenda_files/default_notes_file at
      # ~/org and ~/org/refile.org (lowercase on purpose - ~/Org is a different
      # directory on case-sensitive filesystems).
      ORG_DIR="$HOME/org"
      if [ ! -d "$ORG_DIR" ]; then
        $DRY_RUN_CMD mkdir -p "$ORG_DIR"
        echo "Created org notes directory at $ORG_DIR"
      fi
      if [ ! -f "$ORG_DIR/refile.org" ]; then
        $DRY_RUN_CMD touch "$ORG_DIR/refile.org"
        echo "Created default org notes file at $ORG_DIR/refile.org"
      fi

      # Copy bugsvim config into ~/.config/nvim (writable) so lazy.nvim can manage updates
      SRC=${bugsvimSrc}
      DEST="$HOME/.config/nvim"
      # Ensure existing files are writable so rm succeeds
      $DRY_RUN_CMD chmod -R u+w "$DEST" 2>/dev/null || true
      $DRY_RUN_CMD rm -rf "$DEST"
      $DRY_RUN_CMD mkdir -p "$DEST"
      $DRY_RUN_CMD cp -r "$SRC"/. "$DEST"/
      # Ensure config files are writable so Home Manager can replace them on rebuild
      $DRY_RUN_CMD chmod -R u+w "$DEST"

      # Lazy.nvim will self-bootstrap on first nvim run
      # The init.lua handles automatic cloning if lazy.nvim is not present
    '';
  };
}
