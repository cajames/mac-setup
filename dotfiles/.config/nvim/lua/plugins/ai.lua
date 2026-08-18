-- return {
-- "olimorris/codecompanion.nvim",
-- opts = {
--   strategies = {
--     chat = {
--       adapter = "anthropic",
--     },
--     inline = {
--       adapter = "anthropic",
--     },
--   },
-- },
-- dependencies = {
--   "nvim-lua/plenary.nvim",
--   "nvim-treesitter/nvim-treesitter",
-- },
-- }
return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({})
    end,
  },
}
