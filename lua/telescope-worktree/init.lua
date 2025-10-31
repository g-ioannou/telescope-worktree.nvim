local M = {}

M.opts = {
  on_select = nil,
  theme = "ivy"
}

-- @param opts table:
-- {
--    on_select = function(worktree_path)
-- }
function M.setup(opts)
  if opts ~= nil then
    for k, v in pairs(opts) do
      M.opts[k] = v
    end
  end

  vim.api.nvim_create_user_command("PickWorktree", function()
    require("telescope-worktree.picker").run(M.opts)
  end, {
    desc = "Pick a Git worktree",
  })
end

function M.pick_worktree()
  require("telescope-worktree.picker").pick_worktree(M.opts)
end

function M.add_worktree()
  require("telescope-worktree.picker").add_worktree(M.opts)
end

return M
