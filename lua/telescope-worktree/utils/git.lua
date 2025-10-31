local Job = require("plenary.job")

local M = {}

function M.git_root()
  local root = nil

  Job:new({
    command = "git",
    args = { "rev-parse", "--path-format=absolute", "--git-dir" },
    cwd = vim.fn.getcwd(),
    on_exit = function(job, code)
      if code ~= 0 then
        return
      end
      root = job:result()[1]
    end,
  }):sync()
  print(root)
  return root
end

-- safe directory name from branch
function M.dir_from_branch(branch)
  -- replace slashes and spaces; keep common safe chars
  return (branch:gsub("[/\\%s]+", "-"):gsub("[^%w%._%-]", "-"))
end

-- returns list of worktree paths (strings)
function M.get_git_worktrees()
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
        local path = line:match("^worktree%s+(.+)$")
        if path then
          table.insert(results, path)
        end
      end
    end,
  }):sync()
  return results
end

function M.get_branches(callback)
  local cwd = vim.fn.getcwd()
  -- sync branches
  Job:new({
    command = "git",
    args = { "fetch", "origin", "'+refs/heads/*:refs/remotes/origin/*'" },
    cwd = cwd,
    on_start = function()
      vim.notify("Fetching remote branches...")
    end,
    on_exit = function(job, return_val)
      if return_val ~= 0 then
        vim.notify("Failed to sync branches", vim.log.levels.WARN)
        return
      end

      local results = {}
      -- run `git branch --all --format='%(refname:short)'`
      Job:new({
        command = "git",
        args = { "branch", "--all", "--format=%(refname:short)" },
        cwd = cwd,
        on_exit = function(job, return_val)
          if return_val ~= 0 then
            return
          end

          for _, line in ipairs(job:result()) do
            -- clean up remote HEAD refs like "remotes/origin/HEAD -> origin/main"
            line = line:gsub("%s*->.*", ""):match("^%s*(.-)%s*$")
            if line ~= "" then
              table.insert(results, line)
            end
          end

          vim.schedule(function() callback(results) end)
        end,
      }):start()
    end,
  }):start()
end

-- create worktree for local or remote branch
function M.create_worktree(branch)
  local root = M.git_root()
  if not root then
    vim.notify("Not a git repo", vim.log.levels.ERROR)
    return
  end

  local dirname
  local target
  local args
  if branch:match("/") then
    -- remote branch format: <remote>/<name>
    local remote, short = branch:match("^([^/]+)/(.+)$")
    if not remote or not short then
      vim.notify("Unrecognized remote ref: " .. branch, vim.log.levels.ERROR)
      return
    end
    dirname = M.dir_from_branch(short)
    target = root .. "/" .. dirname
    -- create local branch tracking the remote
    args = { "worktree", "add", target, "-b", short, branch }
  else
    -- local branch
    dirname = M.dir_from_branch(branch)
    target = root .. "/" .. dirname
    args = { "worktree", "add", target, branch }
  end

  local stderr = {}
  local ok = true
  Job:new({
    command = "git",
    args = args,
    cwd = root,
    on_stderr = function(_, data)
      table.insert(stderr, data)
    end,
    on_exit = function(_, code)
      ok = code == 0
    end,
  }):sync()

  if not ok then
    vim.notify("git " .. table.concat(args, " ") .. " failed: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
    return
  end

  vim.notify("Worktree created at " .. target, vim.log.levels.INFO)

  -- optionally open it
  -- vim.cmd("tabe " .. target)
end

return M
