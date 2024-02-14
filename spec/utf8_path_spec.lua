local luv = vim.loop
local _ = require("pathlib")
local file_content = "File Content\n"

describe("Utf8 Filename Manipulation;", function()
  local Path = require("pathlib")
  local foo = Path.new("./ｔｍｐ/ｔｅｓｔ＿ｆｏｌｄｅｒ/ｆｏｏ.ｔｘｔ") -- these are non-ascii characters
  local parent = foo:parent()
  if parent == nil then
    return
  end
  describe("parent", function()
    it("()", function()
      assert.are.equal("ｔｍｐ/ｔｅｓｔ＿ｆｏｌｄｅｒ", tostring(parent))
      assert.is_not.is_nil(parent)
    end)
  end)

  describe("mkdir.", function()
    parent:mkdir(Path.permission("rwxr-xr-x"), true)
    it("exists()", function()
      assert.is_true(parent:exists())
      assert.is_not.is_nil(luv.fs_stat("./ｔｍｐ/ｔｅｓｔ＿ｆｏｌｄｅｒ"))
    end)
    it("is_dir()", function()
      assert.is_true(parent:is_dir())
      local stat = luv.fs_stat("./ｔｍｐ/ｔｅｓｔ＿ｆｏｌｄｅｒ")
      assert.is_not.is_nil(stat)
      ---@cast stat uv.aliases.fs_stat_table
      assert.are.equal("directory", stat.type)
    end)
  end)

  describe("foo:open", function()
    local fd = foo:fs_open("w", Path.permission("rw-r--r--"), true)
    ---@cast fd integer
    it("()", function()
      assert.is_not.is_nil(fd)
      assert.is_nil(foo.error_msg)
    end)
    it("exists()", function()
      assert.is_true(foo:is_file())
      local stat = luv.fs_stat("./ｔｍｐ/ｔｅｓｔ＿ｆｏｌｄｅｒ/ｆｏｏ.ｔｘｔ")
      assert.is_not.is_nil(stat)
      ---@cast stat uv.aliases.fs_stat_table
      assert.are.equal("file", stat.type)
    end)
    it("write()", function()
      assert.are.equal(string.len(file_content), luv.fs_write(fd, file_content))
      assert.is_truthy(luv.fs_close(fd))
    end)
    it("read ()", function()
      assert.are.equal(file_content, foo:io_read())
    end)
  end)

  describe("io read / write", function()
    it("()", function()
      local suc = foo:io_write(file_content)
      assert.is_true(suc)
      assert.is_nil(foo.error_msg)
      assert.are.equal(file_content, foo:io_read())
    end)
  end)

  describe("iterdir", function()
    it("()", function()
      foo:copy(foo .. "ｂａｒ.ｔｘｔ")
      foo:symlink_to(foo .. "ｂａｚ.ｔｘｔ")
      local accum = {}
      for path in parent:iterdir() do
        table.insert(accum, path)
      end
      assert.are.equal(3, #accum)
    end)
  end)
end)
