local M = {}

---Parse a uri and return its path. Protocol is saved at `self._uri_protocol`.
---@param uri string
---@return string protocol # URI protocol (without `:`) such as `file`, `sftp`.
---@return string filepath # Path-like string representation that must be passed to `Path.new` to be normalized.
function M.parse_uri(uri)
  local colon = uri:find(":")
  assert(colon, string.format([[%s is not a valid uri.]], uri))
  assert(colon > 2, string.format([[Failed to parse uri schema for '%s'. Please report a BUG.]], uri))
  local protocol = uri:sub(1, colon - 1)
  local file = vim.uri_decode(uri):gsub(protocol .. ":/", ""):gsub("^/+([a-zA-Z]:)", "%1")
  return protocol, file
end

return M
