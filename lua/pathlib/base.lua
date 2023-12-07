local luv = vim.loop
local fs = vim.fs
local utils = require("pathlib.utils")
local const = require("pathlib.const")
local err = require("pathlib.utils.errors")

---@alias PathlibString string # Specific annotation for result of `tostring(Path)`

---@class PathlibPath
---@field _raw_paths PathlibStrList
---@field _drive_name string # Drive name for Windows path. ("C:", "D:")
---@field __windows_panic boolean # Windows paths shouldn't be passed to this type, but when it is.
---@field __string_cache string? # Cache result of `tostring(self)`.
local Path = {
  mytype = const.path_module_enum.PathlibPath,
  sep_str = "/",
  __string_cache = nil,
}
Path.__index = Path
setmetatable(Path, {
  ---@return PathlibPath
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

---Private init method to create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
function Path:_init(...)
  local run_resolve = false
  for i, s in ipairs({ ... }) do
    if utils.tables.is_type_of(s, const.path_module_enum.PathlibPath) then
      ---@cast s PathlibPath
      if i == 1 then
        self:copy_all_from(s)
      else
        assert(not s:is_absolute(), ("new: invalid root path object in %sth argument: %s"):format(i, s))
        self._raw_paths:extend(s._raw_paths)
      end
    elseif type(s) == "string" then
      local path = fs.normalize(s, { expand_env = true }):gsub([[^%./]], ""):gsub([[/%./]], "/"):gsub([[//]], "/")
      if path:sub(2, 2) == ":" then
        self.__windows_panic = true
        self:_panic_maybe_windows()
      end
      local splits = vim.split(path, "/", { plain = true, trimempty = false })
      if #splits == 0 then
        goto continue
      elseif vim.tbl_contains(splits, "..") then -- deal with '../' later in `self:resolve()`
        run_resolve = true
      end
      self._raw_paths:extend(splits)
    else
      error("PathlibPath(new): ValueError: Invalid type as argument: " .. ("%s (%s: %s)"):format(type(s), i, s))
    end
    ::continue::
  end
  self:__clean_paths_list()
  if run_resolve then
    self:resolve()
  end
end

---Create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
---@return PathlibPath
function Path.new(...)
  local self = Path.new_empty()
  self:_init(...)
  return self
end

function Path.new_empty()
  local self = setmetatable({}, Path)
  self._raw_paths = utils.lists.str_list.new()
  self._drive_name = ""
  self.__windows_panic = false
  self.__string_cache = nil
  return self
end

---Create a new Path object as self's child.
---@param ... string
---@return PathlibPath
function Path:new_child(...)
  local new = Path.new_all_from(self)
  new._raw_paths:extend({ ... })
  new.__string_cache = nil
  return new
end

---Unpack name and return a new self's child
---@param name string
---@return PathlibPath
function Path:new_child_unpack(name)
  local new = Path.new_all_from(self)
  for sub in name:gmatch("[/\\]") do
    new._raw_paths:append(sub)
  end
  new.__string_cache = nil
  return new
end

---Return `vim.fn.getcwd` in Path object
---@return PathlibPath
function Path.cwd()
  return Path(vim.fn.getcwd())
end

---Calculate permission integer from "rwxrwxrwx" notation.
---@param mode_string string
---@return integer
function Path.permission(mode_string)
  err.assert_function("Path.permission", function()
    return const.check_permission_string(mode_string)
  end, "mode_string must be in the form of `rwxrwxrwx` or `-` otherwise.")
  return const.permission_from_string(mode_string)
end

function Path:__clean_paths_list()
  self._raw_paths:filter_internal(nil, 2)
  if #self._raw_paths > 1 and self._raw_paths[1] == "." then
    self._raw_paths:shift()
  end
  self.__string_cache = nil
end

---Compare equality of path objects
---@param other PathlibPath
---@return boolean
function Path:__eq(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    err.value_error("__eq", other)
  end
  if self._drive_name ~= other._drive_name then
    return false
  end
  if #self._raw_paths ~= #other._raw_paths then
    return false
  end
  for i = 1, #self._raw_paths do
    if self._raw_paths[i] ~= other._raw_paths[i] then
      return false
    end
  end
  return true
end

---Compare less than of path objects
---@param other PathlibPath
---@return boolean
function Path:__lt(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    err.value_error("__lt", other)
  end
  if self._drive_name ~= other._drive_name then
    error(
      "PathlibPath: ValueError: drive_name is different. Uncomparable. "
        .. ("%s, %s"):format(self._drive_name, other._drive_name)
    )
  end
  for i = 1, #self._raw_paths do
    if self._raw_paths[i] ~= other._raw_paths[i] then
      return self._raw_paths[i] < other._raw_paths[i]
    end
  end
  return #self._raw_paths < #other._raw_paths
end

---Compare less than or equal of path objects
---@param other PathlibPath
---@return boolean
function Path:__le(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    err.value_error("__le", other)
  end
  return (self < other) or (self == other)
end

---Concatenate paths. `Path.cwd() / "foo" / "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibPath
function Path:__div(other)
  if not utils.tables.is_path_module(self) and not utils.tables.is_path_module(other) then
    -- one of objects must be a path object
    err.value_error("__div", other)
  end
  return self.new(self, other)
end

---Concatenate paths with the parent of lhs. `Path("./foo/foo.txt") .. "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibPath
-- Path.__concat = function(self, other)
function Path:__concat(other)
  if not utils.tables.is_path_module(self) and not utils.tables.is_path_module(other) then
    -- one of objects must be a path object
    err.value_error("__concat", other)
  end
  return self.new(self:parent(), other)
end

function Path:_panic_maybe_windows()
  -- if self.__windows_panic then
  --   vim.api.nvim_err_writeln(table.concat({
  --     "Possible Windows path detected with PathlibPath module.",
  --     "You may want to use PathlibWindows instead.",
  --     "`local WindowsPath = require('pathlib.windows')`",
  --   }, "\n"))
  -- end
end

---Convert path object to string
---@return string
function Path:__tostring()
  if not self.__string_cache then
    self.__string_cache =
      table.concat(self._raw_paths, self.sep_str):gsub([[^%./]], ""):gsub([[/%./]], "/"):gsub([[//]], "/")
    if self:is_absolute() and self._drive_name:len() > 0 then
      self.__string_cache = self._drive_name .. self.__string_cache
    end
  end
  return self.__string_cache
end

---Alias to `tostring(self)`
---@return string
function Path:tostring()
  return tostring(self)
end

---Return the group name of the file GID.
function Path:basename()
  return fs.basename(self:tostring())
end

---Return the group name of the file GID. Same as `str(self) minus self:modify(":r")`.
---@return string # extension of path including the dot (`.`): `.py`, `.lua` etc
function Path:suffix()
  local path_str = self:tostring()
  local without_ext = vim.fn.fnamemodify(path_str, ":r")
  return path_str:sub(without_ext:len() + 1) or ""
end

---Return the group name of the file GID. Same as `self:modify(":t:r")`.
---@return string # stem of path. (src/version.c -> "version")
function Path:stem()
  return vim.fn.fnamemodify(self:tostring(), ":t:r")
end

---Return parent directory of itself. If parent does not exist, returns nil.
---@return PathlibPath?
function Path:parent()
  if #self._raw_paths >= 2 then
    return Path.new_from(self, 1)
  else
    return nil
  end
end

---Return iterator of parents.
function Path:parents()
  local current = self
  return function()
    local result = current:parent()
    if result == nil then
      return nil
    else
      current = result
      return result
    end
  end
end

function Path:as_uri()
  assert(self:is_absolute(), "Relative paths cannot be expressed as a file URI.")
  local path = self:is_absolute() and self or self:absolute()
  return vim.uri_from_fname(path:tostring())
end

---Copy all attributes from `path` to self
---@param path PathlibPath
function Path:copy_all_from(path)
  self.mytype = path.mytype
  self._drive_name = path._drive_name
  self._raw_paths:extend(path._raw_paths)
  self._raw_paths:filter_internal(nil, 2)
  self.__string_cache = nil
end

---Copy all attributes from `path` to self
---@param path PathlibPath
function Path.new_all_from(path)
  local self = Path.new_empty()
  self.mytype = path.mytype
  self._drive_name = path._drive_name
  self._raw_paths:extend(path._raw_paths)
  self.__string_cache = nil
  return self
end

---Inherit from `path` and trim `_raw_paths` if specified.
---@param path PathlibPath
---@param trim_num number? # 1 will trim the last entry in `_raw_paths`, 2 will trim 2.
function Path.new_from(path, trim_num)
  local self = Path.new_all_from(path)
  if not trim_num or trim_num < 1 then
    return self
  end
  for _ = 1, trim_num do
    self._raw_paths:pop()
  end
  self.__string_cache = nil
  return self
end

---Shorthand to `vim.fn.stdpath` returned in Path object
---@param what string # See `:h stdpath` for information
---@return PathlibPath
function Path.stdpath(what)
  return Path.new(vim.fn.stdpath(what))
end

---Shorthand to `vim.fn.stdpath` and specify child path in later args.
---Mason bin path: `Path.stdpath("data", "mason", "bin")` or `Path.stdpath("data", "mason/bin")`
---@param what string # See `:h stdpath` for information
---@param ... string|PathlibPath # child path after the result of stdpath
---@return PathlibPath
function Path.stdpath_child(what, ...)
  return Path.new(vim.fn.stdpath(what), ...)
end

---Returns whether registered path is absolute
---@return boolean
function Path:is_absolute()
  local starts_with_slash = #self._raw_paths >= 1 and self._raw_paths[1] == ""
  if utils.tables.is_type_of(self, const.path_module_enum.PathlibWindows) then
    return self._drive_name:len() == 2 and starts_with_slash
  else
    return starts_with_slash
  end
end

---Returns whether registered path is relative
---@return boolean
function Path:is_relative()
  return not self:is_absolute()
end

function Path:as_posix()
  return self:tostring()
end

function Path:absolute()
  if self:is_absolute() then
    return self
  else
    return Path.new(vim.fn.getcwd(), self)
  end
end

---Get the path being modified with `filename-modifiers`
---@param mods string # filename-modifiers passed to `vim.fn.fnamemodify`
---@return string # result of `vim.fn.fnamemodify(tostring(self), mods)`
function Path:modify(mods)
  return vim.fn.fnamemodify(self:tostring(), mods)
end

---Call `fs_stat` with callback. This plugin will not help you here.
---@param follow_symlinks boolean? # Whether to resolve symlinks
---@param callback fun(err: string?, stat: uv.aliases.fs_stat_table?)
function Path:stat_async(follow_symlinks, callback)
  err.check_and_raise_typeerror("Path:stat_async", callback, "function")
  if follow_symlinks then
    luv.fs_stat(self:tostring(), callback)
  else
    luv.fs_lstat(self:tostring(), callback) ---@diagnostic disable-line
  end
end

---Return result of `luv.fs_stat`. Use `self:stat_async` to use with callback.
---Returns: `fs_stat_table | (nil, err_name: string, err_msg: string)`
---@param follow_symlinks? boolean # Whether to resolve symlinks
---@return uv.aliases.fs_stat_table|nil stat, string? err_name, string? err_msg
---@nodiscard
function Path:stat(follow_symlinks)
  if follow_symlinks then
    return luv.fs_stat(self:tostring())
  else
    return luv.fs_lstat(self:tostring()) ---@diagnostic disable-line
  end
end

function Path:lstat()
  return self:stat(false)
end

function Path:exists(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return stat and true or false
end

function Path:is_dir(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return stat and stat.type == "directory"
end

function Path:is_file(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return stat and stat.type == "file"
end

function Path:is_symlink()
  local stat = self:lstat()
  return stat and stat.type == "link"
end

---Get mode of path object. Use `self:get_type` to get type description in string instead.
---@param follow_symlinks boolean # Whether to resolve symlinks
---@return PathlibModeEnum?
function Path:get_mode(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return stat and stat.mode
end

---Get type description of path object. Use `self:get_mode` to get mode instead.
---@param follow_symlinks boolean # Whether to resolve symlinks
---@return string?
function Path:get_type(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return stat and stat.type
end

---Return whether `other` is the same file or not.
---@param other PathlibPath
---@return boolean
function Path:samefile(other)
  local stat = self:stat()
  local other_stat = other:stat()
  return (stat and other_stat) and (stat.ino == other_stat.ino and stat.dev == stat.dev) or false
end

function Path:is_mount()
  if not self:exists() or not self:is_dir() then
    return false
  end
  local stat = self:stat()
  if not stat then
    return false
  end
  local parent_stat = self:parent():stat()
  if not parent_stat then
    return false
  end
  if stat.dev ~= parent_stat.dev then
    return false
  end
  return stat.ino and stat.ino == parent_stat.ino
end

---Make directory. When `recursive` is true, will create parent dirs like shell command `mkdir -p`
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx"
---@param recursive boolean # if true, creates parent directories as well
function Path:mkdir(mode, recursive)
  if recursive then
    for parent in self:parents() do
      if not parent:exists(true) then
        parent:mkdir(mode, true)
      else
        break
      end
    end
  end
  luv.fs_mkdir(self:tostring(), mode)
end

---Make file. When `recursive` is true, will create parent dirs like shell command `mkdir -p`
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx"
---@param recursive boolean # if true, creates parent directories as well
---@return boolean success, string? err_name, string? err_msg # true if successfully created.
function Path:touch(mode, recursive)
  local fd, err_name, err_msg = self:fs_open("w", mode, recursive)
  if fd == nil then
    return false, err_name, err_msg
  else
    luv.fs_close(fd)
    return true
  end
end

---Copy file to `target`
---@param target PathlibPath # `self` will be copied to `target`
---@return boolean|nil success, string? err_name, string? err_msg # true if successfully created.
function Path:copy(target)
  err.assert_function("Path:copy", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return luv.fs_copyfile(self:tostring(), target:tostring())
end

---Create a simlink named `self` pointing to `target`
---@param target PathlibPath
---@return boolean|nil success, string? err_name, string? err_msg
function Path:symlink_to(target)
  err.assert_function("Path:symlink_to", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return luv.fs_symlink(self:tostring(), target:tostring())
end

---Create a hardlink named `self` pointing to `target`
---@param target PathlibPath
---@return boolean|nil success, string? err_name, string? err_msg
function Path:hardlink_to(target)
  err.assert_function("Path:hardlink_to", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return luv.fs_link(self:tostring(), target:tostring())
end

---Rename `self` to `target`. If `target` exists, fails with false. Ref: `Path:move`
---@param target PathlibPath
---@return boolean|nil success, string? err_name, string? err_msg
function Path:rename(target)
  err.assert_function("Path:rename", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return luv.fs_rename(self:tostring(), target:tostring())
end

---Move `self` to `target`. Overwrites `target` if exists. Ref: `Path:rename`
---@param target PathlibPath
---@return boolean|nil success, string? err_name, string? err_msg
function Path:move(target)
  err.assert_function("Path:move", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  target:unlink()
  return luv.fs_rename(self:tostring(), target:tostring())
end

---@deprecated Use `Path:move` instead.
---@param target PathlibPath
function Path:replace(target)
  return self:move(target)
end

---Resolves path. Eliminates `../` representation.
---Changes internal. (See `Path:resolve_copy` to create new object)
function Path:resolve()
  local accum, length = 1, self:len()
  for _, value in ipairs(self._raw_paths) do
    if value == ".." and accum > 1 then
      accum = accum - 1
    else
      self._raw_paths[accum] = value
      accum = accum + 1
    end
  end
  for i = accum, length do
    self._raw_paths[i] = nil
  end
  self.__string_cache = nil
  return self
end

---Resolves path. Eliminates `../` representation and returns a new object. `self` is not changed.
---@return PathlibPath
function Path:resolve_copy()
  local accum, length, new = 1, self:len(), self:new_all_from()
  for _, value in ipairs(self._raw_paths) do
    if value == ".." and accum > 1 then
      accum = accum - 1
    else
      new._raw_paths[accum] = value
      accum = accum + 1
    end
  end
  for i = accum, length do
    new._raw_paths[i] = nil
  end
  new.__string_cache = nil
  return new
end

---Get length of `self._raw_paths`. `/foo/bar.txt ==> 3: { "", "foo", "bar.txt" } (root dir counts as 1!!)`
---@return integer
function Path:len()
  return #self._raw_paths
end

---Change the permission of the path to `mode`.
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx"
---@param follow_symlinks boolean # Whether to resolve symlinks
---@return boolean|nil success, string? err_name, string? err_msg
function Path:chmod(mode, follow_symlinks)
  if follow_symlinks then
    return luv.fs_chmod(self:resolve():tostring(), mode)
  else
    return luv.fs_chmod(self:tostring(), mode)
  end
end

---Remove this file or link. If the path is a directory, use `Path:rmdir()` instead.
---@return boolean|nil success, string? err_name, string? err_msg
function Path:unlink()
  return luv.fs_unlink(self:tostring())
end

---Remove this directory.  The directory must be empty.
---@return boolean|nil success, string? err_name, string? err_msg
function Path:rmdir()
  return luv.fs_rmdir(self:tostring())
end

---Call `luv.fs_open`. Use `self:open_async` to use with callback.
---@param flags uv.aliases.fs_access_flags|integer
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx".
---@param ensure_dir integer|boolean|nil # if not nil, runs `mkdir -p self:parent()` with permission to ensure parent exists.
---  `true` will default to 755.
---@return integer|nil fd, string? err_name, string? err_msg
---@nodiscard
function Path:fs_open(flags, mode, ensure_dir)
  if ensure_dir == true then
    ensure_dir = const.permission_from_string("rwxr-xr-x")
  end
  if type(ensure_dir) == "integer" then
    self:parent():mkdir(ensure_dir, true)
  end
  return luv.fs_open(self:tostring(), flags, mode)
end

---Call `luv.fs_open` with callback. Use `self:open` for sync version.
---@param flags uv.aliases.fs_access_flags|integer
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx".
---@param ensure_dir integer|boolean|nil # if not nil, runs `mkdir -p self:parent()` with permission to ensure parent exists.
---  `true` will default to 755.
---@param callback fun(err: nil|string, fd: integer|nil)
---@return uv_fs_t
function Path:fs_open_async(flags, mode, ensure_dir, callback)
  if ensure_dir == true then
    ensure_dir = const.permission_from_string("rwxr-xr-x")
  end
  if type(ensure_dir) == "integer" then
    self:parent():mkdir(ensure_dir, true)
  end
  return luv.fs_open(self:tostring(), flags, mode, callback)
end

---Call `io.read`. Use `self:open_async` and `luv.read` to use with callback.
---@return string|nil data, string? err_msg
---@nodiscard
function Path:io_read()
  local file, err_msg = io.open(self:tostring(), "r")
  if not file then
    return nil, err_msg
  end
  return file:read("*a")
end

---Call `io.read` with byte read mode. Use `self:open_async` and `luv.read` to use with callback.
---@return string|nil data, string? err_msg
---@nodiscard
function Path:io_read_bytes()
  local file, err_msg = io.open(self:tostring(), "rb")
  if not file then
    return nil, err_msg
  end
  return file:read("*a")
end

---Call `io.write`. Use `self:open_async` and `luv.write` to use with callback. If failed, returns nil
---@param data string # content
---@return boolean success, string? err_msg
---@nodiscard
function Path:io_write(data)
  local file, err_msg = io.open(self:tostring(), "w")
  if not file then
    return false, err_msg
  end
  local result = file:write(data)
  file:flush()
  file:close()
  return result ---@diagnostic disable-line
end

---Call `io.write` with byte write mode. Use `self:open_async` and `luv.write` to use with callback. If failed, returns nil
---@param data string # content
---@return boolean success, string? err_msg
---@nodiscard
function Path:io_write_bytes(data)
  local file, err_msg = io.open(self:tostring(), "w")
  if not file then
    return false, err_msg
  end
  local result = file:write(tostring(data))
  file:flush()
  file:close()
  return result ---@diagnostic disable-line
end

---Alias to `vim.fs.dir` but returns PathlibPath objects.
---@param opts table|nil Optional keyword arguments:
---             - depth: integer|nil How deep the traverse (default 1)
---             - skip: (fun(dir_name: string): boolean)|nil Predicate
---               to control traversal. Return false to stop searching the current directory.
---               Only useful when depth > 1
---
---@return fun(): PathlibPath?, string? # items in {self}. Each iteration yields two values: "path" and "type".
---        "path" is the PathlibPath object.
---        "type" is one of the following:
---        "file", "directory", "link", "fifo", "socket", "char", "block", "unknown".
function Path:iterdir(opts)
  local generator = fs.dir(self:tostring(), opts)
  return function()
    local name, fs_type = generator()
    if name ~= nil then
      return self:new_child(unpack(vim.split(name:gsub("\\", "/"), "/", { plain = true, trimempty = false }))), fs_type
    end
  end
end

---Iterate directory with callback receiving PathlibPath objects
---@param callback fun(path: PathlibPath, fs_type: uv.aliases.fs_stat_types): boolean? # function called for each child in directory
---  When `callback` returns `false` the iteration will break out.
---@param on_error? fun(err: string) # function called when `luv.fs_scandir` fails
---@param on_exit? fun(count: integer) # function called after the scan has finished. `count` gives the number of children
function Path:iterdir_async(callback, on_error, on_exit)
  luv.fs_scandir(self:tostring(), function(e, handler)
    if e or not handler then
      if on_error and e then
        on_error(e)
      end
      return
    end
    local counter = 0
    while true do
      local name, fs_type = luv.fs_scandir_next(handler)
      if not name or not fs_type then
        break
      end
      counter = counter + 1
      if callback(self:new_child_unpack(name), fs_type) == false then
        break
      end
    end
    if on_exit then
      on_exit(counter)
    end
  end)
end

---Run `vim.fn.globpath` on this path.
---@param pattern string # glob pattern expression
---@return fun(): PathlibPath # iterator of results.
function Path:glob(pattern)
  local str = self:tostring()
  err.assert_function("Path:glob", function()
    return not (str:find([[,]]))
  end, "Path:glob cannot work on path that contains `,` (comma).")
  local result, i = vim.fn.globpath(str, pattern, false, true), 0 ---@diagnostic disable-line
  return function()
    i = i + 1
    return Path.new(result[i])
  end
end

return Path
