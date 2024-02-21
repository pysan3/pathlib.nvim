local nio = require("nio")

---@class PathlibEventStorage
---@field items PathlibPath[]
---@field future nio.control.Future
---@field start integer

---@alias PathlibScheduler.monitor fun(elapsed_ms: integer, item_len: integer, key: string): boolean # A function to decide whether to trigger the debounce_fn.
---@alias PathlibScheduler.executor fun(items: PathlibPath[], key: string): (boolean, string|nil) # Executed when should_run_fn returns true. Return values are (success, error_msg?).

---@class PathlibScheduler
---@field storage table<string, PathlibEventStorage>
---@field minimum_debounce_ms integer
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

---@param executor PathlibScheduler.executor
---@param monitor PathlibScheduler.monitor|nil
---@param minimum_debounce_ms integer|nil
function _Scheduler:init(executor, monitor, minimum_debounce_ms)
  self.executor = executor
  self.minimum_debounce_ms = minimum_debounce_ms or 10
  self.monitor = monitor or function(elapsed_ms)
    return elapsed_ms >= self.minimum_debounce_ms
  end
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
  nio.run(function()
    if self.minimum_debounce_ms > 0 then
      nio.sleep(self.minimum_debounce_ms + 1)
    end
    self:check_and_trigger(key)
  end)
  return self.storage[key].future
end

---Checks whether `self.executor` should be called by checking `self.monitor`.
---@param key string
function _Scheduler:check_and_trigger(key)
  return nio.run(function()
    local info = self.storage[key]
    local elapsed = os.clock() - info.start
    if elapsed >= self.minimum_debounce_ms and self.monitor(elapsed, #info.items, key) then
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

---@alias PathlibScheduler.init fun(executor: PathlibScheduler.executor, monitor: PathlibScheduler.monitor|nil, minimum_debounce_ms: integer|nil): PathlibScheduler
---@type PathlibScheduler|PathlibScheduler.init
local Scheduler = _Scheduler

return Scheduler
