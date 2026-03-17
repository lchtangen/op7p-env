-- ── Editor Plugins ───────────────────────────────────────────────────────────
return {
  -- Telescope fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          path_display = { "truncate" },
          layout_strategy = "horizontal",
          layout_config = { preview_width = 0.55 },
          file_ignore_patterns = { "node_modules", ".git/", "__pycache__" },
        },
      })
      require("telescope").load_extension("fzf")
    end,
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30 },
        renderer = { group_empty = true, icons = { show = { git = true } } },
        filters = { dotfiles = false },
        git = { enable = true },
      })
    end,
  },

  -- Treesitter syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "python", "javascript", "typescript", "go",
          "bash", "json", "yaml", "markdown", "dockerfile",
          "sql", "html", "css", "rust",
        },
        highlight = { enable = true },
        indent = { enable = true },
        auto_install = true,
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function() require("nvim-autopairs").setup() end,
  },

  -- Commenting
  {
    "numToStr/Comment.nvim",
    config = function() require("Comment").setup() end,
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    config = function() require("nvim-surround").setup() end,
  },

  -- Todo comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("todo-comments").setup() end,
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        size = 15,
        open_mapping = [[<leader>t]],
        direction = "horizontal",
        shell = "/bin/zsh",
        float_opts = { border = "curved" },
      })
    end,
  },

  -- Search & replace
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', desc = "Spectre" } },
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
  },
}
