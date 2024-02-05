local M = {
  _has_nio = nil,
  ---@module "nio"
  nio = nil,
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
    M.nio.current_task = function()
      return require("nio.tasks").current_task()
    end
  end
  return M.nio.current_task()
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
          result = { M.nio.uv.fs_opendir(args[1], args[3], args[2]) }
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
