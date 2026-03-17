-- ── Git Plugins ──────────────────────────────────────────────────────────────
return {
  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add    = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "" },
        },
        current_line_blame = true,
        current_line_blame_opts = { delay = 500 },
      })
    end,
  },

  -- LazyGit inside nvim
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
