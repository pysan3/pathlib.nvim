local const = require("pathlib.const")
local M = {}

function M.is_type_of(tbl, type_name)
  if type(tbl) ~= "table" then
    return false
  end
  return tbl.mytype == type_name
end

function M.is_path_module(tbl)
  if type(tbl) ~= "table" then
    return false
  end
  for _, value in pairs(const.path_module_enum) do
    if tbl.mytype == value then
      return true
    end
  end
  return false
end

return M
