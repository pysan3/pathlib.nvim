local luv = vim.loop
local fs = vim.fs
local utils = require("pathlib.utils")
local const = require("pathlib.const")
local err = require("pathlib.utils.errors")

---@class PathlibPath
---@field _raw_paths PathlibStrList
---@field _drive_name string # Drive name for Windows path. ("C:", "D:")
---@field __windows_panic boolean # Windows paths shouldn't be passed to this type, but when it is.
local Path = {
  mytype = const.path_module_enum.PathlibPath,
  sep_str = "/",
}
Path.__index = Path
setmetatable(Path, {
  ---@return PathlibPath
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

---Create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
---@return PathlibPath
function Path.new(...)
  local self = setmetatable({}, Path)
  self._raw_paths = utils.lists.str_list.new()
  self._drive_name = ""
  self.__windows_panic = false
  for i, s in ipairs({ ... }) do
    if utils.tables.is_type_of(s, const.path_module_enum.PathlibPath) then
      ---@cast s PathlibPath
      if i == 1 then
        self:copy_all_from(s)
      else
        assert(not s:is_absolute(), ("new: invalid root path object in %sth argument: %s"):format(i, s))
        self._raw_paths:extend(s._raw_paths)
      end
    elseif type(s) == "string" then
      local path = fs.normalize(s, { expand_env = true }):gsub([[^%./]], ""):gsub([[/%./]], "/"):gsub([[//]], "/")
      if path:sub(2, 2) == ":" then
        self.__windows_panic = true
        self:_panic_maybe_windows()
      end
      local splits = vim.split(path, "/", { plain = true, trimempty = false })
      if #splits == 0 then
        goto continue
      end
      -- elseif -- TODO: deal with `../`
      self._raw_paths:extend(splits)
    else
      error("PathlibPath(new): ValueError: Invalid type as argument: " .. ("%s (%s: %s)"):format(type(s), i, s))
    end
    ::continue::
  end
  self:__clean_paths_list()
  return self
end

---Return `vim.fn.getcwd` in Path object
---@return PathlibPath
function Path.cwd()
  return Path(vim.fn.getcwd())
end

function Path:__clean_paths_list()
  self._raw_paths:filter_internal(nil, 2)
  if #self._raw_paths > 1 and self._raw_paths[1] == "." then
    self._raw_paths:shift()
  end
end

---Compare equality of path objects
---@param other PathlibPath
---@return boolean
function Path:__eq(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    err.value_error("__eq", other)
  end
  if self._drive_name ~= other._drive_name then
    return false
  end
  if #self._raw_paths ~= #other._raw_paths then
    return false
  end
  for i = 1, #self._raw_paths do
    if self._raw_paths[i] ~= other._raw_paths[i] then
      return false
    end
  end
  return true
end

---Compare less than of path objects
---@param other PathlibPath
---@return boolean
function Path:__lt(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    err.value_error("__lt", other)
  end
  if self._drive_name ~= other._drive_name then
    error(
      "PathlibPath: ValueError: drive_name is different. Uncomparable. "
        .. ("%s, %s"):format(self._drive_name, other._drive_name)
    )
  end
  for i = 1, #self._raw_paths do
    if self._raw_paths[i] ~= other._raw_paths[i] then
      return self._raw_paths[i] < other._raw_paths[i]
    end
  end
  return #self._raw_paths < #other._raw_paths
end

---Compare less than or equal of path objects
---@param other PathlibPath
---@return boolean
function Path:__le(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    err.value_error("__le", other)
  end
  return (self < other) or (self == other)
end

---Concat paths. `Path.cwd() / "foo" / "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath
---@return PathlibPath
function Path:__div(other)
  if not utils.tables.is_path_module(self) and not utils.tables.is_path_module(other) then
    -- one of objects must be a path object
    err.value_error("__div", other)
  end
  return self.new(self, other)
end

---Concat paths with the parent of lhs. `Path("./foo/foo.txt") .. "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath
---@return PathlibPath
-- Path.__concat = function(self, other)
function Path:__concat(other)
  if not utils.tables.is_path_module(self) and not utils.tables.is_path_module(other) then
    -- one of objects must be a path object
    err.value_error("__concat", other)
  end
  return self.new(self:parent(), other)
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
  local path_str = table.concat(self._raw_paths, self.sep_str):gsub([[^%./]], ""):gsub([[/%./]], "/"):gsub([[//]], "/")
  if self:is_absolute() then
    path_str = self._drive_name .. path_str
  end
  return path_str
end

---Return parent directory of itself. If parent does not exist, returns nil.
---@return PathlibPath?
function Path:parent()
  if #self._raw_paths >= 2 then
    return Path.new_from(self, 1)
  else
    return nil
  end
end

---Return iterator of parents.
function Path:parents()
  local current = self
  return function()
    local result = current:parent()
    if result == nil then
      return nil
    else
      current = result
      return result
    end
  end
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
  self._raw_paths:filter_internal(nil, 2)
end

---Inherit from `path` and trim `_raw_paths` if specified.
---@param path PathlibPath
---@param trim_num number? # 1 will trim the last entry in `_raw_paths`, 2 will trim 2.
function Path.new_from(path, trim_num)
  local self = Path.new()
  self:copy_all_from(path)
  if not trim_num or trim_num < 1 then
    return self
  end
  for _ = 1, trim_num do
    self._raw_paths:pop()
  end
  return self
end

---Shorthand to `vim.fn.stdpath` returned in Path object
---@param what string # See `:h stdpath` for information
---@return PathlibPath
function Path.stdpath(what)
  return Path.new(vim.fn.stdpath(what))
end

---Returns whether registered path is absolute
---@return boolean
function Path:is_absolute()
  local starts_with_slash = #self._raw_paths >= 1 and self._raw_paths[1] == ""
  if utils.tables.is_type_of(self, const.path_module_enum.PathlibWindows) then
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
