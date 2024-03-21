local Path = require("pathlib.base")
local const = require("pathlib.const")

local function load_winapi()
  if not const.has_ffi then
    return nil
  end
  return require("pathlib.utils.winapi_subset")
end

---@class PathlibWindowsPath : PathlibPath
---@operator div(PathlibWindowsPath|string): PathlibWindowsPath
---@operator concat(PathlibWindowsPath|string): PathlibWindowsPath
local WindowsPath = setmetatable({
  mytype = const.path_module_enum.PathlibWindows,
  sep_str = "\\",
}, {
  __index = Path,
  __call = function(cls, ...)
    return cls.new(...)
  end,
})
WindowsPath.__index = require("pathlib.utils.nuv").generate_index(WindowsPath)
require("pathlib.utils.paths").link_dunders(WindowsPath, Path)

---Private init method to create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
function WindowsPath:_init(...)
  Path._init(self, ...)
  self.__windows_panic = false
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
  ---@type PathlibWindowsPath
  local self = setmetatable({}, WindowsPath)
  self:to_empty()
  return self
end

function WindowsPath.cwd()
  return WindowsPath.new(vim.fn.getcwd())
end

function WindowsPath.home()
  return WindowsPath.new(vim.loop.os_homedir())
end

---Shorthand to `vim.fn.stdpath` and specify child path in later args.
---Mason bin path: `WindowsPath.stdpath("data", "mason", "bin")` or `WindowsPath.stdpath("data", "mason/bin")`
---@param what string # See `:h stdpath` for information
---@param ... string|PathlibPath # child path after the result of stdpath
---@return PathlibWindowsPath
function WindowsPath.stdpath(what, ...)
  return WindowsPath.new(vim.fn.stdpath(what), ...)
end

---Parse a uri and return its path. Protocol is saved at `self._uri_protocol`.
---@param uri string
function WindowsPath.from_uri(uri)
  local protocol, file = require("pathlib.utils.uri").parse_uri(uri)
  local result = WindowsPath.new(file)
  result._uri_protocol = protocol
  return result
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

---@type PathlibWindowsPath|fun(...: PathlibPath|PathlibString): PathlibWindowsPath
local M = WindowsPath

return M
