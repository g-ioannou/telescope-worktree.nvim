local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local themes = require("telescope.themes")

local git_utils = require("telescope-worktree.utils.git")

local M = {}

function M.pick_worktree(opts)
	opts = opts or {}

	local worktrees = git_utils.get_git_worktrees()

	if vim.tbl_isempty(worktrees) then
		vim.notify("No git worktrees found", vim.log.levels.WARN)
		return
	end

	if opts.theme then
		local name = opts.theme
		if name == "dropdown" then
			opts = themes.get_dropdown(opts)
		elseif name == "ivy" then
			opts = themes.get_ivy(opts)
		elseif name == "cursor" then
			opts = themes.get_cursor(opts)
		else
			-- fallback: no theme change or log warning
			vim.notify("Unknown theme: " .. name, vim.log.levels.WARN)
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Change Git Worktree",
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