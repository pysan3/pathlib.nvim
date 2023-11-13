local luv = vim.loop
local fs = vim.fs
local utils = require("pathlib.utils")

local PathlibPath = "PathlibPath"
---@class PathlibPath
---@field _raw_paths PathlibStrList
local Path = {
  mytype = PathlibPath,
  ---Drive name for Windows path. ("C:", "D:")
  _drive_name = "",
}
Path.__index = Path
setmetatable(Path, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

function Path.new(...)
  local self = setmetatable({}, Path)
  self._raw_paths = utils.lists.str_list.new()
  for i, s in ipairs({ ... }) do
    if utils.tables.is_type_of(s, PathlibPath) then
      if i == 1 then
        self:copy_all_from(s)
      else
        assert(not s:is_absolute(), ("new: invalid root path object in %sth argument: %s"):format(i, s))
        self._raw_paths:extend(s._raw_paths)
      end
    elseif type(s) == "string" then
      local path = fs.normalize(s, { expand_env = true })
      self._raw_paths:extend(vim.split(path, "/", { plain = true, trimempty = false }))
    end
  end
  return self
end

---Copy all attributes from `path` to self
---@param path PathlibPath
function Path:copy_all_from(path)
  self.mytype = path.mytype
  self._drive_name = path._drive_name
end

function Path:is_absolute()
  -- TODO: Not implemented <2023-11-14>
  return false
end

return Path
