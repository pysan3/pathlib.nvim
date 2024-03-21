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
  local Posix = require("pathlib.posix")
  local Windows = require("pathlib.windows")
  local foo = Posix.new("./folder/foo.txt")
  describe("__tostring", function()
    it("()", function()
      assert.are.equal(tostring(foo), "folder/foo.txt")
      assert.are_not.equal(tostring(foo), "/folder/foo.txt")
      local windows = Windows.new([[C:\hoge\fuga.txt]])
      assert.are.equal(tostring(windows), [[C:\hoge\fuga.txt]])
    end)
  end)

  describe("__eq", function()
    it("()", function()
      foo.__string_cache = nil
      assert.are.equal(foo, Posix.new("./folder/foo.txt")) -- "./" does not matter
      assert.are.equal(foo, Posix.new("folder/foo.txt"))
      assert.are_not.equal(foo, Posix.new("foo.txt"))
      assert.are_not.equal(foo, Posix.new("/folder/foo.txt"))
    end)
  end)

  describe("__lt", function()
    it("()", function()
      assert.is_true(foo < Posix.new("folder/foo.zzz"))
      assert.is_true(foo < Posix.new("folder/zzz"))
      assert.is_true(foo > foo:parent()) -- parent is always smaller
      assert.is_not_true(foo < foo)
      assert.is_not_true(foo < Posix.new("/folder/foo.txt")) -- compare path length
    end)
  end)

  describe("__le", function()
    it("()", function()
      assert.is_true(foo <= Posix.new("folder/foo.zzz"))
      assert.is_true(foo <= Posix.new("folder/zzz"))
      assert.is_true(foo >= foo:parent()) -- parent is always smaller
      assert.is_true(foo <= foo) -- __le contains itself
    end)
  end)

  describe("__div", function()
    it("()", function()
      assert.are.equal(foo, Posix.new(".") / "folder" / "foo.txt")
      assert.are.equal(foo, Posix.new("folder") / "foo.txt")
      assert.are.equal(foo, Posix.new(".") / Posix.new("./") / Posix.new("./folder") / "foo.txt")
      -- Path.new(".") many times is OK
    end)

    it("raise error", function()
      assert.has_error(function()
        return Posix.new(".") / {}
      end)
    end)
  end)

  describe("__concat", function()
    it("()", function()
      local sibling_file = Posix.new("./folder/baz.txt")
      assert.are.equal(foo, sibling_file .. "foo.txt")
      assert.are.equal(foo, sibling_file .. "./foo.txt")
      assert.are.equal(foo, sibling_file .. Posix.new("./foo.txt"))
    end)

    it("backwards compat", function()
      local path = Posix.new("./folder")
      assert.are.equal(foo, path .. "/foo.txt")
      assert.are.equal(foo, path .. "/" .. "foo.txt")
      assert.are.equal(foo, path .. "/" .. "./foo.txt")
      assert.are_not.equal(foo, path .. "foo.txt")
    end)

    it("raise error", function()
      assert.has_error(function()
        return Posix.new(".") / {}
      end)
    end)
  end)
end)
