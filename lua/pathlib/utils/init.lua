local M = {
  tables = require("pathlib.utils.tables"),
  lists = require("pathlib.utils.lists"),
}

---@return PathlibPath|PathlibWindowsPath|PathlibPosixPath
function M.importPath()
  return require("pathlib") ---@diagnostic disable-line
end

---Execute command via `systemlist` and return its status as well.
---@param cmd string[] # Command to execute as a list of strings.
---@return boolean success
---@return string[] result_lines # Each line of the output from the command.
function M.execute_command(cmd)
  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 or (#result > 0 and vim.startswith(result[1], "fatal:")) then
    return false, {}
  else
    return true, result
  end
end

return M
