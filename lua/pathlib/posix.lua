local Path = require("pathlib.base")
local const = require("pathlib.const")
local err = require("pathlib.utils.errors")

---@class PathlibPosixPath : PathlibPath
---@overload fun(...: string|PathlibPath): PathlibPosixPath
local PosixPath = setmetatable({ ---@diagnostic disable-line
  mytype = const.path_module_enum.PathlibPosixPath,
}, {
  __index = Path,
  __call = function(cls, ...)
    return cls.new(...)
  end,
})
PosixPath.__index = require("pathlib.utils.nuv").generate_index(PosixPath)
require("pathlib.utils.paths").link_dunders(PosixPath, Path)

---Private init method to create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
function PosixPath:_init(...)
  Path._init(self, ...)
  if self.__windows_panic then
    err.multiline_error(
      "RuntimeError",
      ("'%s' looks like a Windows path but you are using PosixPath."):format(self),
      [[If this is intended, use `require("pathlib.windows")` instead.]]
    )
  end
end

---Create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
---@return PathlibPosixPath
function PosixPath.new(...)
  local self = PosixPath.new_empty()
  self:_init(...)
  return self
end

function PosixPath.new_empty()
  ---@type PathlibPosixPath
  local self = setmetatable({}, PosixPath) ---@diagnostic disable-line
  self:to_empty()
  return self
end

function PosixPath.cwd()
  return PosixPath.new(vim.fn.getcwd())
end

function PosixPath.home()
  return PosixPath.new(vim.loop.os_homedir())
end

---Shorthand to `vim.fn.stdpath` and specify child path in later args.
---Mason bin path: `PosixPath.stdpath("data", "mason", "bin")` or `PosixPath.stdpath("data", "mason/bin")`
---@param what string # See `:h stdpath` for information
---@param ... string|PathlibPath # child path after the result of stdpath
---@return PathlibPosixPath
function PosixPath.stdpath(what, ...)
  return PosixPath.new(vim.fn.stdpath(what), ...)
end

---Parse a uri and return its path. Protocol is saved at `self._uri_protocol`.
---@param uri string
function PosixPath.from_uri(uri)
  local protocol, file = require("pathlib.utils.uri").parse_uri(uri)
  local result = PosixPath.new(file)
  result._uri_protocol = protocol
  return result
end

---Returns whether registered path is absolute
---@return boolean
function PosixPath:is_absolute()
  local starts_with_slash = #self._raw_paths >= 1 and self._raw_paths[1] == ""
  return starts_with_slash
end

---Return whether the file is treated as a _hidden_ file.
---Posix: basename starts with `.`.
---@return boolean
function PosixPath:is_hidden()
  return self:basename():sub(1, 1) == "."
end

return PosixPath
