-- ================================================================================================
-- TITLE : nvim-dap
-- ABOUT : Debug Adapter Protocol client implementation for Neovim
-- -- LINKS :
--   > github :https://github.com/mfussenegger/nvim-dap
--   > github :https://github.com/rcarriga/nvim-dap-ui
--   > github :https://github.com/nvim-neotest/nvim-nio
--   > github :https://github.com/mfussenegger/nvim-dap-python
-- ================================================================================================


-- Set up icons
-- stylua: ignore start
local icons = {
  Stopped               = { '', 'DiagnosticWarn', 'DapStoppedLine' },
  Breakpoint            = '',
  BreakpointCondition   = '',
  BreakpointRejected    = { '', 'DiagnosticError' },
  LogPoint              = '󰚃',
}
for name, sign in pairs(icons) do
  sign = type(sign) == 'table' and sign or { sign }
  vim.fn.sign_define('Dap' .. name, {
    text    = sign[1] --[[@as string]] .. ' ',
    texthl  = sign[2] or 'DiagnosticInfo',
    linehl  = sign[3],
    numhl   = sign[3],
  })
end
-- stylua: ignore end

-- Debugging setup
return {
  {
    'mfussenegger/nvim-dap',
    cmd = {
      'DapContinue',
      'DapStepOver',
      'DapStepInto',
      'DapStepOut',
      'DapToggleBreakpoint',
    },
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
    },
    keys = {
      -- stylua: ignore start
      { '<leader>dt', function() require('dap').toggle_breakpoint() end, desc = 'Debug Toggle Breakpoint' },
      { '<leader>ds', function() require('dap').continue() end, desc = 'Debug Start' },
      { '<leader>dc', function() require('dapui').close() end, desc = 'Debug Close' },
      { '<leader>dn', function() require('dap').step_over() end, desc = 'Debug Step Next' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Debug Step Into' },
      { '<leader>do', function() require('dap').step_out() end, desc = 'Debug Step Out' },
      -- stylua: ignore end
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup() -- Set up dapui


      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end

      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end
    end,
  },
  {
    'mfussenegger/nvim-dap-python',
    ft = 'python',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      local path = '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
      require('dap-python').setup(path)
    end,
  },
}
