-- init.lua (Clean Kickstart + Modern Setup)

-- Leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable true color
vim.opt.termguicolors = true

-- Basic options
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- Keymaps
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>')
vim.keymap.set('n', '<C-l>', '<C-w><C-l>')
vim.keymap.set('n', '<C-j>', '<C-w><C-j>')
vim.keymap.set('n', '<C-k>', '<C-w><C-k>')

-- Per-language indentation (add after your other opts, before Lazy)
local function set_indent(ft, opts)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = ft,
    callback = function()
      vim.bo.shiftwidth = opts.shiftwidth or 2
      vim.bo.tabstop = opts.tabstop or opts.shiftwidth or 2
      vim.bo.softtabstop = opts.softtabstop or opts.shiftwidth or 2
      vim.bo.expandtab = opts.expandtab ~= false
    end,
  })
end

set_indent('lua', { shiftwidth = 2 })
set_indent('go', { shiftwidth = 4, tabstop = 4 })
set_indent('javascript', { shiftwidth = 2 })
set_indent('typescript', { shiftwidth = 2 })
set_indent('vue', { shiftwidth = 2 })
set_indent('c', { shiftwidth = 4, tabstop = 4 })
set_indent('cpp', { shiftwidth = 4, tabstop = 4 })

-- Highlight yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Lazy.nvim bootstrap
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.loop or vim.uv).fs_stat(lazypath) then
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', 'https://github.com/folke/lazy.nvim.git', lazypath }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- Indentation guesser
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- Git signs
  { 'lewis6991/gitsigns.nvim', opts = { signs = { add = '+', change = '~', delete = '_', topdelete = '‾', changedelete = '~' } } },

  -- Which-key
  { 'folke/which-key.nvim', event = 'VimEnter', opts = { delay = 0 } },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable 'make' == 1 end },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = false }, -- Nerd font false
    },
    config = function()
      local telescope = require 'telescope'
      telescope.setup {
        extensions = { ['ui-select'] = require('telescope.themes').get_dropdown() },
      }
      pcall(telescope.load_extension, 'fzf')
      pcall(telescope.load_extension, 'ui-select')
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    end,
  },

  -- LSP + Mason
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      require('mason').setup()
      require('mason-tool-installer').setup {
        ensure_installed = {
          'gopls',
          'typescript-language-server',
          'lua-language-server',
          'stylua',
        },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        gopls = {},
        ts_ls = {},
        lua_ls = {},
      }

      for name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  -- Autoformat
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    keys = { { '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end } },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == 'c' or vim.bo[bufnr].filetype == 'cpp' then return nil end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = { lua = { 'stylua' } },
    },
  },

  -- Autocompletion
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = { 'L3MON4D3/LuaSnip' },
    opts = { keymap = { preset = 'default' }, appearance = { nerd_font_variant = 'mono' } },
  },

  -- Colorscheme
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      require('tokyonight').setup { styles = { comments = { italic = false } } }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Todo comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  -- Mini.nvim (statusline, surround, textobjects)
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      require('mini.statusline').setup { use_icons = false }
    end,
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.config').setup {
        ensure_installed = {
          'lua',
          'go',
          'javascript',
          'typescript',
          'vue',
          'vim',
          'vimdoc',
          'query',
        },
        highlight = { enable = true },
        indent = { enable = true },
      }
    end,
  },
}, {
  ui = { icons = { cmd = '⌘', config = '🛠', ft = '📂', plugin = '🔌', start = '🚀' } },
})

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    -- Floating windows
    vim.cmd [[highlight NormalFloat guibg=NONE ctermbg=NONE]]
    vim.cmd [[highlight FloatBorder guibg=NONE ctermbg=NONE]]
    vim.cmd [[highlight TelescopeNormal guibg=NONE ctermbg=NONE]]
    vim.cmd [[highlight TelescopePromptNormal guibg=NONE ctermbg=NONE]]
    vim.cmd [[highlight TelescopePreviewNormal guibg=NONE ctermbg=NONE]]
  end,
})
