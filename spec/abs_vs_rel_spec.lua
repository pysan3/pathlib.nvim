---@module 'busted'

local _ = require("pathlib")

describe("Absolute vs Relative Paths;", function()
  local Path = require("pathlib.base")
  local utils = require("pathlib.utils")

  describe("Make absolute path.", function()
    local check_list = {
      "/foo/bar.txt",
      "C:/foo/bar/txt",
      "D:\\foo\\bar.txt",
      "c:/foo/bar/txt",
      "z:\\foo\\bar.txt",
      "/a/b/c/d/e/f/g/h/i/j/k/l/n/m/o/p/q/r/s/t/u/v/w/x/y/z.txt",
    }
    for _, value in ipairs(check_list) do
      local foo = Path.new(value)
      it("is_absolute: " .. tostring(foo), function()
        assert.is_true(foo:is_absolute() or foo.__windows_panic)
      end)
    end

    local inverse_check_list = {
      "foo/bar.txt",
      "./foo/bar.txt",
      "../../foo/bar.txt",
      "c::/foo/bar.txt",
      "c::\\foo\\bar.txt",
    }
    for _, value in ipairs(inverse_check_list) do
      local foo = Path.new(value)
      it("NOT is_absolute: " .. value, function()
        assert.is_true(foo:is_relative() or foo.__windows_panic)
      end)
    end
  end)
end)
