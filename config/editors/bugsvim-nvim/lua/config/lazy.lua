-- ================================================================================================
-- TITLE: installing lazy plugin manager
-- ABOUT: Bootstarp and configure lazy.nvim plugin manager
-- ================================================================================================

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require 'config.options'
require 'config.globals'
require 'config.keymaps'
require 'config.autocmds'

-- Setup diagnostics
require('utils.diagnostics').setup()

-- Setup lazy.nvim
require('lazy').setup {
  spec = {
    -- import your plugins
    { import = 'plugins' },
  },
  rtp = {
    disabled_plugins = {
      'netrw',
      'netrwPlugin',
    },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { 'tokyonight-night' } },
  -- automatically check for plugin updates
  checker = { enabled = true },
}
