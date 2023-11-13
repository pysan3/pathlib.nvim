local luv = vim.loop
local fs = vim.fs
local utils = require("pathlib.utils")
local const = require("pathlib.const")

---@class PathlibPath
---@field _raw_paths PathlibStrList
---@field __windows_panic boolean
---@field _drive_name string # Drive name for Windows path. ("C:", "D:")
local Path = {
  mytype = const.PathlibPath,
  sep_str = "/",
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
  self._drive_name = ""
  self.__windows_panic = false
  for i, s in ipairs({ ... }) do
    if utils.tables.is_type_of(s, const.PathlibPath) then
      if i == 1 then
        self:copy_all_from(s)
      else
        assert(not s:is_absolute(), ("new: invalid root path object in %sth argument: %s"):format(i, s))
        self._raw_paths:extend(s._raw_paths)
      end
    elseif type(s) == "string" then
      local path = fs.normalize(s, { expand_env = true })
      if path:sub(2, 2) == ":" then
        self.__windows_panic = true
        self:_panic_maybe_windows()
      end
      self._raw_paths:extend(vim.split(path, "/", { plain = true, trimempty = false }))
    end
  end
  if #self._raw_paths == 0 then
    return Path.cwd()
  end
  return self
end

function Path.cwd()
  return Path.new(vim.fn.getcwd())
end

function Path:_panic_maybe_windows()
  if self.__windows_panic then
    vim.api.nvim_err_writeln(table.concat({
      "Possible Windows path detected with PathlibPath module.",
      "You may want to use PathlibWindows instead.",
      "`local WindowsPath = require('pathlib.windows')`",
    }, "\n"))
  end
end

---Convert path object to string
---@return string
function Path:__tostring()
  return self._drive_name .. table.concat(self._raw_paths, self.sep_str)
end

function Path:as_uri()
  assert(self:is_absolute(), "Relative paths cannot be expressed as a file URI.")
  local path = self:is_absolute() and self or self:absolute()
  return vim.uri_from_fname(tostring(path))
end

---Copy all attributes from `path` to self
---@param path PathlibPath
function Path:copy_all_from(path)
  self.mytype = path.mytype
  self._drive_name = path._drive_name
  self._raw_paths:extend(path._raw_paths)
end

---Returns whether registered path is absolute
---@return boolean
function Path:is_absolute()
  local starts_with_slash = #self._raw_paths >= 1 and self._raw_paths[1] == ""
  vim.print(string.format([[self: %s]], vim.inspect(self)))
  vim.print(string.format([[starts_with_slash: %s]], vim.inspect(starts_with_slash)))
  if utils.tables.is_type_of(self, const.PathlibWindows) then
    return self._drive_name:len() == 2 and starts_with_slash
  else
    return starts_with_slash
  end
end

---Returns whether registered path is relative
---@return boolean
function Path:is_relative()
  return not self:is_absolute()
end

function Path:as_posix()
  return tostring(self)
end

function Path:absolute()
  if self:is_absolute() then
    return self
  else
    return Path.new(vim.fn.getcwd(), self)
  end
end

---Get the path being modified with `filename-modifiers`
---@param mods string # filename-modifiers passed to `vim.fn.fnamemodify`
---@return string # result of `vim.fn.fnamemodify(tostring(self), mods)`
function Path:modify(mods)
  return vim.fn.fnamemodify(tostring(self), mods)
end

return Path
