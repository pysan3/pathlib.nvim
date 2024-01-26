---@class PathlibPathUtils
local M = {}

---@class pathlib.private.normalize_default_opts
M.normalize_default_opts = {
  expand_env = true,
  collapse_slash = true,
}

---Normalize path like `vim.fs.normalize`
---@param path string
---@param iswin boolean
---@param opts pathlib.private.normalize_default_opts
function M.normalize(path, iswin, opts)
  opts = vim.tbl_deep_extend("force", M.normalize_default_opts, opts or {})
  if path:sub(1, 1) == "~" then
    path = (vim.loop.os_homedir() or "~") .. "/" .. path
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

return M
