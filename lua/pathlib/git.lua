local const = require("pathlib.const")
local utils = require("pathlib.utils")

---@class PathlibGitState
---@field is_ready boolean # true if the git status is up to date.
---@field ignored boolean?
---@field git_root PathlibPath?
---@field state PathlibGitStatus?

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
  local g = const.git_status
  ---@type PathlibGitStatus
  local result = {
    status = g[status_string:sub(1, 1)] or g.STAGED,
    change = g[status_string:sub(2, 2)],
  }
  if status_string:sub(1, 1) == " " then
    result.status = g.UNSTAGED
  end
  if status_string:match("?$") then
    result.status = g.UNTRACKED
    result.change = nil
  elseif status_string:match("M") then
    result.change = g.MODIFIED
  elseif status_string:match("R") then
    result.change = g.RENAMED
  elseif status_string:match("[ACT]") then
    result.change = g.ADDED
  elseif status_string:match("!") then
    result.change = g.IGNORED
  elseif status_string:match("D") then
    result.change = g.DELETED
  end
  if status_string == "UU" or status_string == "DD" or status_string == "AA" then
    result.status = g.CONFLICT
    result.change = g.CONFLICT
  elseif status_string:match("U") then
    result.status = g.CONFLICT
  end
  return result
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
---@param update_parent_dir_state boolean # If true, updates status of parent dirs by merging the results of children.
---@param git_root PathlibPath
local function parse_git_status_line(line, git_status, update_parent_dir_state, git_root)
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
  local relative_path = M.octal_to_utf8(line_parts[2])
  local absolute_path = git_root / relative_path
  local string_path = absolute_path:tostring()
  -- merge status result if there are results from multiple passes
  local existing_status = git_status[string_path] or {}
  status.status = M.get_priority_git_status_code(existing_status.status, status.status)
  status.change = M.get_priority_git_status_code(existing_status.change, status.change)
  git_status[string_path] = status
  if update_parent_dir_state then
    -- Now bubble this status up to the parent directories
    for parent in absolute_path:parents() do
      local parent_string = parent:tostring()
      if not git_status[parent_string] then
        git_status[parent_string] = {}
      end
      local parent_status = git_status[parent_string]
      parent_status.status = M.get_priority_git_status_code(parent_status.status, status.status)
      parent_status.change = M.get_priority_git_status_code(parent_status.change, status.change)
    end
  end
end

---Fetch the status of files in a git repository.
---@param root_dir PathlibPath
---@param update_parent_dir_state boolean # If true, updates status of parent dirs by merging the results of children.
---@param commit_base string? # Commit to compare against. If nil, uses `HEAD`.
---@return table<PathlibString, PathlibGitStatus> git_status
---@return PathlibPath? git_root
function M.status(root_dir, update_parent_dir_state, commit_base)
  local git_root = M.find_root(root_dir)
  if not git_root or not git_root:is_dir() then
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
    parse_git_status_line(line, git_status, update_parent_dir_state, git_root)
  end
  for _, line in ipairs(unstaged_result) do
    if line then
      parse_git_status_line(" " .. line, git_status, update_parent_dir_state, git_root)
    end
  end
  for _, line in ipairs(untracked_result) do
    if line then
      parse_git_status_line("? \t" .. line, git_status, update_parent_dir_state, git_root)
    end
  end

  return git_status, git_root
end

---Fill in all `path.git_state.ignored`
---@param paths PathlibAbsPath[]
---@param git_root PathlibPath
function M.fill_git_ignore(paths, git_root)
  if not git_root then
    return
  end
  local cmd = { "git", "-C", git_root:tostring(), "check-ignore", "--stdin" }
  local path_strs = {}
  for _, path in ipairs(paths) do
    path_strs[#path_strs + 1] = path:tostring()
  end
  local success, result = utils.execute_command(cmd, path_strs)
  if not success then
    return
  end
  local counter = 1
  for _, line in ipairs(result) do
    local line_path = git_root.new(M.octal_to_utf8(line))
    while counter <= #paths and paths[counter] ~= line_path do
      paths[counter].git_state.ignored = false
      counter = counter + 1
    end
    if counter > #paths then
      break
    end
    paths[counter].git_state.ignored = true
    counter = counter + 1
  end
end

---Fill in all `path.git_state` inside a single git repo. Use `M.fill_git_state_batch` when git root is unknown.
---You may want to pass absolute paths for better performance.
---@param paths PathlibPath[] # List of paths to check git ignored or not. Overwrites `path.git_ignored`.
---@param git_root PathlibPath # The git root dir.
function M.fill_git_state_in_root(paths, git_root)
  local status, _ = M.status(git_root, true)
  for _, path in ipairs(paths) do
    path:inplace_absolute()
    path.git_state.is_ready = true
    path.git_state.git_root = git_root
    path.git_state.state = status[path:tostring()]
  end
  M.fill_git_ignore(paths, git_root)
end

---Fill in all `path.git_state` by asking git cli.
---@param paths PathlibPath[] # List of paths to check git ignored or not. Overwrites `path.git_ignored`.
function M.fill_git_state(paths)
  ---@type table<PathlibString, PathlibPath[] | { root: PathlibPath }>
  local check_list = {} -- sort paths by their git roots
  for _, path in ipairs(paths) do
    local root = M.find_root(path)
    if root then
      if not check_list[root:tostring()] then
        check_list[root:tostring()] = { root = root }
      end
      table.insert(check_list[path:tostring()], path)
    end
  end
  for _, path_list in pairs(check_list) do
    M.fill_git_state_in_root(path_list, path_list.root)
  end
end

---Callback to update `PathlibPath.git_state` on fs_event
---@param path PathlibPath
---@param args PathlibWatcherArgs
function M.update_git_state_callback(path, args)
  if path:is_dir(true) then
    return
  end
  path.git_state.is_ready = false
  if not path.git_state.git_root then
    path.git_state.git_root = M.find_root(path)
  end
  local cmd = { "git", "-C", path.git_state.git_root:tostring(), "check-ignore", path:tostring() }
  local suc, result = utils.execute_command(cmd)
  if suc then
    path.git_state.ignored = #result > 0
  end
  if not path.git_state.ignored then
    -- TODO: request status update cycle via debounce
    local status, _ = M.status(path.git_state.git_root, false)
    path.git_state.state = status[path:tostring()]
  end
end

return M
