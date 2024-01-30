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
---@param input string[]|nil # Lines to send to stdin.
---@return boolean success
---@return string[] result_lines # Each line of the output from the command.
function M.execute_command(cmd, input)
  -- TODO: execute_command cannot be called inside async task
  local result = vim.system(cmd, { stdin = input }):wait()
  if result.code == 0 then
    return true, vim.split(result.stdout or "", "\n", { plain = true, trimempty = false })
  else
    return false, {}
  end
end

return M
