local luv = vim.loop
local _ = require("pathlib")
local const = require("pathlib.const")
local file_content = "File Content\n"

describe("Posix File Manipulation;", function()
  if const.IS_WINDOWS then
    return
  end

  local Path = require("pathlib.base")
  local foo = Path.new("./tmp/test_folder/foo.txt")
  local parent = foo:parent()
  if parent == nil then
    return
  end
  describe("parent", function()
    it("()", function()
      assert.is_equal("tmp/test_folder", tostring(parent))
      assert.is_not.is_nil(parent)
    end)
  end)

  describe("mkdir.", function()
    parent:mkdir(Path.permission("rwxr-xr-x"), true)
    it("exists()", function()
      assert.is_true(parent:exists())
      assert.is_not.is_nil(luv.fs_stat("./tmp/test_folder"))
    end)
    it("is_dir()", function()
      assert.is_true(parent:is_dir())
      local stat = luv.fs_stat("./tmp/test_folder")
      assert.is_not.is_nil(stat)
      ---@cast stat uv.aliases.fs_stat_table
      assert.is_equal("directory", stat.type)
    end)
  end)

  describe("foo:open", function()
    local fd, err_name, err_msg = foo:fs_open("w", Path.permission("rw-r--r--"), true)
    ---@cast fd integer
    it("()", function()
      assert.is_not.is_nil(fd)
      assert.is_nil(err_name)
      assert.is_nil(err_msg)
    end)
    it("exists()", function()
      assert.is_true(foo:is_file())
      local stat = luv.fs_stat("./tmp/test_folder/foo.txt")
      assert.is_not.is_nil(stat)
      ---@cast stat uv.aliases.fs_stat_table
      assert.is_equal("file", stat.type)
    end)
    it("write()", function()
      assert.is_equal(string.len(file_content), luv.fs_write(fd, file_content))
      assert.is_truthy(luv.fs_close(fd))
    end)
    it("read ()", function()
      assert.is_equal(file_content, foo:io_read())
    end)
  end)

  describe("io read / write", function()
    it("()", function()
      local suc, err_msg = foo:io_write(file_content)
      assert.is_true(suc)
      assert.is_nil(err_msg)
      assert.is_equal(file_content, foo:io_read())
    end)
  end)

  describe("iterdir", function()
    it("()", function()
      foo:copy(foo .. "bar.txt")
      foo:symlink_to(foo .. "baz.txt")
      local accum = {}
      for path in parent:iterdir() do
        table.insert(accum, path)
      end
      assert.is_equal(3, #accum)
    end)
  end)
end)
