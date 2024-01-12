local Path = require("pathlib.base")
local utils = require("pathlib.utils")
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
PosixPath.__index = PosixPath

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

---Compare equality of path objects
---@param other PathlibPath
---@return boolean
function PosixPath:__eq(other)
  return Path:__eq(other)
end

---Compare less than of path objects
---@param other PathlibPath
---@return boolean
function PosixPath:__lt(other)
  return Path:__lt(other)
end

---Compare less than or equal of path objects
---@param other PathlibPath
---@return boolean
function PosixPath:__le(other)
  return Path:__le(other)
end

---Concatenate paths. `Path.cwd() / "foo" / "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibPosixPath
function PosixPath:__div(other)
  return Path.__div(self, other) ---@diagnostic disable-line
end

---Concatenate paths with the parent of lhs. `Path("./foo/foo.txt") .. "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibPosixPath
-- Path.__concat = function(self, other)
function PosixPath:__concat(other)
  return Path.__concat(self, other) ---@diagnostic disable-line
end

function PosixPath:__tostring()
  return Path.__tostring(self)
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
  local self = setmetatable({}, PosixPath) ---@diagnostic disable-line
  self:to_empty()
  return self
end

function PosixPath.cwd()
  return PosixPath(vim.fn.getcwd())
end

function PosixPath.new_all_from(path)
  local self = PosixPath.new_empty()
  self._drive_name = path._drive_name
  self._raw_paths:extend(path._raw_paths)
  self.__string_cache = nil
  return self
end

---Inherit from `path` and trim `_raw_paths` if specified.
---@param path PathlibPath
---@param trim_num number? # 1 will trim the last entry in `_raw_paths`, 2 will trim 2.
function PosixPath.new_from(path, trim_num)
  vim.print(("PosixPath.new_from (%s) .. %s"):format(path.mytype, path:tostring()))
  local self = PosixPath.new_all_from(path)
  if not trim_num or trim_num < 1 then
    return self
  end
  for _ = 1, trim_num do
    self._raw_paths:pop()
  end
  self.__string_cache = nil
  return self
end

---Shorthand to `vim.fn.stdpath` returned in Path object
---@param what string # See `:h stdpath` for information
---@return PathlibPosixPath
function PosixPath.stdpath(what)
  return PosixPath.new(vim.fn.stdpath(what))
end

---Shorthand to `vim.fn.stdpath` and specify child path in later args.
---Mason bin path: `PosixPath.stdpath("data", "mason", "bin")` or `PosixPath.stdpath("data", "mason/bin")`
---@param what string # See `:h stdpath` for information
---@param ... string|PathlibPath # child path after the result of stdpath
---@return PathlibPosixPath
function PosixPath.stdpath_child(what, ...)
  return PosixPath.new(vim.fn.stdpath(what), ...)
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
