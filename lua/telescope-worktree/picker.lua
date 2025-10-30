-- lua/my_worktree_picker/picker.lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local Job = require("plenary.job")
local Path = require("plenary.path")

local M = {}

-- returns list of worktree paths (strings)
local function get_git_worktrees()
  local results = {}
  -- run `git worktree list --porcelain`
  Job:new({
    command = "git",
    args = { "worktree", "list", "--porcelain" },
    cwd = vim.fn.getcwd(),
    on_exit = function(job, return_val)
      if return_val ~= 0 then
        return
      end
      for _, line in ipairs(job:result()) do
        -- line example: "worktree /path/to/dir"
        local path = line:match("^worktree%s+(.+)$")
        if path then
          table.insert(results, path)
        end
      end
    end,
  }):sync()
  return results
end

function M.run(opts)
  opts = opts or {}

  local worktrees = get_git_worktrees()

  if vim.tbl_isempty(worktrees) then
    vim.notify("No git worktrees found", vim.log.levels.WARN)
    return
  end

  pickers
      .new(opts, {
        prompt_title = "Select Git Worktree",
        finder = finders.new_table({
          results = worktrees,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
          map("i", "<CR>", function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            local worktree_path = selection[1]

            vim.cmd("cd " .. worktree_path)
            vim.notify("Selected worktree: " .. worktree_path)

            if opts.on_select then
              opts.on_select(worktree_path)
            end
          end)
          return true
        end,
      })
      :find()
end

return M
