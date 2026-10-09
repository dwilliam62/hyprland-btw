-- ================================================================================================
-- TITLE : org.nvim
-- ABOUT : Emacs Org mode for Neovim - outlines, TODOs, agenda, capture, clocking, tables, babel
-- LINKS :
--   > github : https://github.com/xheisenbugx/org.nvim
-- ================================================================================================
-- Committed DISABLED on this branch on purpose.
--
-- org.nvim runs `setup()` at startup (upstream sets lazy = false), so it installs
-- global normal-mode keymaps even when no .org file is ever opened:
--   <leader>oa agenda, <leader>oc capture, <leader>og goto heading,
--   <leader>ols store link, <leader>oxj/oxo/oxq clock, and the Emacs keys
--   <C-c>a / <C-c>c / <C-c>l (which make <C-c> a global prefix).
-- Inside .org buffers it also takes over <Tab>/<S-Tab>/<CR>/<S-CR> in insert mode,
-- plus a large set of buffer-local normal-mode keys.
--
-- Enabling it here would change current behaviour, so it is committed switched off
-- and evaluated on the xorg-vim branch instead.
return {
  'xheisenbugx/org.nvim',
  main = 'org',
  enabled = false,
  lazy = false, -- upstream default; heavy modules load on first use
  opts = {
    org_directory = '~/org',
    agenda_files = { '~/org/**/*.org' },
    default_notes_file = '~/org/refile.org',
    -- Keep blink.cmp's insert-mode <Tab> / <S-Tab> / <CR> working inside org
    -- buffers. org.nvim's org_insert defaults claim those keys for table field and
    -- row movement, and its buffer-local maps win over blink.cmp's global ones.
    -- Table editing is still available in normal mode: <leader>oTr/Ti/TR/TI.
    mappings = {
      org_insert = {
        insert_tab = false, -- <Tab>: table next field / heading level
        table_prev_field = false, -- <S-Tab>: table previous field
        table_next_row = false, -- <CR>: table next row
        table_copy_down = false, -- <S-CR>: copy table field down
      },
    },
  },
}
