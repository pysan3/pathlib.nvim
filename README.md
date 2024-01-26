<div align="center">
  <h1>🐍 pathlib.nvim</h1>
  <p>
    <strong>
      OS independent, ultimate solution to path handling in neovim.
    </strong>
  </p>
</div>

❗ **This is still very WIP. Will be available in February at the
earliest.**

[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org/)

[![MLP-2.0](https://img.shields.io/github/license/pysan3/pathlib.nvim.svg?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/blob/master/LICENSE)
[![Issues](https://img.shields.io/github/issues/pysan3/pathlib.nvim.svg?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/issues)
[![Build
Status](https://img.shields.io/github/actions/workflow/status/pysan3/pathlib.nvim/lua_ls-typecheck.yml?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/actions/workflows/lua_ls-typecheck.yml)
[![LuaRocks](https://img.shields.io/luarocks/v/pysan3/pathlib.nvim?logo=lua&color=purple&style=for-the-badge)](https://luarocks.org/modules/pysan3/pathlib.nvim)

# 🐍 `pathlib.nvim`

This plugin aims to decrease the difficulties of path management across
mutliple OSs in neovim. The plugin API is heavily inspired by Python's
`pathlib.Path` with tweaks to fit neovim usage. It is mainly used in
[neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) but it
is very simple and portable to be used in any plugin.

# Usage Example

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

-- Create siblings (just like `./<foo>/../bar.txt`)
local bar = foo .. "bar.txt"
assert(tostring(bar)          == "folder/bar.txt")
```

## Create and Manipulate Files / Directories

``` lua
local luv = vim.loop
local Path = require("pathlib")

-- Create new folder
local new_file = Path.new("./new/folder/foo.txt")
new_file:parent():mkdir(Path.permission("rwxr-xr-x"), true) -- (permission, recursive)

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

new_file:copy(new_file .. "bar.txt") -- copy `foo.txt` to `bar.txt`
new_file:symlink_to(new_file .. "baz.txt") -- create symlink of `foo.txt` named `baz.txt`
```

## Scan Directories

``` lua
-- Continue from above
for path in new_file:parent():iterdir() do
  -- loop: [Path("./new/folder/foo.txt"), Path("./new/folder/bar.txt"), Path("./new/folder/baz.txt")]
end
```

## Async Execution

This library uses [nvim-nio](https://github.com/nvim-neotest/nvim-nio)
under the hood to run async calls. Supported methods will turn into
async calls inside a `nio.run` environment and has the **EXACT SAME
INTERFACE**.

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

When execution fails, function will return `nil` and the error message
is captured into `self.error_msg`. This property holds the error message
of the latest async function call.

``` lua
nio.run(function ()
  local path = Path("./does/not/exist.txt")
  local fd = path:fs_open("r")
  assert(not fd, "fs_open failed. ERROR: " .. path.error_msg)
  -- fd will be nil when `:fs_open` fails. Check `self.error_msg` for the error message.
end)
```

# TODO

- [ ] API documentation.

- [ ] Git operation integration.

- [ ] Windows implementation, test environment.

# Contributions

I am not thinking of merging any PRs yet but feel free to give me your
opinions with an issue.

# Other Projects

- Python `pathlib`

  - <https://docs.python.org/3/library/pathlib.html>
