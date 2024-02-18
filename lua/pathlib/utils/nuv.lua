local M = {
  _has_nio = nil,
  ---@module "nio"
  nio = nil, ---@diagnostic disable-line
}

function M.check_nio_install()
  if M._has_nio == nil then
    M._has_nio, M.nio = pcall(_G.require, "nio")
  end
  return M._has_nio
end

function M.run(func)
  if not M.check_nio_install() then
    func()
  else
    M.nio.run(func)
  end
end

function M.current_task()
  if not M.check_nio_install() then
    return false
  end
  if not M.nio.current_task then
    return require("nio.tasks").current_task()
  else
    return M.nio.current_task()
  end
end

function M.execute_command(cmd, input)
  local process = M.nio.process.run({
    cmd = cmd[1],
    args = { unpack(cmd, 2) },
  })
  for i, value in ipairs(input or {}) do
    local err = process.stdin.write(value .. "\n")
    assert(not err, ([[ERROR cmd: '%s', input(%s): '%s', error: %s]]):format(table.concat(cmd, " "), i, value, err))
  end
  process.stdin.close()
  if process.result() == 0 then
    return true, vim.split(process.stdout.read() or "", "\n", { plain = true, trimempty = false })
  else
    return false, {}
  end
end

---@param self PathlibPath
function M.generate_nuv(self)
  return setmetatable({}, {
    __index = function(_, key)
      return function(...)
        local result = {}
        if not M.current_task() then
          result = { vim.loop[key](...) }
          if not result[1] then
            self.error_msg = result[2]
            return nil
          end
          return unpack(result)
        end
        -- is inside async task or is passed a `callback`
        if key == "fs_opendir" then
          local args = { ... }
          result = { M.nio.uv.fs_opendir(args[1], args[3], args[2]) } ---@diagnostic disable-line
        else
          result = { M.nio.uv[key](...) }
        end
        -- result[1]: err_msg or nil
        -- result[2, ...]: return values
        if result[1] then
          self.error_msg = result[1]
        end
        return unpack(result, 2)
      end
    end,
  })
end

function M.generate_index(cls)
  return function(self, key)
    if key == "nuv" then
      self.nuv = M.generate_nuv(self)
      return self.nuv
    end
    return cls[key]
  end
end

return M
