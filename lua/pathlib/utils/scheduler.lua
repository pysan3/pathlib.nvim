local nio = require("nio")

---@class PathlibEventStorage
---@field public items PathlibPath[]
---@field public future nio.control.Future
---@field public start integer

---@alias PathlibScheduler.monitor fun(elapsed_ms: integer, item_len: integer, key: string): integer # A function to decide whether to trigger the debounce_fn. Triggers if value is negative.
---@alias PathlibScheduler.executor fun(items: PathlibPath[], key: string): (boolean, string|nil) # Executed when should_run_fn returns true. Return values are (success, error_msg?).

---@class PathlibScheduler
---@field public storage table<string, PathlibEventStorage>
---@field public minimum_debounce_ms integer
---@field public monitor PathlibScheduler.monitor
---@field public executor PathlibScheduler.executor
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
      start = vim.loop.hrtime(),
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
    if not info then
      return
    end
    nio.sleep(self.minimum_debounce_ms)
    local start, iter = info.start, 0
    while true do
      info = self.storage[key]
      if not info or info.start ~= start then
        return -- some other process triggered the task
      end
      local wait_ms = self.monitor((vim.loop.hrtime() - start) / 1000 / 1000, #info.items, key)
      if wait_ms <= 0 then
        break
      end
      nio.sleep(math.min(self.minimum_debounce_ms, wait_ms + iter))
      iter = iter + self.minimum_debounce_ms
    end
    self:trigger(key)
  end)
end

---Triggers `self.executor` for key.
---@param key string
function _Scheduler:trigger(key)
  local info = self.storage[key]
  if not info then
    return
  end
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
  if not info then
    return
  end
  self.storage[key] = nil
  nio.run(function()
    info.future.set_error(debug.traceback("Manually Cleared"))
  end)
end

---@alias PathlibScheduler.init fun(executor: PathlibScheduler.executor, monitor: PathlibScheduler.monitor|nil, minimum_debounce_ms: integer|nil): PathlibScheduler
---@type PathlibScheduler|PathlibScheduler.init
local Scheduler = _Scheduler

return Scheduler
