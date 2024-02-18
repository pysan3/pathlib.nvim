local fs = vim.fs
local utils = require("pathlib.utils")
local const = require("pathlib.const")
local errs = require("pathlib.utils.errors")
local watcher = require("pathlib.utils.watcher")

---@class PathlibPath
---@field public nuv uv
---@field public git_state PathlibGitState
---@field public error_msg string|nil
---@field public _raw_paths PathlibStrList
---@field public _drive_name string # Drive name for Windows path. ("C:", "D:", "\\127.0.0.1")
---@field public __windows_panic boolean # Set to true when passed path might be a windows path. PathlibWindows ignores this.
---@field public __fs_event_callbacks table<string, PathlibWatcherCallback>|nil # List of functions called when a fs_event is triggered.
---@field public __string_cache string|nil # Cache result of `tostring(self)`.
---@field public __parent_cache PathlibPath|nil # Cache reference to parent object.
local Path = setmetatable({
  mytype = const.path_module_enum.PathlibPath,
  sep_str = "/",
  const = const,
}, {
  __call = function(cls, ...)
    return cls.new(cls, ...)
  end,
})
Path.__index = require("pathlib.utils.nuv").generate_index(Path)

---Create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
---@return PathlibPath
function Path.new(...)
  for _, s in ipairs({ ... }) do -- find first arg that is PathlibWindowsPath or PathlibPosixPath
    if utils.tables.is_path_module(s) then
      ---@cast s PathlibPath
      if utils.tables.is_type_of(s, const.path_module_enum.PathlibWindows) then
        return require("pathlib.windows").new(...)
      elseif utils.tables.is_type_of(s, const.path_module_enum.PathlibPosix) then
        return require("pathlib.posix").new(...)
      end
    end
  end
  local self = Path.new_empty()
  self:_init(...)
  if self.__windows_panic then
    vim.api.nvim_err_writeln(table.concat({
      "Possible Windows path detected with PathlibPath module.",
      "You may want to use PathlibWindows instead.",
      "`local WindowsPath = require('pathlib.windows')`",
    }, "\n"))
  end
  return self
end

--          ╭─────────────────────────────────────────────────────────╮          --
--          │                     Class Methods                       │          --
--          ╰─────────────────────────────────────────────────────────╯          --

function Path.new_empty()
  ---@type PathlibPath
  local self = setmetatable({}, Path)
  self:to_empty()
  return self
end

---Return `vim.fn.getcwd` in Path object
---@return PathlibPath
function Path.cwd()
  return Path.new(vim.fn.getcwd())
end

---Return `vim.loop.os_homedir` in Path object
---@return PathlibPath
function Path.home()
  return Path.new(vim.loop.os_homedir())
end

---Calculate permission integer from "rwxrwxrwx" notation.
---@param mode_string string
---@return integer
function Path.permission(mode_string)
  errs.assert_function("Path.permission", function()
    return const.check_permission_string(mode_string)
  end, "mode_string must be in the form of `rwxrwxrwx` or `-` otherwise.")
  return const.permission_from_string(mode_string)
end

---Shorthand to `vim.fn.stdpath` and specify child path in later args.
---Mason bin path: `Path.stdpath("data", "mason", "bin")` or `Path.stdpath("data", "mason/bin")`
---@param what string # See `:h stdpath` for information
---@param ... string|PathlibPath # child path after the result of stdpath
---@return PathlibPath
function Path.stdpath(what, ...)
  return Path.new(vim.fn.stdpath(what), ...)
end

--          ╭─────────────────────────────────────────────────────────╮          --
--          │                     Object Methods                      │          --
--          ╰─────────────────────────────────────────────────────────╯          --

