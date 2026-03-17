-- ── Autocommands ─────────────────────────────────────────────────────────────
local au = vim.api.nvim_create_autocmd

-- Highlight on yank
au("TextYankPost", {
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

-- Remove trailing whitespace on save
au("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Filetype indentation
au("FileType", {
  pattern = { "javascript","typescript","json","yaml","html","css","lua","markdown" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Auto-resize splits when terminal resizes
au("VimResized", {
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- Close some filetypes with q
au("FileType", {
  pattern = { "help","lspinfo","man","notify","qf","checkhealth" },
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
  end,
})

-- Return to last cursor position when opening file
au("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

vim.fn.mkdir(vim.fn.expand("~/.config/nvim/undo"), "p")
