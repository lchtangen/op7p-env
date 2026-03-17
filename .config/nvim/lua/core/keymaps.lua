-- ── Keymaps ──────────────────────────────────────────────────────────────────
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- ── Navigation ───────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", "Move left")
map("n", "<C-j>", "<C-w>j", "Move down")
map("n", "<C-k>", "<C-w>k", "Move up")
map("n", "<C-l>", "<C-w>l", "Move right")
map("n", "<C-Up>",    ":resize -2<CR>",          "Shrink height")
map("n", "<C-Down>",  ":resize +2<CR>",           "Grow height")
map("n", "<C-Left>",  ":vertical resize -2<CR>",  "Shrink width")
map("n", "<C-Right>", ":vertical resize +2<CR>",  "Grow width")

-- ── Buffers ──────────────────────────────────────────────────────────────────
map("n", "<S-l>",      ":bnext<CR>",    "Next buffer")
map("n", "<S-h>",      ":bprev<CR>",    "Prev buffer")
map("n", "<leader>bd", ":bdelete<CR>",  "Delete buffer")

-- ── File / Save / Quit ───────────────────────────────────────────────────────
map("n", "<leader>w",  ":w<CR>",        "Save")
map("n", "<leader>W",  ":wa<CR>",       "Save all")
map("n", "<leader>q",  ":q<CR>",        "Quit")
map("n", "<leader>Q",  ":qa!<CR>",      "Quit all")
map("n", "<leader>sv", ":vsplit<CR>",   "Vertical split")
map("n", "<leader>sh", ":split<CR>",    "Horizontal split")

-- ── Editing ──────────────────────────────────────────────────────────────────
map("v", "<",     "<gv",          "Indent left")
map("v", ">",     ">gv",          "Indent right")
map("n", "<A-j>", ":m .+1<CR>==", "Move line down")
map("n", "<A-k>", ":m .-2<CR>==", "Move line up")
map("v", "<A-j>", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "<A-k>", ":m '<-2<CR>gv=gv", "Move selection up")
map("n", "<leader>sr", ":%s/\\<<C-r><C-w>\\>//gI<Left><Left><Left>", "Replace word")

-- ── Telescope ────────────────────────────────────────────────────────────────
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",  "Find files")
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",   "Live grep")
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",     "Buffers")
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",   "Help")
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>",    "Recent files")
map("n", "<leader>fc", "<cmd>Telescope colorscheme<CR>", "Colorschemes")

-- ── File Tree ────────────────────────────────────────────────────────────────
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>",  "Toggle tree")
map("n", "<leader>E", "<cmd>NvimTreeFocus<CR>",   "Focus tree")

-- ── LSP (set in lsp plugin, listed here for reference) ──────────────────────
-- gd  → go to definition   gr  → references
-- K   → hover              <leader>ca → code action
-- <leader>rn → rename      <leader>f  → format

-- ── Git ──────────────────────────────────────────────────────────────────────
map("n", "<leader>gg", "<cmd>LazyGit<CR>",           "LazyGit")
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", "Blame line")
map("n", "<leader>gd", "<cmd>Gitsigns diffthis<CR>",   "Diff")
map("n", "]h",         "<cmd>Gitsigns next_hunk<CR>",  "Next hunk")
map("n", "[h",         "<cmd>Gitsigns prev_hunk<CR>",  "Prev hunk")

-- ── Terminal ─────────────────────────────────────────────────────────────────
map("n", "<leader>t",  "<cmd>ToggleTerm<CR>",          "Toggle terminal")
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", "Float terminal")
map("t", "<Esc>",      "<C-\\><C-n>",                  "Exit terminal")

-- ── Diagnostics ──────────────────────────────────────────────────────────────
map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>d", vim.diagnostic.open_float, "Show diagnostic")
