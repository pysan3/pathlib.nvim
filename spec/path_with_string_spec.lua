local _ = require("pathlib")

describe("Compatibility Between Path and String;", function()
  local Path = require("pathlib.base")
  local utils = require("pathlib.utils")

  describe("Check string equals.", function()
    local foo = Path.new("foo.txt")
    local bar = Path.new("bar/foo.txt")
    it("single path, string.format", function()
      assert.is_equal(string.format([[%s]], foo), "foo.txt")
    end)
    it("single path, tostring", function()
      assert.is_equal(tostring(foo), "foo.txt")
    end)
    it("relative path, string.format", function()
      assert.is_equal(string.format([[%s]], bar), "bar/foo.txt")
    end)
    it("relative path, tostring", function()
      assert.is_equal(tostring(bar), "bar/foo.txt")
    end)
  end)

  describe("Filename Modifiers.", function()
    local cwd = vim.fn.getcwd()
    local bar = Path.new("src/version.c")
    local modifiers = {
      [":p"] = cwd .. "/src/version.c",
      [":p:."] = "src/version.c",
      [":h"] = "src",
      [":p:h"] = cwd .. "/src",
      [":p:h:h"] = cwd .. "",
      [":t"] = "version.c",
      [":p:t"] = "version.c",
      [":r"] = "src/version",
      [":p:r"] = cwd .. "/src/version",
      [":t:r"] = "version",
      [":e"] = "c",
      [":s?version?main?"] = "src/main.c",
      [":s?version?main?:p"] = cwd .. "/src/main.c",
    }
    for key, value in pairs(modifiers) do
      it(string.format("src/version.c `%s`", key), function()
        assert.is_equal(bar:modify(key), value)
      end)
    end
  end)
end)
