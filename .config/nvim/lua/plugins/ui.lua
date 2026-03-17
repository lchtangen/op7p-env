-- ── UI Plugins ───────────────────────────────────────────────────────────────
return {
  -- Catppuccin theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        integrations = {
          cmp = true, gitsigns = true, nvimtree = true,
          telescope = true, treesitter = true, which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin",
          component_separators = "|",
          section_separators = { left = "", right = "" },
          globalstatus = true,
        },
        sections = {
          lualine_a = { { "mode", separator = { left = "" } } },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { { "location", separator = { right = "" } } },
        },
      })
    end,
  },

  -- Bufferline (tabs)
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          separator_style = "slant",
          offsets = {{ filetype = "NvimTree", text = "Files", padding = 1 }},
        },
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function() require("ibl").setup({ indent = { char = "│" } }) end,
  },

  -- Which-key (keybinding cheatsheet)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({})
      require("which-key").register({
        ["<leader>f"] = { name = "Find" },
        ["<leader>g"] = { name = "Git" },
        ["<leader>l"] = { name = "LSP" },
        ["<leader>t"] = { name = "Terminal" },
      })
    end,
  },

  -- Notifications
  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
      require("notify").setup({ background_colour = "#1e1e2e" })
    end,
  },

  -- Dashboard
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("dashboard").setup({
        theme = "doom",
        config = {
          header = {
            "",
            "  ██╗  ████████╗ █████╗ ███╗  ██╗ ██████╗ ███████╗███╗  ██╗",
            "  ██║  ╚══██╔══╝██╔══██╗████╗ ██║██╔════╝ ██╔════╝████╗ ██║",
            "  ██║     ██║   ███████║██╔██╗██║██║  ███╗█████╗  ██╔██╗██║",
            "  ██║     ██║   ██╔══██║██║╚████║██║   ██║██╔══╝  ██║╚████║",
            "  ███████╗██║   ██║  ██║██║ ╚███║╚██████╔╝███████╗██║ ╚███║",
            "  ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚══╝ ╚═════╝ ╚══════╝╚═╝  ╚══╝",
            "                  OnePlus 7 Pro · Ubuntu · ARM64",
            "",
          },
          center = {
            { icon = "  ", key = "f", desc = "Find file",     action = "Telescope find_files" },
            { icon = "  ", key = "r", desc = "Recent files",  action = "Telescope oldfiles" },
            { icon = "  ", key = "g", desc = "Live grep",     action = "Telescope live_grep" },
            { icon = "  ", key = "e", desc = "File tree",     action = "NvimTreeToggle" },
            { icon = "  ", key = "n", desc = "New file",      action = "enew" },
            { icon = "  ", key = "q", desc = "Quit",          action = "qa" },
          },
        },
      })
    end,
  },
}
