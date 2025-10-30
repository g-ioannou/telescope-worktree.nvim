# my_worktree_picker.nvim

A Neovim plugin to pick a git worktree directory and execute commands via Telescope.

## Installation

```lua
require("lazy").setup({
  {
    "g-ioannou/telescope-worktree.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope-worktree").setup({
        on_select = function(worktree)
            vim.notify("Selected worktre " .. worktree)
        end
      })
    end,
  },
})
```
