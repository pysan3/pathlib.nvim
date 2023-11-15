---@class PathlibStrList:string[]
local str_list = {}
str_list.__index = str_list
setmetatable(str_list, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

---Filters out empty string
---@param e string
---@param _ integer
---@return boolean
function str_list.filter_empty(e, _)
  return e ~= ""
end

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

---Remove the first element in the list and return removed value.
---@return string? # first element that has been removed. If the list is already empty, returns nil.
function str_list:shift()
  if #self == 0 then
    return nil
  end
  return table.remove(self, 1)
end

---Remove the last element in the list and return removed value.
---@return string? # last element that has been removed. If the list is already empty, returns nil.
function str_list:pop()
  if #self == 0 then
    return nil
  end
  return table.remove(self, #self)
end

---Filter list but elements before `index_from` are free-pass. Returns new list.
---@param func? fun(e: string, idx: integer): boolean # filter function
---@param index_from integer? # Start filtering from this index and after. Set this value <= 0 or nil to have normal behavior
---@return PathlibStrList # Newly created list of filtered values
function str_list:filter(func, index_from)
  if index_from == nil then
    index_from = 0
  end
  local new = str_list.new()
  for index, value in ipairs(self) do
    if index < index_from or (func or self.filter_empty)(value, index) then
      new:append(value)
    end
  end
  return new
end

---Filter list but elements before `index_from` are free-pass. Returns new list.
---@param func? fun(e: string, idx: integer): boolean # filter function
---@param index_from integer? # Start filtering from this index and after. Set this value <= 0 or nil to have normal behavior
---@return PathlibStrList # Newly created list of filtered values
function str_list:filter_internal(func, index_from)
  if index_from == nil then
    index_from = 0
  end
  local new = str_list.new()
  for index, value in ipairs(self) do
    if index < index_from or (func or self.filter_empty)(value, index) then
      new:append(value)
    end
  end
  return new
end

return {
  str_list = str_list,
}
