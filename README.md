<div align="center">
  <h1>🐍 pathlib.nvim</h1>
  <p>
    <strong>
      OS Independent, ultimate solution to path handling in neovim.
    </strong>
  </p>
</div>

# 🐍 `pathlib.nvim`

This plugin aims to decrease the difficulties of path management across
mutliple OSs in neovim. The plugin API is heavily inspired by Python's
`pathlib.Path` with tweaks to fit neovim usage. It is mainly used in
[neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) but it
is very simple and portable to be used in any plugin.

❗ **This is still very WIP. Will be available in February at the
earliest.**

[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org/)

[![MLP-2.0](https://img.shields.io/github/license/pysan3/pathlib.nvim.svg?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/blob/master/LICENSE)
[![Issues](https://img.shields.io/github/issues/pysan3/pathlib.nvim.svg?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/issues)
[![Build
Status](https://img.shields.io/github/actions/workflow/status/pysan3/pathlib.nvim/lua_ls-typecheck.yml?style=for-the-badge)](https://github.com/pysan3/pathlib.nvim/actions/workflows/lua_ls-typecheck.yml)
[![LuaRocks](https://img.shields.io/luarocks/v/pysan3/pathlib.nvim?logo=lua&color=purple&style=for-the-badge)](https://luarocks.org/modules/pysan3/pathlib.nvim)

# Usage Example

## Create Path Object

``` lua
local Path = require("pathlib.base")

local cwd = Path.cwd()
local folder = cwd / "folder" -- use __div to chain file tree!
local foo = folder / "foo.txt"
assert(tostring(foo) == "folder/foo.txt")
assert(foo == Path("./folder/foo.txt")) -- Path object can be created with arguments
assert(foo == Path(folder, "foo.txt")) -- Unpack any of them if you want!
assert(tostring(foo:parent()) == "folder")

local bar = foo .. "bar.txt" -- create siblings (just like `./<foo>/../bar.txt`)
assert(tostring(bar) == "folder/bar.txt")
```

## Create and Manipulate Files / Directories

``` lua
local luv = vim.loop
local Path = require("pathlib.base")

local new_file = Path.new("./new/folder/foo.txt")
new_file:parent():mkdir(Path.permission("rwxr-xr-x"), true) -- (permission, recursive)

-- You don't need above line if you specify recursive = true in `open`; all parents will be created
local fd, err_name, err_msg = new_file:open("w", Path.permission("rw-r--r--"), true)
assert(fd ~= nil, "File creation failed. " .. err_name .. err_msg)
luv.fs_write(fd, "File Content\n")
luv.fs_close(fd)

local content = new_file:read(0)
assert(content == "File Content\n")

new_file:copy(new_file .. "bar.txt")
new_file:symlink_to(new_file .. "baz.txt")
```

## Scan Directories

``` lua
-- Continue from above
for path in new_file:parent():iterdir() do
    -- path will be [Path("./new/folder/foo.txt"), Path("./new/folder/bar.txt"), Path("./new/folder/baz.txt")]
end

-- fs_scandir-like usage
new_file:parent():iterdir_async(function(path, fs_type) -- callback on all files
    vim.print(tostring(path), fs_type)
end, function(error) -- on error
    vim.print("Error: " .. error)
end, function(count) -- on exit
    vim.print("Scan Finished. " .. count .. " files found.")
end)
```

# TODO

- API documentation

- Windows implementation, test environment.

# Contributions

I am not thinking of merging any PRs yet but feel free to give me your
opinions with an issue.

# Other Projects

- Python `pathlib`

  - <https://docs.python.org/3/library/pathlib.html>
