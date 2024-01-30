---@class PathlibPathUtils
local M = {}

---@class pathlib.private.normalize_default_opts
M.normalize_default_opts = {
  expand_env = true,
  collapse_slash = true,
}

function M.link_dunders(cls, base)
  function cls:__eq(other)
    return base.__eq(self, other)
  end
  function cls:__lt(other)
    return base.__lt(self, other)
  end
  function cls:__le(other)
    return base.__le(self, other)
  end
  function cls:__div(other)
    return base.__div(self, other)
  end
  function cls:__concat(other)
    return base.__concat(self, other)
  end
  function cls:__tostring()
    return base.__tostring(self)
  end
end

---Normalize path like `vim.fs.normalize`
---@param path string
---@param iswin boolean
---@param opts pathlib.private.normalize_default_opts
function M.normalize(path, iswin, opts)
  opts = vim.tbl_deep_extend("force", M.normalize_default_opts, opts or {})
  if path:sub(1, 1) == "~" then
    path = (vim.loop.os_homedir() or "~") .. "/" .. path:sub(2)
  end
  if opts.expand_env then
    path = path:gsub("%$([%w_]+)", vim.loop.os_getenv)
    if iswin then
      path = path:gsub("%%([%w_]+)%%", vim.loop.os_getenv)
    end
  end
  path = path:gsub(opts.collapse_slash and "[\\/]+" or "\\", "/")
  if iswin and path:match("^%w:/+$") then
    return path
  end
  return (path:gsub("([^/])/+$", "%1"))
end

---@param path PathlibPath
---@return PathlibPointer
function M.path_pointer(path)
  return string.format("%p", path)
end

return M
