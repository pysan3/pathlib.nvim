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
      assert.are.equal("folder/foo.txt", tostring(foo))
      assert.are_not.equal("/folder/foo.txt", tostring(foo))
      local windows = Windows.new([[C:\hoge\fuga.txt]])
      assert.are.equal([[C:\hoge\fuga.txt]], tostring(windows))
    end)
  end)

  describe("__eq", function()
    it("()", function()
      foo.__string_cache = nil
      assert.are.equal(Posix.new("./folder/foo.txt"), foo) -- "./" does not matter
      assert.are.equal(Posix.new("folder/foo.txt"), foo)
      assert.are_not.equal(Posix.new("foo.txt"), foo)
      assert.are_not.equal(Posix.new("/folder/foo.txt"), foo)
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
      assert.are.equal(Posix.new(".") / "folder" / "foo.txt", foo)
      assert.are.equal(Posix.new("folder") / "foo.txt", foo)
      assert.are.equal(Posix.new(".") / Posix.new("./") / Posix.new("./folder") / "foo.txt", foo)
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
      local file = Posix.new("./folder")
      assert.are.equal("folder/foo/bar", file .. "/foo/bar")
      assert.are.equal(file .. "/foo/bar", tostring(file) .. "/foo/bar")
    end)

    it("raise error", function()
      assert.has_error(function()
        return Posix.new(".") .. {}
      end)
    end)
  end)
end)
