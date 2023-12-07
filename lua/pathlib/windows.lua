local Path = require("pathlib.base")

---@class PathlibWindowsPath : PathlibPath
local WindowsPath = {}
WindowsPath.__index = WindowsPath
setmetatable(WindowsPath, {
  __index = Path,
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function WindowsPath:_init(...)
  Path._init(self, ...)
  -- TODO: WindowsPath specific init procs
end
