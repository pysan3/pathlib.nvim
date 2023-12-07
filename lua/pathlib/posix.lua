local Path = require("pathlib.base")
local err = require("pathlib.utils.errors")

---@class PathlibPosixPath : PathlibPath
local PosixPath = {}
PosixPath.__index = PosixPath
setmetatable(PosixPath, {
  __index = Path,
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

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
