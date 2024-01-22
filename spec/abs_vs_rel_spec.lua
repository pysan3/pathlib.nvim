local _ = require("pathlib")

describe("Absolute vs Relative Paths;", function()
  local Posix = require("pathlib.posix")
  local Windows = require("pathlib.windows")
  local utils = require("pathlib.utils")

  describe("Make Posix absolute path.", function()
    local check_list = {
      "/foo/bar.txt",
      "/a/b/c/d/e/f/g/h/i/j/k/l/n/m/o/p/q/r/s/t/u/v/w/x/y/z.txt",
    }
    for _, value in ipairs(check_list) do
      local foo = Posix.new(value)
      it("is_absolute: " .. value .. " -> " .. tostring(foo), function()
        assert.is_true(foo:is_absolute())
      end)
    end
  end)

  describe("Make Windows absolute path.", function()
    local check_list = {
      [[C:/foo/bar/txt]],
      [[D:\foo\bar.txt]],
      [[c:/foo/bar/txt]],
      [[z:\foo\bar.txt]],
      -- TODO: Network storage paths are not supported yet
      -- https://github.com/neovim/neovim/issues/27068
      -- [[\\127.0.0.1\foo\bar.txt]],
      -- [[\\wsl$\foo\bar.txt]],
    }
    for _, value in ipairs(check_list) do
      local foo = Windows.new(value)
      it("is_absolute: " .. value .. " -> " .. tostring(foo), function()
        assert.is_true(foo:is_absolute())
      end)
    end
  end)

  describe("Make Posix absolute path.", function()
    local inverse_check_list = {
      "foo/bar.txt",
      "./foo/bar.txt",
      "../../foo/bar.txt",
    }
    for _, value in ipairs(inverse_check_list) do
      local foo = Posix.new(value)
      it("NOT is_absolute: " .. value, function()
        assert.is_true(foo:is_relative())
      end)
    end
  end)

  describe("Make Windows absolute path.", function()
    local inverse_check_list = {
      "foo/bar.txt",
      "./foo/bar.txt",
      "../../foo/bar.txt",
      "c::/foo/bar.txt",
      "c::\\foo\\bar.txt",
    }
    for _, value in ipairs(inverse_check_list) do
      local foo = Windows.new(value)
      it("NOT is_absolute: " .. value, function()
        assert.is_true(foo:is_relative())
      end)
    end
  end)
end)
