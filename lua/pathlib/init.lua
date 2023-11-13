---@toc pathlib.contents

---@mod intro Introduction
---@brief [[
---This plugin aims to decrease the difficulties of path management across mutliple OSs.
---The plugin API is heavily inspired by Python's `pathlib.Path` with tweaks to fit neovim usage.
---It is mainly used in {https://github.com/nvim-neo-tree/neo-tree.nvim}[neo-tree.nvim]
---but it is as simple as you can use it in your own configs!
---
---@brief ]]

---@mod pathlib The pathlib module
---@brief [[
---Entry-point into this plugin's public API.
---
---Example:
--->lua
------@type PathlibPath
---local Path = require("pathlib")
---<
---@brief ]]

IS_WINDOWS = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1

if IS_WINDOWS then
  return require("pathlib.windows")
else
  return require("pathlib.posix")
end
