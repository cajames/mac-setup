-- lua/plugins/formatting.lua
return {
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local null_ls = require("null_ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        null_ls.builtins.formatting.biome,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "biome" },
        javascriptreact = { "biome" },
        typescript = { "biome" },
        typescriptreact = { "biome" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
      },
    },
  },
}
