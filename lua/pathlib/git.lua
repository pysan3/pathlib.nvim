local const = require("pathlib.const")
local utils = require("pathlib.utils")

---@class PathlibGitState
---@field is_ready boolean # true if the git status is up to date.
---@field ignored boolean?

---@class PathlibGit
local M = {
  ---@type table<PathlibString, PathlibPath>
  __known_git_roots = {},
}

---Find closest directory that contains `.git` directory, meaning that it's a root of a git repository
---@param current_focus PathlibPath?
function M.find_root(current_focus)
  if not current_focus then
    return nil
  end
  local cache = M.__known_git_roots[current_focus:tostring()]
  if cache and cache:child(".git"):exists() then
    return cache
  end
  if current_focus:child(".git"):exists() then
    M.__known_git_roots[current_focus:tostring()] = current_focus
    return current_focus
  end
  local root = M.find_root(current_focus:parent())
  if root and current_focus:is_dir() then
    M.__known_git_roots[current_focus:tostring()] = root -- save result to cache
  end
  return root
end

-- ---Check if `git_status` contains `status`
-- ---@param git_status PathlibGitStatus
-- ---@param status PathlibGitStatusEnum
-- local function git_status_has(git_status, status)
--   return git_status[1] == status or git_status[2] == status
-- end

---Parse the git status
---@param status_string string
---@return PathlibGitStatus
function M.get_simple_git_status_code(status_string)
  -- Prioritze M then A over all others
  if status_string:match("U") or status_string == "AA" or status_string == "DD" then
    return { const.git_status.UNMODIFIED }
  elseif status_string:match("M") then
    return { const.git_status.MODIFIED }
  elseif status_string:match("[ACR]") then
    return { const.git_status.ADDED }
  elseif status_string:match("!$") then
    return { const.git_status.IGNORED }
  elseif status_string:match("?$") then
    return { const.git_status.UNTRACKED }
  else
    local len = #status_string
    while len > 0 do
      local char = status_string:sub(len, len)
      if char ~= " " then
        return git_simple_status_to_enum(char)
      end
      len = len - 1
    end
    return git_simple_status_to_enum(status_string)
  end
end

---Get the most significant git status among
---@param status PathlibGitStatusEnum?
---@param other_status PathlibGitStatusEnum?
---@return PathlibGitStatusEnum?
function M.get_priority_git_status_code(status, other_status)
  if not status then
    return other_status
  elseif not other_status then
    return status
  else
    local g = const.git_status
    for _, st in ipairs({ g.UPDATED_BUT_UNMERGED, g.UNTRACKED, g.MODIFIED, g.ADDED }) do
      if status == st or other_status == st then
        return st
      end
    end
    return status
  end
end

---git uses octal encoding for utf-8 filepaths, convert octal back to utf-8
---@param text string
---@return string # Converted string encoded with utf8
function M.octal_to_utf8(text)
  local function convert_octal_char(octal)
    return string.char(tonumber(octal, 8))
  end
  if type(text) ~= "string" then
    return text
  end
  -- remove the first and last " due to whitespace or utf-8 in the path
  -- convert octal encoded lines to utf-8
  local success, converted = pcall(string.gsub, text:gsub('^"(.*)"$', "%1"), [[\([0-7][0-7][0-7])]], convert_octal_char)
  return success and converted or text
end

---Parse and return status of git status output.
---@param line string # One line of git status output.
---@param git_status table<PathlibString, PathlibGitStatus>
---@param update_parent_dirs boolean # If true, updates status of parent dirs by merging the results of children.
---@param git_root PathlibPath
local function parse_git_status_line(line, git_status, update_parent_dirs, git_root)
  if type(line) ~= "string" then
    return
  end
  if #line < 4 then
    return
  end
  local line_parts = vim.split(line, "\t")
  if #line_parts < 2 then
    return
  end

  local status_string = line_parts[1]
  if status_string:match("^R") then -- is rename
    status_string = line_parts[3]
  end
  local status = M.get_simple_git_status_code(status_string)
  local relative_path = line_parts[2]
  -- remove any " due to whitespace or utf-8 in the path
  relative_path = relative_path:gsub('^"', ""):gsub('"$', "")
  -- convert octal encoded lines to utf-8
  relative_path = M.octal_to_utf8(relative_path)

  local absolute_path = git_root / relative_path
  local string_path = absolute_path:tostring()
  -- merge status result if there are results from multiple passes
  local existing_status = git_status[string_path] or {}
  status[1] = M.get_priority_git_status_code(existing_status[1], status[1])
  status[2] = M.get_priority_git_status_code(existing_status[2], status[2])
  git_status[string_path] = status
  if update_parent_dirs then
    -- Now bubble this status up to the parent directories
    for parent in absolute_path:parents() do
      local parent_string = parent:tostring()
      if not git_status[parent_string] then
        git_status[parent_string] = {}
      end
      local parent_status = git_status[parent_string]
      parent_status[1] = M.get_priority_git_status_code(parent_status[1], status[1])
      parent_status[2] = M.get_priority_git_status_code(parent_status[2], status[2])
    end
  end
end

---Fetch the status of files in a git repository.
---@param root_path PathlibPath
---@param update_parent_dirs boolean # If true, updates status of parent dirs by merging the results of children.
---@param commit_base string? # Commit to compare against. If nil, uses `HEAD`.
---@return table<PathlibString, PathlibGitStatus> git_status
---@return PathlibPath git_root
function M.status(root_path, update_parent_dirs, commit_base)
  local git_root = M.find_root(root_path)
  if not git_root or not git_root:is_dir() or not git_root:exists() then
    return {}, git_root
  end
  if not commit_base or commit_base:len() == 0 then
    commit_base = "HEAD"
  end
  local C = git_root:tostring()
  local staged_cmd = { "git", "-C", C, "diff", "--staged", "--name-status", commit_base, "--" }
  local staged_ok, staged_result = utils.execute_command(staged_cmd)
  if not staged_ok then
    return {}, git_root
  end
  local unstaged_cmd = { "git", "-C", C, "diff", "--name-status" }
  local unstaged_ok, unstaged_result = utils.execute_command(unstaged_cmd)
  if not unstaged_ok then
    return {}, git_root
  end
  local untracked_cmd = { "git", "-C", C, "ls-files", "--exclude-standard", "--others" }
  local untracked_ok, untracked_result = utils.execute_command(untracked_cmd)
  if not untracked_ok then
    return {}, git_root
  end

  ---@type table<PathlibString, PathlibGitStatus>
  local git_status = {}
  for _, line in ipairs(staged_result) do
    parse_git_status_line(line, git_status, update_parent_dirs, git_root)
  end
  for _, line in ipairs(unstaged_result) do
    if line then
      parse_git_status_line(" " .. line, git_status, update_parent_dirs, git_root)
    end
  end
  for _, line in ipairs(untracked_result) do
    if line then
      parse_git_status_line("? \t" .. line, git_status, update_parent_dirs, git_root)
    end
  end

  return git_status, git_root
end

return M
