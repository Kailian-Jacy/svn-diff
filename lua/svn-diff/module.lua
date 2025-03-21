---@class svn-diff
local M = {}

---@class SvnDiffAllOpt
---@field older_commit string
---@field newer_commit string
---@field new_tab      boolean

---@param opt SvnDiffAllOpt
M.diff_all = function(opt)
  -- by default, it compares the current work tree and last commit.
  opt.older_commit = opt.older_commit or "HEAD"
  opt.newer_commit = opt.newer_commit or "PREV"
  -- if older commit is empty, it goes to the last commit before newer_commit;
  -- if newer commit is empty, it's the current work tree.
end

---@param input string
M.svn_log_parse = function(input)
  local entries = {}

  -- Split the input into lines
  local lines = {}
  for line in input:gmatch("([^\n]*)\n?") do
    table.insert(lines, line)
  end

  local current_entry = nil

  -- Split into entries using separator lines
  for _, line in ipairs(lines) do
    if line:match("^%-%-%-%-+$") then
      -- Separator line found
      if current_entry then
        table.insert(entries, current_entry)
        current_entry = nil
      end
    else
      if not current_entry then
        current_entry = { lines = {} }
      end
      table.insert(current_entry.lines, line)
    end
  end

  -- Add the last entry if it exists
  if current_entry then
    table.insert(entries, current_entry)
  end

  -- Process each entry
  local parsed_entries = {}
  local i = 0
  for _, entry in ipairs(entries) do
    local entry_lines = entry.lines
    if #entry_lines == 0 then
      goto continue
    end

    -- Parse metadata line
    local meta_line = entry_lines[1]
    local parts = {}
    for part in meta_line:gmatch("([^|]+)") do
      table.insert(parts, part:match("^%s*(.-)%s*$")) -- Trim whitespace
    end

    if #parts < 4 then
      goto continue
    end

    local revision = parts[1]:match("^r(%d+)$")
    local author = parts[2]
    local date = parts[3]
    local line_count = tonumber(parts[4]:match("^(%d+)")) or 0

    -- Find message start (skip empty lines after metadata)
    local message_start = 2
    while message_start <= #entry_lines and entry_lines[message_start] == "" do
      message_start = message_start + 1
    end

    -- Fixed line: use unpack instead of table.unpack
    local message_lines = { unpack(entry_lines, message_start) }
    local message = table.concat(message_lines, "\n")

    i = i + 1

    table.insert(parsed_entries, {
      idx = i,
      commit = revision,
      author = author,
      date = date,
      line_count = line_count,
      text = message,
    })

    ::continue::
  end

  return parsed_entries
end

return M
