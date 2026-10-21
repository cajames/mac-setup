local ts_preferences = {
  includeCompletionsForModuleExports = true,
  includeCompletionsForImportStatements = true,
  importModuleSpecifier = "non-relative",
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        virtual_lines = { current_line = true },
        signs = false,
      },
      servers = {
        tsc = {
          settings = {
            -- TS7 uses the unified `js/ts` namespace, older keys kept as fallback
            ["js/ts"] = { preferences = ts_preferences },
            typescript = { preferences = ts_preferences },
          },
        },
      },
    },
  },
}
