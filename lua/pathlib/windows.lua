local Path = require("pathlib.base")
local const = require("pathlib.const")

local function load_winapi()
  if not const.has_ffi then
    return nil
  end
  return require("pathlib.utils.winapi_subset")
end

---@class PathlibWindowsPath : PathlibPath
---@overload fun(...: string|PathlibPath): PathlibWindowsPath
local WindowsPath = setmetatable({ ---@diagnostic disable-line
  mytype = const.path_module_enum.PathlibWindows,
  sep_str = "\\",
}, {
  __index = Path,
  __call = function(cls, ...)
    return cls.new(...)
  end,
})
WindowsPath.__index = require("pathlib.utils.nuv").generate_index(WindowsPath)

function WindowsPath:_init(...)
  Path._init(self, ...)
  self.__windows_panic = false
end

---Compare equality of path objects
---@param other PathlibPath
---@return boolean
function WindowsPath:__eq(other)
  return Path.__eq(self, other)
end

---Compare less than of path objects
---@param other PathlibPath
---@return boolean
function WindowsPath:__lt(other)
  return Path.__lt(self, other)
end

---Compare less than or equal of path objects
---@param other PathlibPath
---@return boolean
function WindowsPath:__le(other)
  return Path.__le(self, other)
end

---Concatenate paths. `Path.cwd() / "foo" / "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibWindowsPath
function WindowsPath:__div(other)
  return Path.__div(self, other) ---@diagnostic disable-line
end

---Concatenate paths with the parent of lhs. `Path("./foo/foo.txt") .. "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibWindowsPath
-- Path.__concat = function(self, other)
function WindowsPath:__concat(other)
  return Path.__concat(self, other) ---@diagnostic disable-line
end

function WindowsPath:__tostring()
  return Path.__tostring(self)
end

---Create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
---@return PathlibWindowsPath
function WindowsPath.new(...)
  local self = WindowsPath.new_empty()
  self:_init(...)
  return self
end

function WindowsPath.new_empty()
  local self = setmetatable({}, WindowsPath) ---@diagnostic disable-line
  self:to_empty()
  return self
end

function WindowsPath.cwd()
  return WindowsPath.new(vim.fn.getcwd())
end

function WindowsPath.home()
  return WindowsPath.new(vim.loop.os_homedir())
end

function WindowsPath.new_all_from(path)
  local self = WindowsPath.new_empty()
  self._drive_name = path._drive_name
  self._raw_paths:extend(path._raw_paths)
  self.__string_cache = nil
  return self
end

---Inherit from `path` and trim `_raw_paths` if specified.
---@param path PathlibPath
---@param trim_num number? # 1 will trim the last entry in `_raw_paths`, 2 will trim 2.
function WindowsPath.new_from(path, trim_num)
  local self = WindowsPath.new_all_from(path)
  if not trim_num or trim_num < 1 then
    return self
  end
  for _ = 1, trim_num do
    self._raw_paths:pop()
  end
  self.__string_cache = nil
  return self
end

---Shorthand to `vim.fn.stdpath` and specify child path in later args.
---Mason bin path: `WindowsPath.stdpath("data", "mason", "bin")` or `WindowsPath.stdpath("data", "mason/bin")`
---@param what string # See `:h stdpath` for information
---@param ... string|PathlibPath # child path after the result of stdpath
---@return PathlibWindowsPath
function WindowsPath.stdpath(what, ...)
  return WindowsPath.new(vim.fn.stdpath(what), ...)
end

---Returns whether registered path is absolute
---@return boolean
function WindowsPath:is_absolute()
  local starts_with_slash = #self._raw_paths >= 1 and self._raw_paths[1] == ""
  return starts_with_slash and self._drive_name:len() > 0
end

---Return whether the file is treated as a _hidden_ file.
---Posix: basename starts with `.`, Windows: calls `GetFileAttributesA`.
---@return boolean
function WindowsPath:is_hidden()
  local winapi = load_winapi()
  if not winapi then
    return false
  end
  local FILE_ATTRIBUTE_HIDDEN = 0x2
  return const.band(winapi.GetFileAttributesA(self:tostring()), FILE_ATTRIBUTE_HIDDEN) ~= 0
end

return WindowsPath
