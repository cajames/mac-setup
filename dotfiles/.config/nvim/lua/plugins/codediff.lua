local function default_branch()
  local out = vim.system({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" }, { text = true }):wait()
  if out.code ~= 0 then
    return "main"
  end
  return vim.trim(out.stdout)
end

return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gm", "<cmd>CodeDiff<CR>", desc = "Diff Working Tree (CodeDiff)" },
    {
      "<leader>gM",
      function()
        vim.cmd("CodeDiff " .. default_branch() .. "...")
      end,
      desc = "Diff vs Default Branch (CodeDiff)",
    },
    { "<leader>gH", "<cmd>CodeDiff history<CR>", desc = "History (CodeDiff)" },
  },
}
