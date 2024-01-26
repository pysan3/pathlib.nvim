local M = {}

---Raise error with multiline message.
---@param error_t string # Error Type
---@param ... string # Table of each line of the error message.
function M.multiline_error(error_t, ...)
  local t = { "PathlibPath: " .. error_t .. ":" }
  for _, line in ipairs({ ... }) do
    t[#t + 1] = "  " .. line
  end
  error(table.concat(t, "\n"), 2)
end

---Raise ValueError
---@param annotation string # function name where error is raised
---@param object any # Object with wrong value.
function M.value_error(annotation, object)
  local type_msg = type(object)
  if type(object) == "table" then
    type_msg = type_msg .. (" (mytype=%s)"):format(object.mytype)
  end
  error(("PathlibPath: ValueError (%s): called against unknown type: %s"):format(annotation, type_msg), 2)
end

---Raise TypeError
---@param annotation string # function name where error is raised
---@param object any # Object with wrong value.
function M.check_and_raise_typeerror(annotation, object, expected_type)
  local type_msg = type(object)
  if type(object) ~= expected_type then
    error(("PathlibPath: TypeError (%s). Expected type %s but got %s"):format(annotation, type_msg, expected_type), 2)
  end
end

---Run assert function and raise error.
---@param annotation string # function name where error is raised
---@param assert_func fun(): boolean # assert function to run
---@param description string # description of the error
function M.assert_function(annotation, assert_func, description)
  if not assert_func() then
    error(("PathlibPath: AssertionError (%s). %s"):format(annotation, description), 2)
  end
end

return M
