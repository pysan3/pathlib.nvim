---@alias PathlibWatcherEvent { change: boolean?, rename: boolean? }
---@alias PathlibWatcherArgs { filename: string, events: PathlibWatcherEvent, dir: PathlibPath }
---@alias PathlibWatcherCallback fun(path: PathlibPath, args: PathlibWatcherArgs)

---@alias pathlib.private.callback_table table<PathlibPointer, PathlibPath>

---@class pathlib.private.watcher_storage
---@field handler uv_fs_event_t
---@field dir_callbacks pathlib.private.callback_table # directory path
---@field children table<PathlibString, pathlib.private.callback_table> # basename: path object
---@field num_children integer
---@field is_active boolean

---@class PathlibWatcher
local M = {
  ---@type table<PathlibString, pathlib.private.watcher_storage>
  storage = {},
  ---@type PathlibWatcherCallback[]?
  allways_run = nil,
}

local path_pointer = require("pathlib.utils.paths").path_pointer
local nio = require("nio")

---Register new path to watcher
---@param dir PathlibPath
---@param recursive boolean?
---@return uv_fs_event_t? fs_event_t # nil if failed to create an event.
---@return string? err_msg # error message from `new_fs_event` or `fs_event_start` (`fs_event_t` == nil)
function M.register_dir(dir, recursive)
  if recursive ~= false then
    M.register_file(dir, false)
  end
  local dir_str = dir:tostring()
  if not M.storage[dir_str] or not M.storage[dir_str].handler then
    local handler, err_new, _ = vim.loop.new_fs_event()
    if not handler then
      return nil, err_new
    end
    M.storage[dir_str] = {
      handler = handler,
      dir_callbacks = {},
      children = {},
      is_active = false,
      num_children = 0,
    }
  end
  local watcher = M.storage[dir_str]
  if dir:has_watcher() then
    watcher.dir_callbacks[path_pointer(dir)] = dir
  end
  if not watcher.is_active then
    local success, err_start, _ = watcher.handler:start(dir_str, {}, function(err, filename, events)
      if err then
        return
      end
      nio.run(function()
        local child = watcher.children[filename]
        for _, _p in pairs(child or watcher.dir_callbacks) do
          _p:execute_watchers(nil, { filename = filename, events = events, dir = dir })
        end
      end)
    end)
    if success == nil then
      return nil, err_start
    else
      watcher.is_active = true
    end
  end
  return watcher.handler
end

---Register new path to watcher
---@param path PathlibPath
---@param unique boolean?
---@return uv_fs_event_t? fs_event_t # nil if failed to create an event.
---@return string? err_msg # error message from `new_fs_event` or `fs_event_start` (`fs_event_t` == nil)
function M.register_file(path, unique)
  local parent = path:parent()
  if not parent then
    return nil, "Cound not find parent of " .. path:tostring()
  end
  local handler, err_msg = M.register_dir(parent, unique)
  if not handler then
    return nil, err_msg
  end
  local path_key = path:basename()
  local watcher = M.storage[parent:tostring()]
  if not watcher.children[path_key] then
    watcher.children[path_key] = {}
    watcher.num_children = watcher.num_children + 1
  end
  if unique then
    watcher.children[path_key][path_pointer(path)] = path
    watcher.children[path_key]["_"] = nil
  else
    watcher.children[path_key]["_"] = path
  end
  return watcher.handler
end

---Register new path to watcher
---@param path PathlibPath
---@return uv_fs_event_t? fs_event_t # nil if failed to create an event.
---@return string? err_msg # error message from `new_fs_event` or `fs_event_start` (`fs_event_t` == nil)
function M.register(path)
  if path:is_dir(true) then
    return M.register_dir(path, true)
  else
    return M.register_file(path, true)
  end
end

---Unregister path from watcher
---@param path PathlibPath
---@return boolean success
---@return string? err_msg # error message if `success` is false
function M.unregister_file(path)
  local parent = path:parent()
  if not parent or not M.storage[parent:tostring()] then
    return true
  end
  local watcher = M.storage[parent:tostring()]
  local path_key = path:basename()
  if watcher.children[path_key] then
    watcher.children[path_key][path_pointer(path)] = nil
    local counter = 0
    for key, _ in pairs(watcher.children[path_key]) do
      if key ~= "_" then
        counter = counter + 1
      end
    end
    if counter == 0 then
      watcher.children[path_key] = nil
      watcher.num_children = watcher.num_children - 1
    end
  end
  if watcher.num_children <= 0 then
    M.unregister_dir(parent)
  end
  return true
end

---Unregister path from watcher
---@param dir PathlibPath
---@return boolean success
---@return string? err_msg # error message if `success` is false
function M.unregister_dir(dir)
  M.unregister_file(dir)
  local watcher = M.storage[dir:tostring()]
  if watcher.is_active and watcher.handler then
    local success, err_msg, _ = watcher.handler:stop()
    if success == nil then
      return false, err_msg
    end
    watcher.is_active = false
    watcher.num_children = 0
    watcher.children = {}
  end
  return true
end

---Unregister path from watcher
---@param path PathlibPath
---@return boolean success
---@return string? err_msg # error message if `success` is false
function M.unregister(path)
  if path:is_dir(true) then
    return M.unregister_dir(path)
  else
    return M.unregister_file(path)
  end
end

return M
