describe("nvim-nio async calls;", function()
  describe("nvim-nio is installed.", function()
    it("require", function()
      local ok, mod = pcall(require, "nio")
      assert.is_true(ok)
      assert.is_not.is_nil(mod)
    end)
  end)

  local nio = require("nio")
  local Path = require("pathlib.posix")
  local const = require("pathlib.const")
  local file_content = "File Content\n"

  describe("`nio` works?", function()
    _G.it = it
    nio.tests.it("notifies listeners", function()
      local event = nio.control.event()
      local notified = 0
      for _ = 1, 10 do
        nio.run(function()
          event.wait()
          notified = notified + 1
        end)
      end

      event.set()
      nio.sleep(10)
      assert.equals(10, notified)
    end)
  end)

  describe("`nio` file system IO.", function()
    local path = Path("./tmp/nio.txt")
    it("mkdir", function()
      assert.is_true(path:parent():mkdir(const.o755, true))
    end)

    _G.it = it
    nio.tests.it("async read / write", function()
      assert.is_not.is_nil(path:fs_write(file_content))
      local read = path:fs_read()
      assert.is_not.is_nil(read)
      assert.is_equal(file_content, read)
    end)
  end)

  describe("`nio` updates error_msg.", function()
    local path = Path("./file/not/exists.txt")
    _G.it = it
    nio.tests.it("no exist file stat", function()
      assert.is_nil(path:stat(true))
      assert.is_true(type(path.error_msg) == "string")
      assert.is_true(path.error_msg:len() > 0)
    end)

    nio.tests.it("fail to async read / write", function()
      -- reset error_msg to check if it is udpated
      path.error_msg = file_content
      assert.is_nil(path:fs_write(file_content))
      assert.is_not.is_nil(path.error_msg)
      assert.is_true(path.error_msg:len() > 0)
      assert.is_not.is_equal(file_content, path.error_msg) -- error_msg is updated
    end)
  end)
end)
