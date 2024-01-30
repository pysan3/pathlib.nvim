local d = {}

---@param str string
function d.flatten(str)
  return table.concat(vim.split(str:gsub("\n", " "), " +", { trimempty = true, plain = false }), " ")
end

---@param t table
function d.tbl(t)
  return d.flatten(vim.inspect(t))
end

function d.p(...)
  return vim.print(d.ps(...))
end

function d.ps(...)
  return (d.tbl({ ... }):sub(3, -3):gsub([[^['"](.*)["']$]], "%1"):gsub([[\t]], "  "))
end

function d.pt(...)
  local result = {}
  for index, value in ipairs({ ... }) do
    result[index] = tostring(value)
  end
  return unpack(result)
end

function d.pp(path, ...)
  return d.p(tostring(path), ...)
end

d.f = string.format

function d.pf(s, ...)
  return d.p(d.f(s, ...))
end

function d.ptr(x)
  return d.f("%p", x)
end

---@param state PathlibGitState
function d.g(state)
  return d.tbl(vim.tbl_deep_extend("force", state, { git_root = state.git_root:tostring() }))
end

---@param dir PathlibPath
function d.rmdir(dir)
  for _p in dir:iterdir() do
    if _p:is_dir(true) then
      d.rmdir(_p)
      _p:rmdir()
    end
    _p:unlink()
  end
  dir:rmdir()
end

return d