---Private init method to create a new Path object
---@param ... string | PathlibPath # List of string and Path objects
function Path:_init(...)
  local run_resolve = false
  local iswin = not utils.tables.is_type_of(self, const.path_module_enum.PathlibPosix)
  for i, s in ipairs({ ... }) do
    if utils.tables.is_path_module(s) then
      ---@cast s PathlibPath
      if i == 1 then
        self:copy_all_from(s)
      else
        assert(not s:is_absolute(), ("new: invalid root path object in %sth argument: %s"):format(i, s))
        self._raw_paths:extend(s._raw_paths)
      end
    elseif type(s) == "string" then
      local path = require("pathlib.utils.paths").normalize(s, iswin, { collapse_slash = false })
      if i == 1 then
        if path:sub(2, 2) == ":" then --[[Windows C: etc]]
          self.__windows_panic = true
          self._drive_name = path:sub(1, 2)
          path = path:sub(3)
        elseif vim.startswith(path, "//") then --[[Windows network devices: \\127.0.0.1, \\wsl$]]
          self.__windows_panic = true
          local path_start = path:find("/", 3) or 0
          local network_device = path:sub(3, path_start - 1)
          self._drive_name = self.sep_str:rep(2) .. network_device
          path = path_start > 0 and path:sub(path_start) or "/"
        end
      end
      local splits = vim.split(path:gsub("/+", "/"), "/", { plain = true, trimempty = false })
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

function Path:to_empty()
  self.git_state = { is_ready = false }
  self._raw_paths = utils.lists.str_list.new()
  self._drive_name = ""
  self.__windows_panic = false
  self.__string_cache = nil
  return self
end

---Copy all attributes from `path` to self
---@param path PathlibPath
function Path:copy_all_from(path)
  self._drive_name = path._drive_name
  self._raw_paths:extend(path._raw_paths)
  self.__string_cache = nil
  return self
end

---Copy all attributes from `path` to self
function Path:deep_copy()
  return self.new_empty():copy_all_from(self)
end

---Create a new Path object as self's child. `name` cannot be a grandchild.
---@param name string
---@return PathlibPath
function Path:child(name)
  local new = self.deep_copy(self)
  new._raw_paths:append(name)
  new.__string_cache = self:tostring() .. self.sep_str .. name
  new.__parent_cache = self
  return new
end

---Create a new Path object as self's descentant. Use `self:child` if new path is a direct child of the dir.
---@param ... string
---@return PathlibPath
function Path:new_descendant(...)
  local new = self:deep_copy()
  local args = { ... }
  new._raw_paths:extend(args)
  new.__string_cache = self:tostring() .. self.sep_str .. table.concat(args, self.sep_str)
  return new
end

---Unpack name and return a new self's grandchild, where `name` contains more than one `/`.
---@param name string
---@return PathlibPath
function Path:new_child_unpack(name)
  return self:new_descendant(unpack(vim.split(name, "[/\\]", { plain = false, trimempty = true })))
end

function Path:__clean_paths_list()
  self._raw_paths:filter_internal()
  self.__string_cache = nil
end

