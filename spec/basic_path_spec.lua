local _ = require("pathlib")

describe("Simple PathlibPath test;", function()
  describe("Import test.", function()
    it("import test:", function()
      local path_ok, Path = pcall(require, "pathlib.base")
      assert.is_true(path_ok)
      assert.is_not_nil(Path)

      local utils_ok, utils = pcall(require, "pathlib.utils")
      assert.is_true(utils_ok)
      assert.is_not_nil(utils)
    end)
  end)

  describe("Relative init.", function()
    local Path = require("pathlib")
    local utils = require("pathlib.utils")

    it("single argument", function()
      local path = Path.new(".")
      assert.is_true(utils.tables.is_type_of(path, "PathlibPath"))
      assert.are_same(path._raw_paths, {})
    end)
  end)

  describe("Object is not shared.", function()
    local Path = require("pathlib")

    local path1 = Path.new("a")
    local path2 = Path.new("b")

    for key, value in pairs(path1) do
      if type(value) == "table" then
        it("check " .. key, function()
          assert.are_not_same(path1[key], path2[value])
        end)
      end
    end
  end)
end)
