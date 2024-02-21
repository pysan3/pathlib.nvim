local nio = require("nio")

---@class PathlibEventStorage
---@field items PathlibPath[]
---@field future nio.control.Future
---@field start integer

---@alias PathlibScheduler.monitor fun(elapsed_ms: integer, item_len: integer, key: string): boolean # A function to decide whether to trigger the debounce_fn.
---@alias PathlibScheduler.executor fun(items: PathlibPath[], key: string): (boolean, string|nil) # Executed when should_run_fn returns true. Return values are (success, error_msg?).

---@class PathlibScheduler
---@field storage table<string, PathlibEventStorage>
---@field monitor PathlibScheduler.monitor
---@field executor PathlibScheduler.executor
local _Scheduler = setmetatable({}, {
  __call = function(cls, ...)
    local self = setmetatable({
      storage = {},
    }, { __index = cls })
    self:init(...)
    return self
  end,
})
_Scheduler.__index = _Scheduler

---@param monitor PathlibScheduler.monitor
---@param executor PathlibScheduler.executor
function _Scheduler:init(monitor, executor)
  self.monitor = monitor
  self.executor = executor
end

---Append a new item to `key` schedule.
---@param key string
---@param item PathlibPath
---@return nio.control.Future future
function _Scheduler:add(key, item)
  if not self.storage[key] then
    self.storage[key] = {
      items = { item },
      future = nio.control.future(),
      start = os.clock(),
    }
  else
    table.insert(self.storage[key].items, item)
  end
  return self.storage[key].future
end

---Checks whether `self.executor` should be called by checking `self.monitor`.
---@param key string
function _Scheduler:check_and_trigger(key)
  return nio.run(function()
    local info = self.storage[key]
    if self.monitor(os.clock() - info.start, #info.items, key) then
      self:trigger(key)
    end
  end)
end

---Triggers `self.executor` for key.
---@param key string
function _Scheduler:trigger(key)
  local info = self.storage[key]
  self.storage[key] = nil
  nio.run(function()
    local suc, err = self.executor(info.items, key)
    if suc then
      info.future.set()
    else
      info.future.set_error(err)
    end
  end)
end

---Clears storage for key without running executor.
---@param key string
function _Scheduler:clear(key)
  local info = self.storage[key]
  self.storage[key] = nil
  nio.run(function()
    info.future.set_error(debug.traceback("Manually Cleared"))
  end)
end

---@alias PathlibScheduler.init fun(monitor: PathlibScheduler.monitor, executor: PathlibScheduler.executor): PathlibScheduler
---@type PathlibScheduler|PathlibScheduler.init
local Scheduler = _Scheduler

return Scheduler
