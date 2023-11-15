-- `dunder` means _double under_, the methods that start with `__` such as `__eq()`
local _ = require("pathlib")

-- NOTE: List of unimplemented dunder methods
-- __add
-- __sub
-- __mul
-- __div
-- __mod
-- __pow
-- __unm
-- __idev
-- __band
-- __bor
-- __bxor
-- __bnot
-- __shl
-- __shr

describe("Test Dunder Methods of Path Object;", function()
  local Path = require("pathlib.base")
  local foo = Path.new("./folder/foo.txt")
  describe("__tostring", function()
    it("()", function()
      assert.is_equal(tostring(foo), "folder/foo.txt")
      assert.is_not.is_equal(tostring(foo), "/folder/foo.txt")
      local windows = Path.new([[C:\hoge\fuga.txt]])
      assert.is_equal(tostring(windows), [[C:/hoge/fuga.txt]])
    end)
  end)

  describe("__eq", function()
    it("()", function()
      assert.is_equal(foo, Path.new("./folder/foo.txt")) -- "./" does not matter
      assert.is_equal(foo, Path.new("folder/foo.txt"))
      assert.is_not.is_equal(foo, Path.new("foo.txt"))
      assert.is_not.is_equal(foo, Path.new("/folder/foo.txt"))
    end)
  end)

  describe("__lt", function()
    it("()", function()
      assert.is_true(foo < Path.new("folder/foo.zzz"))
      assert.is_true(foo < Path.new("folder/zzz"))
      assert.is_true(foo > foo:parent()) -- parent is always smaller
      assert.is_not_true(foo < foo)
      assert.is_not_true(foo < Path.new("/folder/foo.txt")) -- compare path length
    end)
  end)

  describe("__le", function()
    it("()", function()
      assert.is_true(foo <= Path.new("folder/foo.zzz"))
      assert.is_true(foo <= Path.new("folder/zzz"))
      assert.is_true(foo >= foo:parent()) -- parent is always smaller
      assert.is_true(foo <= foo) -- __le contains itself
    end)
  end)

  describe("__div", function()
    it("()", function()
      assert.is_equal(foo, Path.new(".") / "folder" / "foo.txt")
      assert.is_equal(foo, Path.new("folder") / "foo.txt")
      assert.is_equal(foo, Path.new(".") / Path.new("./") / Path.new("./folder") / "foo.txt")
      -- Path.new(".") many times is OK
    end)

    it("raise error", function()
      assert.has_error(function()
        return Path.new(".") / {}
      end)
    end)
  end)

  describe("__concat", function()
    it("()", function()
      local sibling_file = Path.new("./folder/baz.txt")
      assert.is_equal(foo, sibling_file .. "foo.txt")
      assert.is_equal(foo, sibling_file .. "./foo.txt")
      assert.is_equal(foo, sibling_file .. Path.new("./foo.txt"))
    end)

    it("raise error", function()
      assert.has_error(function()
        return Path.new(".") / {}
      end)
    end)
  end)
end)
