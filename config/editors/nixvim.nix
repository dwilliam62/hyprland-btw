{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  # Bring in Nixvim's Home Manager module so programs.nixvim options exist
  imports = [inputs.nixvim.homeModules.nixvim];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    # Core editor options
    opts = {
      number = true;
      relativenumber = false;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;
      swapfile = false;
      termguicolors = true;
      signcolumn = "yes";
      updatetime = 200;
      cursorline = true;
      spell = true;
      spelllang = ["en"];
      clipboard = "unnamedplus";
    };

    # Theme: Tokyo Night
    colorschemes.tokyonight.enable = true;

    plugins = {
      # UI and visuals
      web-devicons.enable = true;
      lualine = {
        enable = true;
        settings = {
          options = {theme = "tokyonight";};
        };
      };
      bufferline.enable = true;
      indent-blankline.enable = true;
      colorizer.enable = true;
      illuminate.enable = true;

      # File tree (Neo-tree to match NVF)
      neo-tree = {
        enable = true;
      };

      # Fuzzy finder
      telescope = {
        enable = true;
        settings.extensions = {
          media_files = {
            filetypes = ["png" "webp" "jpg" "jpeg"];
            find_cmd = "find";
          };
        };
      };

      # Treesitter for syntax/TS features
      treesitter.enable = true;
      treesitter-context.enable = false;

      # Project management
      project-nvim.enable = true;

      # Notifications and UI polish
      notify.enable = true;
      noice = {
        enable = true;
        settings = {
          lsp = {
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
          };
          presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
            inc_rename = false;
            lsp_doc_border = false;
          };
        };
      };

      # snacks.nvim - QoL improvements and pickers
      snacks = {
        enable = true;
        settings = {
          bigfile = {enabled = true;};
          dashboard = {
            enabled = true;
            preset = {
              header = ''
                ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗
                ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║
                ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║
                ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║
                ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║
                ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
              '';
            };
          };
          explorer = {enabled = true;};
          indent = {enabled = true;};
          image = {enabled = true;};
          input = {enabled = true;};
          notifier = {
            enabled = true;
            timeout = 3000;
          };
          picker = {enabled = true;};
          quickfile = {enabled = true;};
          scope = {enabled = true;};
          scroll = {enabled = true;};
          statuscolumn = {enabled = true;};
          words = {enabled = true;};
          styles = {
            notification = {
              wo = {wrap = true;};
            };
          };
        };
      };

      # Startup dashboard
      alpha = {
        enable = true;
        theme = "dashboard"; # required by nixvim: either set a theme or a custom layout
      };

      # Git integrations
      gitsigns.enable = true;
      diffview.enable = true;

      # Motions and editing helpers
      hop.enable = true;
      leap.enable = true;
      vim-surround.enable = true;
      comment.enable = true;

      # mini.nvim - Collection of independent Lua modules for editing
      mini = {
        enable = true;
        mockDevIcons = true;
        modules = {
          ai = {};
          comment = {};
          move = {};
          surround = {};
          cursorword = {};
          pairs = {};
          trailspace = {};
          icons = {};
        };
      };

      # TODO/HACK/BUG comment highlighting and navigation
      todo-comments = {
        enable = true;
      };

      # Keybinding hints and display
      which-key = {
        enable = true;
        settings = {
          preset = "helix";
        };
      };

      # Autopairs for (), {}, [], '', "", etc.
      nvim-autopairs = {
        enable = true;
        settings = {
          check_ts = true; # leverage Treesitter for smarter pairing
          enable_check_bracket_line = false;
          fast_wrap = {
            enable = true;
            map = "<M-e>"; # Alt+e to fast-wrap
            chars = ["{" "[" "(" "\"" "'" "`"];
          };
        };
      };

      # Terminal
      toggleterm = {
        enable = true;
        settings = {direction = "float";};
      };

      # Diagnostics UI
      trouble.enable = true;

      # Markdown preview
      markdown-preview.enable = true;

      # Completion and snippets
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            preset = "default";
            "<CR>" = ["accept" "fallback"];
            "<Tab>" = ["select_next" "fallback"];
            "<S-Tab>" = ["select_prev" "fallback"];
          };
          appearance = {
            nerd_font_variant = "mono";
          };
          completion = {
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 500;
            };
          };
          sources = {
            default = ["lsp" "path" "snippets" "buffer"];
          };
          snippets = {
            preset = "luasnip";
          };
          fuzzy = {
            implementation = "prefer_rust_with_warning";
          };
          signature = {
            enabled = true;
          };
        };
      };

      luasnip.enable = true;
      friendly-snippets.enable = true;

      # Disable lazy.nvim update/change notifications (Nix-managed plugins)
      lazy = {
        enable = true;
        settings = {
          checker = {
            enabled = false;
            notify = false;
          };
          change_detection = {
            enabled = false;
            notify = false;
          };
        };
      };

      # Signature help while typing function params
      lsp-signature.enable = true;

      # LSP configuration
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          lua_ls.enable = true;
          pyright.enable = true;
          ts_ls.enable = true;
          html.enable = true;
          cssls.enable = true;
          clangd.enable = true;
          zls.enable = true;
          marksman.enable = true;
          hyprls.enable = true;
          # hyprls is optional; keep tools available via extraPackages
          tailwindcss = {
            enable = true;
            filetypes = [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
              "vue"
              "svelte"
            ];
          };
          bashls.enable = true;
        };
        keymaps = {
          diagnostic = {
            "<leader>dl" = "open_float";
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };
        };
      };

      # Formatter: conform.nvim (Prettierd, Stylua, etc.)
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = ["alejandra"];
            #nix = [ "nixpkgs_fmt" ];
            lua = ["stylua"];
            javascript = ["prettierd"];
            typescript = ["prettierd"];
            javascriptreact = ["prettierd"];
            typescriptreact = ["prettierd"];
            css = ["prettierd"];
            html = ["prettierd"];
            markdown = ["prettierd"];
            sh = ["shfmt"];
          };
          format_on_save = {
            lsp_fallback = true;
          };
        };
      };
    };

    # Keymaps aligned with your NVF setup
    keymaps = [
      # Insert-mode escape
      {
        key = "jk";
        mode = ["i"];
        action = "<ESC>";
        options.desc = "Exit insert mode";
      }

      # Telescope
      {
        key = "<leader>ff";
        mode = ["n"];
        action = "<cmd>Telescope find_files<cr>";
        options.desc = "Search files by name";
      }
      {
        key = "<leader>fm";
        mode = ["n"];
        action = "<cmd>Telescope media_files<cr>";
        options.desc = "Search media files";
      }
      {
        key = "<leader>lg";
        mode = ["n"];
        action = "<cmd>Telescope live_grep<cr>";
        options.desc = "Search files by contents";
      }

      # File tree (Neo-tree)
      {
        key = "<leader>fe";
        mode = ["n"];
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "File browser toggle";
      }

      # Terminal
      {
        key = "<leader>t";
        mode = ["n"];
        action = "<cmd>ToggleTerm<CR>";
        options.desc = "Toggle terminal";
      }

      # Comment line (Doom Emacs style)
      {
        key = "<leader>.";
        mode = ["n"];
        action = "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>";
        options.desc = "Comment line";
      }
      {
        key = "<leader>.";
        mode = ["v"];
        action = "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>";
        options.desc = "Comment selection";
      }

      # Diagnostics
      {
        key = "<leader>dj";
        mode = ["n"];
        action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
        options.desc = "Go to next diagnostic";
      }
      {
        key = "<leader>dk";
        mode = ["n"];
        action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
        options.desc = "Go to previous diagnostic";
      }
      {
        key = "<leader>dl";
        mode = ["n"];
        action = "<cmd>lua vim.diagnostic.open_float()<CR>";
        options.desc = "Show diagnostic details";
      }
      {
        key = "<leader>dt";
        mode = ["n"];
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Toggle diagnostics list";
      }

      # Snacks: Terminal and scratch buffers
      {
        key = "<c-/>";
        mode = ["n"];
        action = "<cmd>lua Snacks.terminal()<CR>";
        options.desc = "Toggle terminal";
      }
      {
        key = "<leader>.";
        mode = ["n"];
        action = "<cmd>lua Snacks.scratch()<CR>";
        options.desc = "Toggle scratch buffer";
      }
      {
        key = "<leader>S";
        mode = ["n"];
        action = "<cmd>lua Snacks.scratch.select()<CR>";
        options.desc = "Select scratch buffer";
      }

      # Snacks: Zen and zoom modes
      {
        key = "<leader>z";
        mode = ["n"];
        action = "<cmd>lua Snacks.zen()<CR>";
        options.desc = "Toggle zen mode";
      }
      {
        key = "<leader>Z";
        mode = ["n"];
        action = "<cmd>lua Snacks.zen.zoom()<CR>";
        options.desc = "Toggle zoom";
      }

      # Snacks: Git
      {
        key = "<leader>gg";
        mode = ["n"];
        action = "<cmd>lua Snacks.lazygit()<CR>";
        options.desc = "Lazygit";
      }
      {
        key = "<leader>gB";
        mode = ["n" "v"];
        action = "<cmd>lua Snacks.gitbrowse()<CR>";
        options.desc = "Git browse";
      }

      # Snacks: Buffer and file operations
      {
        key = "<leader>bd";
        mode = ["n"];
        action = "<cmd>lua Snacks.bufdelete()<CR>";
        options.desc = "Delete buffer";
      }
      {
        key = "<leader>cR";
        mode = ["n"];
        action = "<cmd>lua Snacks.rename.rename_file()<CR>";
        options.desc = "Rename file";
      }

      # Snacks: Notifications
      {
        key = "<leader>n";
        mode = ["n"];
        action = "<cmd>lua Snacks.notifier.show_history()<CR>";
        options.desc = "Notification history";
      }
      {
        key = "<leader>un";
        mode = ["n"];
        action = "<cmd>lua Snacks.notifier.hide()<CR>";
        options.desc = "Dismiss all notifications";
      }

      # TODO comments navigation
      {
        key = "]t";
        mode = ["n"];
        action = "<cmd>lua require('todo-comments').jump_next()<CR>";
        options.desc = "Next todo comment";
      }
      {
        key = "[t";
        mode = ["n"];
        action = "<cmd>lua require('todo-comments').jump_prev()<CR>";
        options.desc = "Previous todo comment";
      }
      {
        key = "<leader>st";
        mode = ["n"];
        action = "<cmd>TodoTelescope<CR>";
        options.desc = "Search todo comments";
      }
      {
        key = "<leader>sT";
        mode = ["n"];
        action = "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<CR>";
        options.desc = "Search TODO/FIX/FIXME comments";
      }

      # Which-key buffer keymaps
      {
        key = "<leader>?";
        mode = ["n"];
        action = "<cmd>lua require('which-key').show({ global = false })<CR>";
        options.desc = "Buffer local keymaps (which-key)";
      }

      # Disable accidental F1 across modes
      {
        key = "<F1>";
        mode = ["n" "i" "v" "x" "s" "o" "t" "c"];
        action = "<Nop>";
        options.desc = "Disable accidental F1 help";
      }
      # Help mappings
      {
        key = "<leader>h";
        mode = ["n"];
        action = ":help<Space>";
        options = {
          desc = "Open :help prompt";
          nowait = true;
        };
      }
      {
        key = "<leader>H";
        mode = ["n"];
        action = ":help <C-r><C-w><CR>";
        options.desc = "Help for word under cursor";
      }
    ];

    # Runtime tools and language servers
    extraPackages = with pkgs; [
      bat
      chafa
      clang-tools
      fd
      figlet
      hyprls
      lazygit
      nil
      nixpkgs-fmt
      nodePackages.typescript-language-server
      nodePackages.typescript
      pyright
      lua-language-server
      marksman
      prettierd
      ripgrep
      stylua
      shfmt
      toilet
      wl-clipboard
      viu
      vscode-langservers-extracted
      zls
      tailwindcss-language-server
      nodePackages.bash-language-server
    ];

    extraPlugins = with pkgs.vimPlugins; [
      telescope-media-files-nvim
      nui-nvim # Required by snacks and noice
    ];

    # Diagnostic UI and notify background tweaks
    extraConfigLua = ''
      require('telescope').load_extension('media_files')

      -- Diagnostic configuration with enhanced icons and styling (from bugsvim)
      local diagnostic_signs = {
        Error = " ",
        Warn = " ",
        Hint = "",
        Info = "",
      }

      vim.diagnostic.config({
        -- Show signs in the gutter with custom icons
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
            [vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
            [vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
            [vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
          },
          linehl = false,
        },
        -- Show virtual text next to error (inline diagnostics)
        virtual_text = {
          prefix = "●",
          spacing = 2,
          severity = {
            min = vim.diagnostic.severity.HINT,
          },
        },
        -- Show diagnostics on separate lines for better visibility
        virtual_lines = {
          only_current_line = false,
          highlight_whole_line = false,
        },
        -- Underline errors
        underline = true,
        -- Show diagnostic in floating window on hover with source
        float = {
          source = "always",
          border = "rounded",
          pad_bottom = 1,
        },
        severity_sort = true,
        update_in_insert = false,
      })

      -- Highlight the yanked text for 200ms
      local highlight_yank_group = vim.api.nvim_create_augroup('HighlightYank', {})
      vim.api.nvim_create_autocmd('TextYankPost', {
        group = highlight_yank_group,
        pattern = '*',
        callback = function()
          vim.hl.on_yank {
            higroup = 'IncSearch',
            timeout = 200,
          }
        end,
      })

      -- Basic LSP keymaps when LSP attaches
      local function lsp_on_attach(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map('n', 'K', vim.lsp.buf.hover, 'Hover docs')
        map('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
        map('n', 'gD', vim.lsp.buf.declaration, 'Goto declaration')
        map('n', 'gi', vim.lsp.buf.implementation, 'Goto implementation')
        map('n', 'gr', vim.lsp.buf.references, 'References')
        map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
        map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
      end

      -- If nixvim exposes a hook, register it; otherwise set a global autocmd
      if vim.g.__nixvim_lsp_attached ~= true then
        vim.g.__nixvim_lsp_attached = true
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local bufnr = args.buf
            lsp_on_attach(nil, bufnr)
          end,
        })
      end

      -- Notify background using Stylix palette
      local ok, notify = pcall(require, 'notify')
      if ok then
        notify.setup({ background_colour = "#${config.lib.stylix.colors.base01}" })
        vim.notify = notify
      end

      -- blink-cmp setup: configured via nixvim opts above, with luasnip integration
      do
        local ok_snip, luasnip = pcall(require, "luasnip")
        if ok_snip then
          -- Load friendly-snippets lazily if available
          pcall(function()
            require("luasnip.loaders.from_vscode").lazy_load()
          end)
        end
        -- blink-cmp configuration is handled through the opts table above
        -- No additional setup needed here
      end

      -- Startup dashboard (alpha-nvim)
      do
        local ok_alpha, alpha = pcall(require, "alpha")
        if ok_alpha then
          local dashboard = require("alpha.themes.dashboard")

          -- Prefer generating the header with toilet (ansi-shadow), then figlet; fall back if unavailable
          local header_lines = nil
          local function gen_banner(cmd)
            local h = io.popen(cmd)
            if not h then return nil end
            local out = h:read("*a") or ""
            h:close()
            if #out == 0 then return nil end
            local lines = {}
            for line in out:gmatch("([^\n]*)\n?") do
              if line ~= "" then table.insert(lines, line) end
            end
            return #lines > 0 and lines or nil
          end

          header_lines = gen_banner('toilet -f ansi-shadow NIXVIM 2>/dev/null')
            or gen_banner('figlet -f "ANSI Shadow" NIXVIM 2>/dev/null')
            or gen_banner('figlet NIXVIM 2>/dev/null')

          if not header_lines then
            header_lines = {
              "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗",
              "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║",
              "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║",
              "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║",
              "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║",
              "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
            }
          end
          dashboard.section.header.val = header_lines

          dashboard.section.buttons.val = {
            dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
            dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
            dashboard.button("g", "󰺮  Live grep", ":Telescope live_grep<CR>"),
            dashboard.button("n", "  New file", ":enew<CR>"),
            dashboard.button("e", "  File browser", ":Neotree toggle<CR>"),
            dashboard.button("q", "  Quit", ":qa<CR>"),
          }

          local v = vim.version()
          dashboard.section.footer.val = string.format("NixVim • Neovim %d.%d.%d", v.major, v.minor, v.patch)

          dashboard.opts.opts.noautocmd = true
          alpha.setup(dashboard.config)

          -- Disable folding in alpha buffer
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "alpha",
            callback = function()
              vim.opt_local.foldenable = false
            end,
          })
        end
      end
    '';
  };
}
