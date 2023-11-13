local M = {}

function M.is_type_of(tbl, type_name)
  if type(tbl) ~= "table" then
    return false
  end
  return tbl.mytype == type_name
end

return M
