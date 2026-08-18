return {
  {
    dir = "~/repos/copy-reference.nvim",
    name = "copy-reference",
    opts = {}, -- Uses sensible defaults
    keys = {
      { "yr", "<cmd>CopyReference file<cr>", mode = { "n", "v" }, desc = "Copy file path" },
      { "yrr", "<cmd>CopyReference line<cr>", mode = { "n", "v" }, desc = "Copy file:line reference" },
    },
  },
}
