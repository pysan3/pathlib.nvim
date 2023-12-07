local const = require("pathlib.const")
local M = {}

---Return type or `tbl.mytype` if tbl is a path object.
---@param tbl any
---@return type|PathlibPathEnum
function M.type_of(tbl)
  local this_type = type(tbl)
  if this_type ~= "table" then
    return this_type
  end
  return tbl.mytype or this_type
end

---Checks if type of `tbl` is `type_name`. If `tbl` is a path object, checks for `tbl.mytype`.
---@param tbl any
---@param type_name type|PathlibPathEnum
---@return boolean
function M.is_type_of(tbl, type_name)
  return M.type_of(tbl) == type_name
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
