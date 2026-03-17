-- ── Options ──────────────────────────────────────────────────────────────────
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "88"

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- UI
opt.termguicolors = true
opt.splitbelow = true
opt.splitright = true
opt.showmode = false
opt.laststatus = 3
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.pumheight = 10

-- Performance (mobile ARM64 optimised)
opt.updatetime = 100
opt.timeoutlen = 300
opt.synmaxcol = 200

-- Files
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.config/nvim/undo")
opt.fileencoding = "utf-8"
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- Folds
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
