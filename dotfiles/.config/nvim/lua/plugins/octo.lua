-- base config comes from the `util.octo` LazyVim extra (lazyvim.json)
return {
  "pwntester/octo.nvim",
  opts = {
    use_local_fs = true, -- review diffs use local files when the PR branch is checked out (LSP works)
  },
  keys = {
    { "<leader>gv", "<cmd>Octo review<CR>", desc = "Review PR (Octo)" },
    { "<leader>gV", "<cmd>Octo review submit<CR>", desc = "Submit Review (Octo)" },
    { "<leader>gC", "<cmd>Octo review comments<CR>", desc = "Pending Review Comments (Octo)" },
    { "<leader>go", "<cmd>Octo pr checkout<CR>", desc = "Checkout PR (Octo)" },
    { "<leader>gn", "<cmd>Octo notification list<CR>", desc = "Notifications (Octo)" },
    { "<leader>gD", "<cmd>Octo discussion list<CR>", desc = "List Discussions (Octo)" },
  },
}
