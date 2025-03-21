-- main module file
local module = require("svn-diff.module")

---@class Config
---@field test_opt string Your config option
local config = {
  -- TODO: Try out testing opt.
  test_opt = "Hello!",
  svn_exe = 'ssh dev "z release && svn',
  -- svn_exe = "svn",
  max_log_items = 10,
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  if vim.fn.executable(M.config.svn_exe) == 0 then
    error("svn executable not found: " .. M.config.svn_exe)
  end
end

---@class svn_commits_opts
---@field max_log_items integer

---@param opts svn_commits_opts
M.snacks_svn_commits = function(opts)
  -- return module.my_first_function(M.config.opt)
  opts.max_log_items = opts.max_log_items or M.config.max_log_items

  -- local command = M.config.svn_exe .. " log " .. " -l " .. opts.max_log_items .. " --non-interactive"
  local command = M.config.svn_exe .. " log " .. " -l " .. opts.max_log_items .. " --non-interactive" .. '"'
  vim.print(command)

  local handle = io.popen(command)
  if not handle then
    error("Failed to execute svn command: " .. command)
  end
  local result = handle:read("*a")
  handle:close()

  vim.print(result)

  local picker_item = module.svn_log_parse(result)

  require("snacks").picker({
    title = "Commits",
    items = picker_item,
    -- preview = "none",
    format = function(item, picker)
      local ret = {}  ---@type snacks.picker.Highlight[]
      local a = Snacks.picker.util.align
      ret[#ret + 1] = { picker.opts.icons.git.commit, "SnacksPickerGitCommit" }
      -- local c = item.revision or "HEAD"
      ret[#ret + 1] = { a(item.author, 12, { truncate = true }), "SnacksPickerBold" }
      ret[#ret + 1] = { "| " }
      ret[#ret + 1] = { item.text, "SnacksPickerGitMsg" }
      -- TODO: right alignment and color.
      ret[#ret + 1] = { item.commit, "SnacksPickerGitCommit" }
      -- item.date = item.date -- TODO: Format date later.
      return ret
    end,
  })
end

M.snacks_svn_commits({})

return M
