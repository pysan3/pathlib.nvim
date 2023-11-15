local M = {}

---Raise ValueError
---@param func_name string # function name where error is raised
---@param object any # Object with wrong value.
M.value_error = function(func_name, object)
  local type_msg = type(object)
  if type(object) == "table" then
    type_msg = type_msg .. (" (mytype=%s)"):format(object.mytype)
  end
  error(("PathlibPath: ValueError: %s called against unknown type: %s"):format(func_name, type_msg), 2)
end

return M
