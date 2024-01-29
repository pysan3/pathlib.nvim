local nio = require("nio")
local Path = require("pathlib")
local git = require("pathlib.git")
local d = require("pathlib.utils.debug")

local log = Path("measure.log"):absolute()
log:io_write("")
local fd = log:fs_open("a")
assert(fd, log:tostring())
function d.p(...) ---@diagnostic disable-line
  vim.loop.fs_write(fd, d.ps(...) .. "\n")
end

---@alias after_func_cb fun(array: PathlibPath[])

---@param dir PathlibPath
---@param array PathlibPath[]
---@param cb after_func_cb?
local function scan_sync_rec(dir, array, cb)
  for path in dir:iterdir() do
    if path:is_dir() then
      scan_sync_rec(path, array)
    end
    array[#array + 1] = path
  end
  if cb then
    cb(array)
  end
end

---@param dir PathlibPath
---@param array PathlibPath[]
---@param cb after_func_cb?
local function scan_sync_depth(dir, array, cb)
  for path in dir:iterdir({ depth = 100 }) do
    array[#array + 1] = path
  end
  if cb then
    cb(array)
  end
end

---@param dir PathlibPath
---@param array PathlibPath[]
---@param cb after_func_cb?
local function scan_async_iterdir(dir, array, cb)
  local function _iterdir_cb(path, fs_type)
    if fs_type == "directory" then
      scan_async_iterdir(path, array, cb)
    end
    array[#array + 1] = path
  end
  dir:iterdir_async(_iterdir_cb, nil, function(_)
    if cb then
      cb(array)
    end
  end)
end

---@param dir PathlibPath
---@param array PathlibPath[]
---@param cb after_func_cb?
local function scan_async_nuv(dir, array, cb)
  local nuv = dir.nuv
  local function _iterdir(path)
    local h = nuv.fs_scandir(path:tostring())
    if not h then
      return
    end
    while true do
      local name, fs_type = vim.loop.fs_scandir_next(h)
      if not name or not fs_type then
        break
      end
      if fs_type == "directory" then
        _iterdir(path:child(name))
      end
      array[#array + 1] = path:child(name)
    end
  end
  _iterdir(dir)
  if cb then
    cb(array)
  end
end

---comment
---@param name string
---@param dir PathlibPath
---@param func fun(dir: PathlibPath, array: PathlibPath[], cb: after_func_cb?)
local function time_it(name, dir, func, times)
  d.pf("==== Start %s (%s times) ====", name, times)
  times = times or 1
  local start = os.clock()
  local counter = 0
  local function run_func()
    func(dir, {}, function(array)
      counter = counter + 1
      if counter < times then
        run_func()
      else
        local elapsed = os.clock() - start
        d.p(d.f("%s: (%.3f sec, %.3f ave) [# %06s]", name, elapsed, elapsed / times, #array))
      end
    end)
  end
  run_func()
end

d.p(vim.loop.os_homedir())
local linux = Path("~/Documents/linux"):absolute()
d.pf([[linux: %s]], linux)

local url = [[https://github.com/torvalds/linux]]
assert(linux:is_dir(true), string.format([[Please download %s into %s]], url, linux))

local obj = vim.system({ "tree", "-a", "-f", linux:tostring() }):wait()
local _, num_lines = obj.stdout:gsub("\n", "\t")
d.pf([[TREE: %s]], num_lines - 3) -- files detected with `tree` command (uncount summary lines)

local test_times = 5
-- local test_times = 1

nio.run(function()
  time_it("scan_sync_rec", linux, scan_sync_rec, test_times)
  time_it("scan_sync_depth", linux, scan_sync_depth, test_times)
  -- time_it("scan_async_iterdir", linux, scan_async_iterdir, test_times)
  time_it("scan_async_nuv", linux, scan_async_nuv, test_times)
end)

---@type PathlibPath[]
local array = {}
scan_async_nuv(linux, array)
d.pf("scan_async_nuv done. %s files.", #array)
git.fill_git_state_in_root(array, linux)
local dot_git = linux:child(".git")
for _, path in ipairs(array) do
  if not path.git_state.ignored and not vim.startswith(path:tostring(), dot_git:tostring()) then
    d.pp(path, d.g(path.git_state))
  end
end

vim.loop.fs_close(fd)
