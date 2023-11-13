---@class PathlibStrList
local str_list = {}
str_list.__index = str_list
setmetatable(str_list, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

function str_list.new()
  return setmetatable({}, str_list)
end

---@param value string
function str_list:append(value)
  self[#self + 1] = value
end

---@param list PathlibStrList
function str_list:extend(list)
  local start_from = #self
  for index, value in ipairs(list) do
    self[start_from + index] = value
  end
end

return {
  str_list = str_list,
}
