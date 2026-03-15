{
  config,
  pkgs,
  lib,
  ...
}: let
  # Reference the local bugsvim config directory in this repo
  bugsvimSrc = ./bugsvim-nvim;
in {
  programs.neovim = lib.mkForce {
    enable = true;
    defaultEditor = false;
    vimAlias = false;
    viAlias = false;
    withNodeJs = true;
    withPython3 = true;

    # Install all required tools and language servers
    extraPackages = with pkgs; [
      # Language Servers
      lua-language-server
      pyright
      nodePackages.typescript-language-server
      tailwindcss-language-server
      clang-tools
      nodePackages.bash-language-server
      rust-analyzer
      nodePackages.vscode-langservers-extracted # html, css, json, eslint
      nil # Nix LSP
      hyprls

      # Formatters
      stylua
      ruff
      prettierd
      clang-tools # includes clang-format
      shfmt
      alejandra

      # Linters
      ruff
      nodePackages.eslint_d
      luajitPackages.luacheck
      cpplint

      # Additional tools
      ripgrep
      fd
      tree-sitter
      git
      gnumake
    ];
  };

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

      # Copy bugsvim config into ~/.config/nvim (writable) so lazy.nvim can manage updates
      SRC=${bugsvimSrc}
      DEST="$HOME/.config/nvim"
      $DRY_RUN_CMD rm -rf "$DEST"
      $DRY_RUN_CMD mkdir -p "$DEST"
      $DRY_RUN_CMD cp -r "$SRC"/. "$DEST"/

      # Lazy.nvim will self-bootstrap on first nvim run
      # The init.lua handles automatic cloning if lazy.nvim is not present
    '';
  };
}
