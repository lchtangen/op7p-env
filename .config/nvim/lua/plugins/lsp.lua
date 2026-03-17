-- ── LSP + Completion — nvim 0.11 native API ──────────────────────────────────
return {
  -- Mason: LSP server installer
  { "williamboman/mason.nvim", config = function() require("mason").setup() end },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },

  -- nvim 0.11 native LSP setup
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end
        map("gd",         vim.lsp.buf.definition,     "Go to definition")
        map("gD",         vim.lsp.buf.declaration,    "Go to declaration")
        map("gr",         vim.lsp.buf.references,     "References")
        map("gi",         vim.lsp.buf.implementation, "Implementation")
        map("K",          vim.lsp.buf.hover,          "Hover docs")
        map("<leader>rn", vim.lsp.buf.rename,         "Rename")
        map("<leader>ca", vim.lsp.buf.code_action,    "Code action")
        map("<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "Format")
      end

      -- nvim 0.11: use vim.lsp.config for each server
      local servers = {
        pyright             = {},
        ts_ls               = {},
        gopls               = {},
        lua_ls              = { settings = { Lua = { diagnostics = { globals = { "vim" } } } } },
        bashls              = {},
        dockerls            = {},
        yamlls              = {},
        jsonls              = {},
      }

      for server, config in pairs(servers) do
        config.capabilities = capabilities
        config.on_attach = on_attach
        -- Use new 0.11 API if available, fall back to lspconfig
        if vim.lsp.config then
          vim.lsp.config(server, config)
          vim.lsp.enable(server)
        else
          require("lspconfig")[server].setup(config)
        end
      end

      -- Diagnostic signs
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        severity_sort = true,
        float = { border = "rounded" },
      })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python     = { "black", "isort" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          json       = { "prettier" },
          yaml       = { "prettier" },
          lua        = { "stylua" },
          go         = { "gofmt" },
          sh         = { "shfmt" },
        },
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
      })
    end,
  },
}
