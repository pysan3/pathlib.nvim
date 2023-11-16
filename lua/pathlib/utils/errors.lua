local M = {}

---Raise ValueError
---@param annotation string # function name where error is raised
---@param object any # Object with wrong value.
M.value_error = function(annotation, object)
  local type_msg = type(object)
  if type(object) == "table" then
    type_msg = type_msg .. (" (mytype=%s)"):format(object.mytype)
  end
  error(("PathlibPath: ValueError (%s): called against unknown type: %s"):format(annotation, type_msg), 2)
end

---Raise TypeError
---@param annotation string # function name where error is raised
---@param object any # Object with wrong value.
M.check_and_raise_typeerror = function(annotation, object, expected_type)
  local type_msg = type(object)
  if type(object) ~= expected_type then
    error(("PathlibPath: TypeError (%s). Expected type %s but got %s"):format(annotation, type_msg, expected_type), 2)
  end
end

---Run assert function and raise error.
---@param annotation string # function name where error is raised
---@param assert_func fun(): boolean # assert function to run
---@param description string # description of the error
M.assert_function = function(annotation, assert_func, description)
  if not assert_func() then
    error(("PathlibPath: AssertionError (%s). %s"):format(annotation, description), 2)
  end
end

return M