---Return the basename of `self`.
---Eg: foo/bar/baz.txt -> baz.txt
---@return string
function Path:basename()
  return self._raw_paths[#self._raw_paths]
end

---Return the group name of the file GID. Same as `str(self) minus self:modify(":r")`.
---@return string # extension of path including the dot (`.`): `.py`, `.lua` etc
function Path:suffix()
  return self:basename():sub(self:stem():len() + 1)
end

---Return the group name of the file GID. Same as `self:modify(":t:r")`.
---@return string # stem of path. (src/version.c -> "version")
function Path:stem()
  return (self:basename():gsub("([^.])%.[^.]+$", "%1", 1))
end

---Return parent directory of itself. If parent does not exist, returns nil.
---
---If you never want a nil, use `self:parent_assert()`. This will raise an error if parent not found.
---This could be used to chain methods: (`self:parent_assert():tostring()`, `self:parent_assert():fs_iterdir()`).
---
---@return PathlibPath|nil
function Path:parent()
  if not self.__parent_cache and #self._raw_paths >= 2 then
    local parent = self.deep_copy(self)
    local trim = parent._raw_paths:pop()
    if trim then
      self.__parent_cache = parent
    end
  end
  return self.__parent_cache
end

---Return parent directory of itself. This will raise an error when parent is not found.
---@return PathlibPath
function Path:parent_assert()
  local parent = self:parent()
  assert(parent, string.format([[Parent for %s not found.]], self))
  return parent
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

---Returns whether registered path is absolute
---@return boolean
function Path:is_absolute()
  error("PathlibPath: This function is an abstract method.")
end

---Return whether the file is treated as a _hidden_ file.
---Posix: basename starts with `.`, Windows: calls `GetFileAttributesA`.
---@return boolean
function Path:is_hidden()
  error("PathlibPath: This function is an abstract method.")
end

---Returns whether registered path is relative
---@return boolean
function Path:is_relative()
  return not self:is_absolute()
end

---Compute a version of this path relative to the path represented by `other`.
---If it’s impossible, nil is returned and `self.error_msg` is modified.
---
---When `walk_up == false` (the default), the path MUST start with `other`.
---When the argument is true, '`../`' entries may be added to form a relative path
---but this function DOES NOT check the actual filesystem for file existence whatsoever.
---
---If the paths referencing different drives or if only one of `self` or `other` is relative,
---nil is returned and `self.error_msg` is modified.
---
--->>> p = Path("/etc/passwd")
--->>> p:relative_to(Path("/"))
---Path.new("etc/passwd")
--->>> p:relative_to(Path("/usr"))
---nil; p.error_msg = "'%s' is not in the subpath of '%s'."
--->>> p:relative_to(Path("C:/foo"))
---nil; p.error_msg = "'%s' is not on the same disk as '%s'."
--->>> p:relative_to(Path("./foo"))
---nil; p.error_msg = "Only one path is relative: '%s', '%s'."
---
---@param other PathlibPath
---@param walk_up boolean|nil # If true, uses `../` to make relative path.
function Path:relative_to(other, walk_up)
  if self:is_absolute() and other:is_absolute() then
    if self._drive_name ~= other._drive_name then
      self.error_msg = string.format("'%s' is not on the same disk as '%s'.", self, other)
      return nil
    end
  elseif self:is_relative() and other:is_relative() then
  else
    self.error_msg = string.format("Only one path is relative: '%s', '%s'.", self, other)
    return nil
  end
  if not walk_up and not self:is_relative_to(other) then
    self.error_msg = string.format("'%s' is not in the subpath of '%s'.", self, other)
    return nil
  end
  local result = self:deep_copy()
  result._raw_paths:clear()
  result._drive_name = ""
  local index = other:len()
  while index > 0 and self._raw_paths[index] ~= other._raw_paths[index] do
    result._raw_paths:append("..")
    index = index - 1
  end
  for i = index + 1, self:len() do
    if self._raw_paths[i] and self._raw_paths[i]:len() > 0 then
      result._raw_paths:append(self._raw_paths[i])
    end
  end
  self:__clean_paths_list()
  return result
end

---Return whether or not this path is relative to the `other` path.
---This is a wrapper of `vim.startswith(tostring(self), tostring(other))` and nothing else.
---It neither accesses the filesystem nor treats “..” segments specially.
---
---Use `self:absolute()` or `self:to_absolute()` beforehand if needed.
---
---`other` may be a string, but MUST use the same path separators.
---
--->>> p = Path("/etc/passwd")
--->>> p:is_relative_to("/etc") -- Must be [[\etc]] on Windows.
---true
--->>> p:is_relative_to(Path("/usr"))
---false
---
---@param other PathlibPath|PathlibString
function Path:is_relative_to(other)
  return vim.startswith(tostring(self), tostring(other))
end

function Path:as_posix()
  if not utils.tables.is_type_of(self, const.path_module_enum.PathlibWindows) then
    return self:tostring()
  end
  local posix = self:deep_copy()
  if posix._drive_name:find("^[A-Za-z]:$") then
    posix._drive_name = ""
  end
  return (self:tostring():gsub(self.sep_str .. "+", require("pathlib.posix").sep_str))
end

---Returns a new path object with absolute path.
---
---Use `self:to_absolute()` instead to modify the object itself which does not need a deepcopy.
---
---If `self` is already an absolute path, returns itself.
---@param cwd PathlibPath|nil # If passed, this is used instead of `vim.fn.getcwd()`.
---@return PathlibPath
function Path:absolute(cwd)
  if self:is_absolute() then
    return self
  else
    return self.new(cwd or vim.fn.getcwd(), self)
  end
end

---Modifies itself to point to an absolute path.
---
---Use `self:absolute()` instead to return a new path object without modifying self.
---
---If `self` is already an absolute path, does nothing.
---@param cwd PathlibPath|nil # If passed, this is used instead of `vim.fn.getcwd()`.
function Path:to_absolute(cwd)
  if self:is_absolute() then
    return
  end
  local new = self.new(cwd or vim.fn.getcwd(), self)
  self._raw_paths:clear()
  self:copy_all_from(new)
end

---Get the path being modified with `filename-modifiers`
---@param mods string # filename-modifiers passed to `vim.fn.fnamemodify`
---@return string # result of `vim.fn.fnamemodify(tostring(self), mods)`
function Path:modify(mods)
  return vim.fn.fnamemodify(self:tostring(), mods)
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
  local accum, length, new = 1, self:len(), self:deep_copy()
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

---Run `vim.fn.globpath` on this path.
---@param pattern string # glob pattern expression
---@return fun(): PathlibPath # iterator of results.
function Path:glob(pattern)
  local str = self:tostring()
  errs.assert_function("Path:glob", function()
    return not (str:find([[,]]))
  end, "Path:glob cannot work on path that contains `,` (comma).")
  local result, i = vim.fn.globpath(str, pattern, false, true), 0 ---@diagnostic disable-line
  return function()
    i = i + 1
    return self.new(result[i])
  end
end

--          ╭─────────────────────────────────────────────────────────╮          --
--          │                  UV Filesystem Methods                  │          --
--          ╰─────────────────────────────────────────────────────────╯          --

---Return result of `luv.fs_stat`.
---@param follow_symlinks boolean|nil # Whether to resolve symlinks
---@return uv.aliases.fs_stat_table|nil stat # nil if `fs_stat` failed
---@nodiscard
function Path:fs_stat(follow_symlinks)
  if follow_symlinks then
    local realpath = self:realpath()
    if realpath then
      return realpath:fs_stat(false)
    end
  else
    return self.nuv.fs_stat(self:tostring())
  end
end

---Return result of `luv.fs_stat`. Use `self:stat_async` to use with callback.
---@param follow_symlinks boolean|nil # Whether to resolve symlinks
---@return uv.aliases.fs_stat_table|nil stat # nil if `fs_stat` failed
---@nodiscard
function Path:stat(follow_symlinks)
  return self:fs_stat(follow_symlinks)
end

function Path:lstat()
  return self:stat(false)
end

function Path:exists(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return not not stat
end

function Path:size()
  local stat = self:stat(true)
  return stat and stat.size
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

---Return result of `luv.fs_realpath` in `PathlibPath`.
---@return PathlibPath|nil # Resolves symlinks if exists. Returns nil if link does not exist.
function Path:realpath()
  local realpath = self.nuv.fs_realpath(self:tostring())
  if realpath then
    return self.new(realpath)
  end
end

---Get mode of path object. Use `self:get_type` to get type description in string instead.
---@param follow_symlinks boolean # Whether to resolve symlinks
---@return PathlibModeEnum|nil
function Path:get_mode(follow_symlinks)
  local stat = self:stat(follow_symlinks)
  return stat and stat.mode
end

---Get type description of path object. Use `self:get_mode` to get mode instead.
---@param follow_symlinks boolean # Whether to resolve symlinks
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
---@return boolean|nil success
function Path:mkdir(mode, recursive)
  if self:is_dir(true) then
    return true
  end
  if recursive then
    local parent = self:parent()
    if parent and not parent:is_dir(true) then
      local success = parent:mkdir(mode, recursive)
      if not success then
        return success
      end
    end
  end
  return self.nuv.fs_mkdir(self:tostring(), mode)
end

---Make file. When `recursive` is true, will create parent dirs like shell command `mkdir -p`
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx"
---@param recursive boolean # if true, creates parent directories as well
---@return boolean|nil success
function Path:touch(mode, recursive)
  local fd = self:fs_open("w", mode, recursive)
  if fd ~= nil then
    self.nuv.fs_close(fd)
    return true
  end
  return false
end

---Copy file to `target`
---@param target PathlibPath # `self` will be copied to `target`
---@return boolean|nil success # whether operation succeeded
function Path:copy(target)
  errs.assert_function("Path:copy", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return self.nuv.fs_copyfile(self:tostring(), target:tostring())
end

---Create a simlink named `self` pointing to `target`
---@param target PathlibPath
---@return boolean|nil success # whether operation succeeded
function Path:symlink_to(target)
  errs.assert_function("Path:symlink_to", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return self.nuv.fs_symlink(self:tostring(), target:tostring())
end

---Create a hardlink named `self` pointing to `target`
---@param target PathlibPath
---@return boolean|nil success # whether operation succeeded
function Path:hardlink_to(target)
  errs.assert_function("Path:hardlink_to", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return self.nuv.fs_link(self:tostring(), target:tostring())
end

---Rename `self` to `target`. If `target` exists, fails with false. Ref: `Path:move`
---@param target PathlibPath
---@return boolean|nil success # whether operation succeeded
function Path:rename(target)
  errs.assert_function("Path:rename", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  return self.nuv.fs_rename(self:tostring(), target:tostring())
end

---Move `self` to `target`. Overwrites `target` if exists. Ref: `Path:rename`
---@param target PathlibPath
---@return boolean|nil success # whether operation succeeded
function Path:move(target)
  errs.assert_function("Path:move", function()
    return utils.tables.is_path_module(target)
  end, "target is not a Path object.")
  if target:exists() then
    target:unlink()
  end
  return self.nuv.fs_rename(self:tostring(), target:tostring())
end

---@deprecated Use `Path:move` instead.
---@param target PathlibPath
function Path:replace(target)
  return self:move(target)
end

---Change the permission of the path to `mode`.
---@param mode integer # permission. You may use `Path.permission()` to convert from "rwxrwxrwx"
---@param follow_symlinks boolean # Whether to resolve symlinks
---@return boolean|nil success # whether operation succeeded
function Path:chmod(mode, follow_symlinks)
  if follow_symlinks then
    return self.nuv.fs_chmod(self:realpath():tostring(), mode)
  else
    return self.nuv.fs_chmod(self:tostring(), mode)
  end
end

---Remove this file or link. If the path is a directory, use `Path:rmdir()` instead.
---@return boolean|nil success # whether operation succeeded
function Path:unlink()
  return self.nuv.fs_unlink(self:tostring())
end

---Remove this directory.  The directory must be empty.
---@return boolean|nil success # whether operation succeeded
function Path:rmdir()
  return self.nuv.fs_rmdir(self:tostring())
end

---Call `luv.fs_open`.
---@param flags uv.aliases.fs_access_flags|integer
---@param mode integer|nil # permission. You may use `Path.permission()` to convert from "rwxrwxrwx".
---@param ensure_dir integer|boolean|nil # if not nil, runs `mkdir -p self:parent()` with permission to ensure parent exists.
---  `true` will default to 755.
---@return integer|nil fd
---@nodiscard
function Path:fs_open(flags, mode, ensure_dir)
  if ensure_dir == true then
    ensure_dir = const.o755
  end
  if type(ensure_dir) == "number" then
    self:parent():mkdir(ensure_dir, true)
  end
  return self.nuv.fs_open(self:tostring(), flags, mode or const.o644)
end

---Call `luv.fs_open("r") -> luv.fs_read`.
---@param size integer|nil # if nil, uses `self:stat().size`
---@param offset integer|nil
---@return string|nil content # content of the file
function Path:fs_read(size, offset)
  local fd = self:fs_open("r")
  return fd and self.nuv.fs_read(fd, size or self:size() or 0, offset) --[[@as string]]
end

---Call `luv.fs_open("w") -> luv.fs_write`.
---@param data uv.aliases.buffer
---@param offset integer|nil
---@return integer|nil bytes # number of bytes written
function Path:fs_write(data, offset)
  local fd = self:fs_open("w", nil, true)
  return fd and self.nuv.fs_write(fd, data, offset) --[[@as integer]]
end

---Call `luv.fs_open("a") -> luv.fs_write`.
---@param data uv.aliases.buffer
---@param offset integer|nil
---@return integer|nil bytes # number of bytes written
function Path:fs_append(data, offset)
  local fd = self:fs_open("a", nil, true)
  return fd and self.nuv.fs_write(fd, data, offset) --[[@as integer]]
end

---Call `io.read`. Use `self:fs_read` to use with `nio.run` instead.
---@return string|nil data # whole file content
function Path:io_read()
  local file, err_msg = io.open(self:tostring(), "r")
  if not file then
    self.error_msg = err_msg
    return nil
  end
  local data, err_read = file:read("*a")
  if not data then
    self.error_msg = err_read
    return nil
  end
  return data
end

---Call `io.read` with byte read mode.
---@return string|nil bytes # whole file content
function Path:io_read_bytes()
  local file, err_msg = io.open(self:tostring(), "rb")
  if not file then
    self.error_msg = err_msg
    return nil
  end
  local data, err_read = file:read("*a")
  if not data then
    self.error_msg = err_read
    return nil
  end
  return data
end

---Call `io.write`. Use `self:fs_write` to use with `nio.run` instead. If failed, returns error message
---@param data string # content
---@return boolean # success
function Path:io_write(data)
  local file, err_msg = io.open(self:tostring(), "w")
  if not file then
    self.error_msg = err_msg
    return false
  end
  local _, err_write = file:write(tostring(data))
  if err_write then
    self.error_msg = err_write
    return false
  end
  file:flush()
  file:close()
  return true
end

---Call `io.write` with byte write mode.
---@param data string # content
function Path:io_write_bytes(data)
  local file, err_msg = io.open(self:tostring(), "wb")
  if not file then
    self.error_msg = err_msg
    return false
  end
  local _, err_write = file:write(tostring(data))
  if err_write then
    self.error_msg = err_write
    return false
  end
  file:flush()
  file:close()
  return true
end

---Iterate dir with `luv.fs_scandir`.
---@param follow_symlinks boolean|nil # If true, resolves hyperlinks and go into the linked directory.
---@param depth integer|nil # How deep the traverse. If nil or <1, scans everything.
---@param skip_dir (fun(dir: PathlibPath): boolean)|nil # Function to decide whether to dig in a directory.
function Path:fs_iterdir(follow_symlinks, depth, skip_dir)
  depth = depth or -1
  ---@type uv_fs_t|nil
  local handler = nil
  local current, i_dir, last_index = self, 1, 1
  local paths = { self }
  local depths = { 1 }
  local function next_file()
    current = paths[i_dir]
    if not current then
      return nil
    end
    if not handler then
      handler = self.nuv.fs_scandir(current:tostring())
      if not handler then
        return handler
      end
    end
    local name, fs_type = vim.loop.fs_scandir_next(handler)
    if not name then
      handler = nil
      i_dir = i_dir + 1
      return next_file()
    end
    local child = current:child(name)
    if follow_symlinks and fs_type == "link" then
      child = child:realpath() or child
      fs_type = (child:lstat() or { type = "file" }).type
    end
    if fs_type == "directory" and (depth < 0 or depths[i_dir] < depth) and (skip_dir and not skip_dir(child)) then
      last_index = last_index + 1
      paths[last_index] = child
      depths[last_index] = depths[i_dir] + 1
    end
    return child
  end
  return next_file
end

--          ╭─────────────────────────────────────────────────────────╮          --
--          │                     Dunder Methods                      │          --
--          ╰─────────────────────────────────────────────────────────╯          --

---Compare equality of path objects
---@param other PathlibPath
---@return boolean
function Path:__eq(other)
  if not utils.tables.is_path_module(self) or not utils.tables.is_path_module(other) then
    errs.value_error("__eq", other)
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
    errs.value_error("__lt", other)
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
    errs.value_error("__le", other)
  end
  return (self == other) or (self < other)
end

---Get length of `self._raw_paths`. `/foo/bar.txt ==> 3: { "", "foo", "bar.txt" } (root dir counts as 1!!)`
---@return integer
function Path:len()
  return #self._raw_paths
end

---Concatenate paths. `Path.cwd() / "foo" / "bar.txt" == "./foo/bar.txt"`
---@param other PathlibPath | string
---@return PathlibPath
function Path:__div(other)
  if not utils.tables.is_path_module(self) and not utils.tables.is_path_module(other) then
    -- one of objects must be a path object
    errs.value_error("__div", other)
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
    errs.value_error("__concat", other)
  end
  return self.new(self:parent(), other)
end

---Convert path object to string
---@return string
function Path:__tostring()
  return self:tostring()
end

---Alias to `tostring(self)`. Returns the string representation of `self`.
---
---If you pass string to `vim.cmd`, use `self:cmd_string()` instead to avoid weird results.
---
---If you pass string to `vim.system` and other shell commands, use `self:shell_string()` instead.
---
---If you compare against LSP filepath, convert the LSP result with `Path.from_uri` compare path objects to avoid mismatch with escape sequence (eg '%3A').
---
---@param sep string|nil # If not nil, this is used as a path separator.
---@return string
function Path:tostring(sep)
  local nocache = sep and sep ~= self.sep_str
  if nocache or not self.__string_cache then
    local s = table.concat(self._raw_paths, self.sep_str)
    if self:is_absolute() then
      if #self._raw_paths == 1 then
        s = self.sep_str
      end
      if self._drive_name:len() > 0 then
        s = self._drive_name .. s
      end
    end
    if s:len() == 0 then
      return "."
    elseif nocache then
      return s
    else
      self.__string_cache = s
    end
  end
  return self.__string_cache
end

---Returns a string representation that is safe to pass to `vim.cmd`.
---@return PathlibString
function Path:cmd_string()
  local s = table.concat(vim.tbl_map(vim.fn.fnameescape, self._raw_paths), "/")
  if self._drive_name:len() > 0 then
    s = self._drive_name .. s
  end
  if s:len() > 0 then
    return "."
  end
  return s
end

---Returns a string representation that is safe to shell.
---
---Use this for `vim.fn.system`, `vim.system` etc.
---
---If result is passed to the `:!` command, set `special` to true.
---
---@param special boolean|nil # If true, special items such as "!", "%", "#" and "<cword>" will be preceded by a backslash. The backslash will be removed again by the |:!| command. See `:h shellescape` for more details. The <NL> character is escaped.
---@return PathlibString
function Path:shell_string(special)
  local s = table.concat(
    vim.tbl_map(function(t)
      return vim.fn.shellescape(t, special)
    end, self._raw_paths),
    "/"
  )
  if self._drive_name:len() > 0 then
    s = self._drive_name .. s
  end
  if s:len() > 0 then
    return "."
  end
  return s
end

--          ╭─────────────────────────────────────────────────────────╮          --
--          │                     Watcher Methods                     │          --
--          ╰─────────────────────────────────────────────────────────╯          --

---Register fs_event watcher for `self`.
---@param func_name string|nil # Name of the callback to check existence. If nil, returns whether any callback exists.
---@return boolean exists
function Path:has_watcher(func_name)
  if not self.__fs_event_callbacks then
    return false
  end
  if not func_name then
    for _, _ in pairs(self.__fs_event_callbacks) do
      return true
    end
    return false
  end
  return not not self.__fs_event_callbacks[func_name]
end

---Register fs_event watcher for `self`.
---@param func_name string # Name of the callback to prevent register same callback multiple time
---@param callback PathlibWatcherCallback # Callback passed to `luv.fs_event_start`
---@return boolean succeess
function Path:register_watcher(func_name, callback)
  self.__fs_event_callbacks = self.__fs_event_callbacks or {}
  self.__fs_event_callbacks[func_name] = callback
  local suc, err_msg = watcher.register(self)
  if suc ~= nil then
    return true
  else
    self.error_msg = err_msg
    return false
  end
end

---Unregister fs_event watcher for `self`.
---@param func_name string|nil # Name of the callback registered with `self:register(func_name, ...)`. If nil removes all.
---@return boolean succeess
function Path:unregister_watcher(func_name)
  if not self.__fs_event_callbacks then
    return true
  end
  if func_name then
    self.__fs_event_callbacks[func_name] = nil
    for _, _ in pairs(self.__fs_event_callbacks) do
      return true -- still has other callbacks
    end
  end
  self.__fs_event_callbacks = nil
  local suc, err_msg = watcher.unregister(self)
  if suc ~= nil then
    return true
  else
    self.error_msg = err_msg
    return false
  end
end

---Register fs_event watcher for `self`.
---@param func_name string|nil # Name of the callback to check existence. If nil, calls all watchers.
---@param args PathlibWatcherArgs
function Path:execute_watchers(func_name, args)
  if not self.__fs_event_callbacks then
    return
  end
  if func_name then
    if self.__fs_event_callbacks[func_name] then
      pcall(self.__fs_event_callbacks[func_name], self, args)
    end
  else
    for _, func in pairs(self.__fs_event_callbacks) do
      pcall(func, self, args)
    end
  end
end

---@alias PathlibString string # Specific annotation for result of `tostring(Path)`
---@alias PathlibPointer string # A unique id to each path object
---@alias PathlibAbsPath PathlibPath
---@alias PathlibRelPath PathlibPath

--          ╭─────────────────────────────────────────────────────────╮          --
--          │                    Deprecated Methods                   │          --
--          ╰─────────────────────────────────────────────────────────╯          --

---Alias to `vim.fs.dir` but returns PathlibPath objects.
---@deprecated # Use `self:fs_iterdir()` for better performance.
---@param opts table|nil Optional keyword arguments:
---             - depth: integer|nil How deep the traverse (default 1)
---             - skip: (fun(dir_name: string): boolean)|nil Predicate
---               to control traversal. Return false to stop searching the current directory.
---               Only useful when depth > 1
---
---@return fun(): PathlibPath|nil, string|nil # items in {self}. Each iteration yields two values: "path" and "type".
---        "path" is the PathlibPath object.
---        "type" is one of the following:
---        "file", "directory", "link", "fifo", "socket", "char", "block", "unknown".
function Path:iterdir(opts)
  local generator = fs.dir(self:tostring(), opts)
  return function()
    local name, fs_type = generator()
    if name ~= nil then
      return self:new_descendant(unpack(vim.split(name:gsub("\\", "/"), "/", { plain = true, trimempty = false }))),
        fs_type
    end
  end
end

---Iterate dir with `luv.fs_opendir`.
---@deprecated # Use `self:fs_scandir` instead for better performance.
---@param follow_symlinks boolean|nil # If true, resolves hyperlinks and go into the linked directory.
---@param depth integer|nil # How deep the traverse. If nil or <1, scans everything.
---@return function
function Path:fs_opendir(follow_symlinks, depth)
  depth = depth or -1
  ---@type (uv.aliases.fs_readdir_entries[]|nil)
  local entries = nil
  ---@type luv_dir_t|nil
  local handler = nil
  local current_dir, i_dir, i_ent = nil, 1, 0
  local dirs = { paths = { self }, depths = { 1 }, last_index = 1 }
  local function next_file()
    current_dir = dirs.paths[i_dir]
    if not current_dir then
      return nil
    end
    if not handler then
      handler = self.nuv.fs_opendir(current_dir:tostring(), nil, 100) --[[@as luv_dir_t]] ---@diagnostic disable-line
      entries, i_ent = nil, 0
      return handler and next_file()
    end
    if not entries or not entries[i_ent] then
      if i_ent == 1 then
        self.nuv.fs_closedir(handler)
        handler = nil
        i_dir = i_dir + 1
      else
        entries = self.nuv.fs_readdir(handler) ---@diagnostic disable-line
      end
      i_ent = 1
      return next_file()
    end
    local entry = entries[i_ent]
    i_ent = i_ent + 1
    local child = current_dir:child(entry.name)
    if follow_symlinks and entry.type == "link" then
      child = child:realpath() or child
      entry.type = (child:lstat() or { type = "file" }).type
    end
    if entry.type == "directory" and (depth < 0 or dirs.depths[i_dir] < depth) then
      dirs.last_index = dirs.last_index + 1
      dirs.paths[dirs.last_index] = child
      dirs.depths[dirs.last_index] = dirs.depths[i_dir] + 1
    end
    return child
  end
  return next_file
end

return Path
