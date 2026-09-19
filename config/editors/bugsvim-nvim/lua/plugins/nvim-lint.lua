-- ================================================================================================
-- TITLE : nvim lint
-- ABOUT : For code linting
-- LINKS : nvim-lint.nvim   https://github.com/mfussenegger/nvim-lint
-- ================================================================================================

return {
  'mfussenegger/nvim-lint',
  config = function()
    local lint = require 'lint'

    lint.linters_by_ft = {
      javascript = { 'eslint_d' },
      typescript = { 'eslint_d' },
      lua = { 'luacheck' },
      c = { 'cpplint' },
      cpp = { 'cpplint' },
      rust = { 'clippy' },
      python = { 'ruff' },
    }
    lint.linters.luacheck.args = {
      '--globals',
      'vim',
      'hl',
      '--formatter',
      'plain',
      '--codes',
      '--ranges',
      '-',
    }

    -- Lint on save
    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
