local nio = require("nio")

local M = {}

if not nio.current_task then
  nio.current_task = function()
    return require("nio.tasks").current_task()
  end
end

---@param self PathlibPath
function M.generate_nuv(self)
  return setmetatable({}, {
    __index = function(_, key)
      return function(...)
        local result = {}
        if not nio.current_task() then
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
          result = { nio.uv.fs_opendir(args[1], args[3], args[2]) }
        else
          result = { nio.uv[key](...) }
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
