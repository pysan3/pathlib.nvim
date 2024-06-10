<div align="center">
  <h1>🐍 pathlib.nvim</h1>
  <p>
    <strong>
      OS independent, ultimate solution to path handling in neovim.
    </strong>
  </p>
</div>

[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/) [![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org/)

[![MLP-2.0](https://img.shields.io/github/license/pysan3/pathlib.nvim.svg?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/blob/master/LICENSE) [![Issues](https://img.shields.io/github/issues/pysan3/pathlib.nvim.svg?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/issues) [![Build Status](https://img.shields.io/github/actions/workflow/status/pysan3/pathlib.nvim/lua_ls-typecheck.yml?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/actions/workflows/lua_ls-typecheck.yml) [![LuaRocks](https://img.shields.io/luarocks/v/pysan3/pathlib.nvim?logo=lua&color=purple&style=for-the-badge)](https://luarocks.org/modules/pysan3/pathlib.nvim)

# 🐍 `pathlib.nvim`

This plugin aims to decrease the difficulties of path management across mutliple OSs in neovim. The plugin API is heavily inspired by Python's `pathlib.Path` with tweaks to fit neovim usage.

- [Documentation](https://pysan3.github.io/pathlib.nvim/)
- Module References
  - [`PathlibPath`](https://pysan3.github.io/pathlib.nvim/doc/PathlibPath.html): base class with operations.
  - [`PathlibPosixPath`](https://pysan3.github.io/pathlib.nvim/doc/PathlibPosixPath.html): posix system specific.
  - [`PathlibWindowsPath`](https://pysan3.github.io/pathlib.nvim/doc/PathlibWindowsPath.html): posix system specific.
- 🔎 Search for Keyword
  - [Search](https://pysan3.github.io/pathlib.nvim/search.html)
  - [Index](https://pysan3.github.io/pathlib.nvim/genindex.html)

# ✨ Benefits

## 📦 Intuitive and Useful Methods

``` lua
local Path = require("pathlib")
local dir = Path("~/Documents") -- Same as `Path.home() / "Documents"`
local foo = dir / "foo.txt"

print(foo:basename(), foo:stem(), foo:suffix()) -- foo.txt, foo, .txt
print(foo:parent()) -- "/home/user/Documents"
```

## 📋 Git Integration

``` lua
local git_root = Path("/path/to/git/workdir")
assert(git_root:child(".git"):exists(), string.format("%s is not a git repo.", git_root))

require("pathlib.git").fill_git_state({ file_a, file_b, ... })

file_a.git_state.ignored  -- is git ignored
file_a.git_state.status   -- git status (modified, added, staged, ...)
file_a.git_state.git_root -- root directory of the repo
```

## ⏱️ Sync / Async Operations

The API is designed so it is very easy to switch between sync and async operations. Call them inside a [nvim-nio async context](https://github.com/nvim-neotest/nvim-nio) without any change, and the operations are converted to be async (does not block the main thread).

``` lua
local foo = Path("~/Documents/foo.txt")
local content = "File Content\n"

-- # sync
local sync_bytes = foo:fs_write(content)
assert(sync_bytes == content:len(), foo.error_msg)

-- # async
require("nio").run(function()
  local async_bytes = foo:fs_write(content)
  assert(async_bytes == content:len(), foo.error_msg)
end)
```

# 🚀 Usage Example

## Create Path Object

``` lua
local Path = require("pathlib")
local cwd     = Path.cwd()
vim.print(string.format([[cwd: %s]], cwd))

-- Use __div to chain file tree!
local folder  = Path(".") / "folder"
local foo     =              folder / "foo.txt"
assert(tostring(foo)          == "folder/foo.txt") -- $PWD/folder/foo.txt
assert(tostring(foo:parent()) == "folder")

-- Path object is comparable
assert(foo                    == Path("./folder/foo.txt")) -- Path object can be created with arguments
assert(foo                    == Path(folder, "foo.txt"))  -- Unpack any of them if you want!

-- Calculate relativily
assert(foo:is_relative_to(Path("folder")))
assert(not foo:is_relative_to(Path("./different folder")))
assert(foo:relative_to(folder) == Path("foo.txt"))
```

### Path object is stored with `string[]`.

- Very fast operations to work with parents / children / siblings.
- No need to worry about path separator =\> OS Independent.
  - `/`: Unix, `\`: Windows

### Nicely integrated with vim functions.

There are wrappers around vim functions such as `fnamemodify`, `stdpath` and `getcwd`.

``` lua
path:modify(":p:t:r")                -- vim.fn.fnamemodify

-- Define child directory of stdpaths
Path.stdpath("data", "mason", "bin") -- vim.fn.stdpath("data") .. "/mason/bin"
```

## Create and Manipulate Files / Directories

``` lua
local luv = vim.loop
local Path = require("pathlib")

-- Create new folder
local new_file = Path.new("./new/folder/foo.txt")
new_file:parent_assert():mkdir(Path.permission("rwxr-xr-x"), true) -- (permission, recursive)

-- Create new file and write to it
local fd = new_file:fs_open("w", Path.permission("rw-r--r--"), true)
assert(fd ~= nil, "File creation failed. " .. new_file.error_msg)
luv.fs_write(fd, "File Content\n")
luv.fs_close(fd)
-- HINT: new_file:fs_write(...) does this all at once.

-- SHORTHAND: read file content with `io.read`
local content = new_file:io_read()
assert(content == "File Content\n")

-- SHORTHAND: write to file
new_file:io_write("File Content\n")

new_file:copy(new_file:with_basename("bar.txt")) -- copy `foo.txt` to `bar.txt`
new_file:symlink_to(new_file:with_basename("baz.txt")) -- create symlink of `foo.txt` named `baz.txt`
```

## Scan Directories

``` lua
-- Continue from above
for path in new_file:parent_assert():fs_iterdir() do
  -- loop: [Path("./new/folder/foo.txt"), Path("./new/folder/bar.txt"), Path("./new/folder/baz.txt")]
end
```

## Async Execution

This library uses [nvim-nio](https://github.com/nvim-neotest/nvim-nio) under the hood to run async calls. Supported methods will turn into async calls inside a `nio.run` async context and has the **EXACT SAME INTERFACE**.

``` lua
local nio = require("nio")
local path = Path("foo.txt")
nio.run(function() -- async run (does not block the main thread)
  vim.print(path:fs_stat())       -- coroutine (async)
  path:fs_write("File Content\n") -- coroutine (async)
  vim.print(path:fs_read())       -- coroutine (async)
  vim.print("async done")         -- prints last
end)

vim.print("sync here") -- prints first (maybe not if above functions end very fast)
```

When execution fails, function will return `nil` and the error message is captured into `self.error_msg`. This property holds the error message of the latest async function call.

``` lua
nio.run(function ()
  local path = Path("./does/not/exist.txt")
  local fd = path:fs_open("r")
  assert(fd, "ERROR: " .. path.error_msg)
  -- fd will be nil when `:fs_open` fails. Check `self.error_msg` for the error message.
end)
```

# TODO

- [x] API documentation.
  - [x] PathlibPath
  - [x] PathlibPosixPath
  - [x] PathlibWindowsPath
  - [x] Git
- [x] Git operation integration.
- [ ] Git test suite.
  - [ ] List out every possible git state: ignored, staged etc.
  - [ ] Create file for each state.
  - [ ] Add docs for each state: `man git-diff -> RAW OUTPUT FORMAT`
- [ ] Windows implementation, test environment.
  - [ ] Create a CI/CD action to run on windows.
  - [ ] Prepare windows specific test suite.

# Contributions

I'll happily accept any [feature request](https://github.com/pysan3/pathlib.nvim/issues/new?assignees=&labels=feature&projects=&template=feature_request.yml) Feel free to ask for any functionality :)

# Other Projects

- Python `pathlib`
  - <https://docs.python.org/3/library/pathlib.html>
