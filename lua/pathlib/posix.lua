local Path = require("pathlib.base")

---@class PathlibPosixPath
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
  -- TODO: PosixPath specific init procs
end
