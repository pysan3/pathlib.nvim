local Posix = require("pathlib.posix")
local Windows = require("pathlib.windows")

describe("Stem / Suffix Test", function()
  describe("stem", function()
    local test_table = {
      ["foo"] = {
        [[folder/foo.txt]],
        [[foo.txt]],
        [[foo.x]],
        [[/etc/foo.txt]],
        [[/etc/foo]],
        [[foo]],
      },
      ["my.awesome.file"] = { "my.awesome.file.png" },
      ["my.awesome.file."] = { "my.awesome.file." },
      ["my.awesome.file.."] = { "my.awesome.file...png" },
    }
    for expected, values in pairs(test_table) do
      for index, value in ipairs(values) do
        it(string.format([[%s: Path(%s):stem() == '%s']], index, value, expected), function()
          assert.are_equal(expected, Posix(value):stem())
          assert.are_equal(expected, Windows(value):stem())
        end)
      end
    end
  end)

  describe("invalid stem", function()
    local test_table = {
      ["foo"] = {
        [[foo.tar.gz]],
        [[foo.]],
        [[.foo.txt]],
      },
    }
    for expected, values in pairs(test_table) do
      for index, value in ipairs(values) do
        it(string.format([[%s: Path(%s):stem() ~= '%s']], index, value, expected), function()
          assert.are_not_equal(expected, Posix(value):stem())
          assert.are_not_equal(expected, Windows(value):stem())
        end)
      end
    end
  end)

  describe("suffix", function()
    local test_table = {
      [".txt"] = {
        [[folder/foo.txt]],
        [[foo.txt]],
        [[foo.bar.txt]],
        [[.......txt]],
      },
      [""] = {
        [[foo]],
        [[foo.]],
        "my.awesome.file.",
      },
      [".png"] = {
        "my.awesome.file.png",
        "my.awesome.file...png",
      },
    }
    for expected, values in pairs(test_table) do
      for index, value in ipairs(values) do
        it(string.format([[%s: Path(%s):suffix() == '%s']], index, value, expected), function()
          assert.are_equal(expected, Posix(value):suffix())
          assert.are_equal(expected, Windows(value):suffix())
        end)
      end
    end
  end)

  describe("invalid suffix", function()
    local test_table = {
      [".txt"] = { -- not
        [[foo.txt.]],
        [[.txt.zip]],
        [[.txt.]],
      },
      [".tar.gz"] = {
        [[foo.tar.gz]],
      },
    }
    for expected, values in pairs(test_table) do
      for index, value in ipairs(values) do
        it(string.format([[%s: Path(%s):suffix() ~= '%s']], index, value, expected), function()
          assert.are_not_equal(expected, Posix(value):suffix())
          assert.are_not_equal(expected, Windows(value):suffix())
        end)
      end
    end
  end)

  describe("with_stem", function()
    local test_table = { -- from, stem, to
      { "folder/foo.txt", "bar", "folder/bar.txt" },
      { "folder/foo.txt", ".txt", "folder/.txt.txt" },
      { "foo.tar", "foo.tar", "foo.tar.tar" },
      { "foo.tar.gz", "foo", "foo.gz" },
      { "foo.png", "bar", "bar.png" },
      { ".bashrc", ".zshrc", ".zshrc.bashrc" },
      { "foo", "bar", "bar" },
      { "foo.txt", "", ".txt" },
      { "my.awesome.file.png", "", ".png" },
      { "my.awesome.file.", "", "" },
      { "my.awesome.file.png", ".", "..png" },
      { "my.awesome.file...png", "", ".png" },
    }
    for _, test in ipairs(test_table) do
      local a, stem, b = unpack(test)
      it(string.format("%s - '%s' -> %s", a, stem, b), function()
        assert.are_equal(Posix(b), Posix(a):with_stem(stem))
        assert.are_equal(Windows(b), Windows(a):with_stem(stem))
      end)
    end
  end)

  describe("with_suffix", function()
    local test_table = { -- from, suffix, to
      { "folder/foo.txt", ".png", "folder/foo.png" },
      { "folder/foo.txt", ".txt", "folder/foo.txt" },
      { "foo.tar", ".zip", "foo.zip" },
      { "foo.tar.gz", ".zip", "foo.tar.zip" },
      { "foo.png", ".tar.gz", "foo.tar.gz" },
      { ".bashrc", ".zshrc", ".zshrc" },
      { "foo", ".zip", "foo.zip" },
      { "foo.txt", "", "foo" },
      { "my.awesome.file.png", "", "my.awesome.file" },
      { "my.awesome.file.", "", "my.awesome.file." },
      { "my.awesome.file.png", ".txt", "my.awesome.file.txt" },
      { "my.awesome.file...png", "", "my.awesome.file.." },
    }
    for _, test in ipairs(test_table) do
      local a, suffix, b = unpack(test)
      it(string.format("%s - '%s' -> %s", a, suffix, b), function()
        assert.are_equal(Posix(b), Posix(a):with_suffix(suffix))
        assert.are_equal(Windows(b), Windows(a):with_suffix(suffix))
      end)
    end
  end)

  describe("add_suffix", function()
    local test_table = { -- from, suffix, to
      { "folder/foo.txt", ".png", "folder/foo.txt.png" },
      { "folder/foo.txt", ".txt", "folder/foo.txt" },
      { "foo.txt.bak", ".bak", "foo.txt.bak" },
      { "foo.tar", ".zip", "foo.tar.zip" },
      { "foo.tar.gz", ".zip", "foo.tar.gz.zip" },
      { "foo.png", ".tar.gz", "foo.png.tar.gz" },
      { ".bashrc", ".zshrc", ".bashrc.zshrc" },
      { "foo", ".zip", "foo.zip" },
      { "foo.txt", "", "foo.txt" },
      { "my.awesome.file.png", "", "my.awesome.file.png" },
      { "my.awesome.file.", "", "my.awesome.file." },
      { "my.awesome.file.png", ".txt", "my.awesome.file.png.txt" },
      { "my.awesome.file...png", ".png", "my.awesome.file...png" },
    }
    for _, test in ipairs(test_table) do
      local a, suffix, b = unpack(test)
      it(string.format("%s - '%s' -> %s", a, suffix, b), function()
        assert.are_equal(Posix(b), Posix(a):add_suffix(suffix))
        assert.are_equal(Windows(b), Windows(a):add_suffix(suffix))
      end)
    end
  end)
end)
