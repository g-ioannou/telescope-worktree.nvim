local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local themes = require("telescope.themes")

local git_utils = require("telescope-worktree.utils.git")

local M = {}

function M.add_worktree(opts)
  opts = opts or {}

  if opts.theme then
    if opts.theme == "dropdown" then
      opts = themes.get_dropdown(opts)
    elseif opts.theme == "ivy" then
      opts = themes.get_ivy(opts)
    elseif opts.theme == "cursor" then
      opts = themes.get_cursor(opts)
    else
      vim.notify("Unknown theme: " .. opts.theme, vim.log.levels.WARN)
    end
  end

  git_utils.get_branches(function(branches)
    if vim.tbl_isempty(branches) then
      vim.notify("No branches found", vim.log.levels.WARN)
      return
    end

    pickers
        .new(opts, {
          prompt_title = "Select branch for new worktree",
          finder = finders.new_table({
            results = branches,
            entry_maker = function(line)
              return {
                value = line,
                display = line,
                ordinal = line,
              }
            end,
          }),
          sorter = conf.generic_sorter(opts),
          attach_mappings = function(prompt_bufnr, map)
            local function on_confirm()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if not entry or not entry.value then
                return
              end
              git_utils.create_worktree(entry.value)
            end
            map("i", "<CR>", on_confirm)
            map("n", "<CR>", on_confirm)
            return true
          end,
        })
        :find()
  end
  )
end

return M

