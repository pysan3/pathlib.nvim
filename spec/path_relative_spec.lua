describe("Test Relative Path Detection and Generation", function()
  local Posix = require("pathlib.posix")
  local Windows = require("pathlib.windows")
  local relp = Posix.new("./folder/foo.txt")
  local parent_relp = Posix.new("./folder")
  local absp = Posix.new("/etc/passwd")
  local parent_absp = Posix.new("/etc")
  local relw = Windows.new("./folder/foo.txt")
  local parent_relw = Windows.new("./folder")
  local absw = Windows.new("C:/foo/bar.txt")
  local parent_absw = Windows.new("C:/foo")

  describe("is_relative", function()
    it("()", function()
      assert.is_true(relp:is_relative())
      assert.is_not_true(absp:is_relative())
      assert.is_not_true(Posix.cwd():is_relative())
    end)
  end)

  describe("is_absolute", function()
    it("()", function()
      assert.is_not_true(relp:is_absolute())
      assert.is_true(absp:is_absolute())
      assert.is_true(Posix.cwd():is_absolute())
    end)
  end)

  describe("is_relative_to", function()
    it("vs parent", function()
      local parent = relp:parent()
      assert.is_not_nil(parent)
      assert.is_true(parent and relp:is_relative_to(parent))
    end)
    it("vs string posix", function()
      assert.is_true(relp:is_relative_to("folder"))
      assert.is_true(relp:is_relative_to("folder/"))
      assert.is_not_true(relp:is_relative_to([[folder\]]))
    end)
    it("vs string windows", function()
      assert.is_true(relw:is_relative_to("folder"))
      assert.is_not_true(relw:is_relative_to("folder/"))
      assert.is_true(relw:is_relative_to([[folder\]]))
    end)
    it("vs string posix absolute", function()
      assert.is_true(absp:is_relative_to("/etc"))
      assert.is_not_true(absp:is_relative_to("/usr"))
    end)
    it("vs string windows absolute", function()
      assert.is_true(absw:is_relative_to([[C:\]]))
      assert.is_not_true(absw:is_relative_to([[C:/]]))
      assert.is_true(absw:is_relative_to([[C:\foo\]]))
      assert.is_not_true(absw:is_relative_to([[C:/foo/]]))
    end)
    it("vs parent posix absolute", function()
      assert.is_true(absp:is_relative_to(absp:parent())) ---@diagnostic disable-line
      assert.is_true(absp:is_relative_to(absp:parent_string())) ---@diagnostic disable-line
    end)
    it("vs parent windows absolute", function()
      assert.is_true(absw:is_relative_to(absw:parent())) ---@diagnostic disable-line
      assert.is_true(absw:is_relative_to(absw:parent_string())) ---@diagnostic disable-line
    end)
  end)

  describe("relative_to", function()
    it("works", function()
      assert.is_not_nil(relp:relative_to(parent_relp))
      assert.is_not_nil(absp:relative_to(parent_absp))
      assert.is_not_nil(relw:relative_to(parent_relw))
      assert.is_not_nil(absw:relative_to(parent_absw))
    end)
    it("return is relative", function()
      assert.is_true(relp:relative_to(parent_relp):is_relative()) ---@diagnostic disable-line
      assert.is_true(absp:relative_to(parent_absp):is_relative()) ---@diagnostic disable-line
      assert.is_true(relw:relative_to(parent_relw):is_relative()) ---@diagnostic disable-line
      assert.is_true(absw:relative_to(parent_absw):is_relative()) ---@diagnostic disable-line
    end)
    it("validate return value", function()
      assert.are.equal("foo.txt", relp:relative_to(parent_relp):tostring()) ---@diagnostic disable-line
      assert.are.equal(relp:basename(), relp:relative_to(parent_relp):tostring()) ---@diagnostic disable-line
      assert.are.equal(relp.new(relp:basename()), relp:relative_to(parent_relp)) ---@diagnostic disable-line
      assert.are.equal(absp:basename(), absp:relative_to(parent_absp):tostring()) ---@diagnostic disable-line
      assert.are.equal(absp.new(absp:basename()), absp:relative_to(parent_absp)) ---@diagnostic disable-line
      assert.are.equal(relw:basename(), relw:relative_to(parent_relw):tostring()) ---@diagnostic disable-line
      assert.are.equal(relw.new(relw:basename()), relw:relative_to(parent_relw)) ---@diagnostic disable-line
      assert.are.equal(absw:basename(), absw:relative_to(parent_absw):tostring()) ---@diagnostic disable-line
      assert.are.equal(absw.new(absw:basename()), absw:relative_to(parent_absw)) ---@diagnostic disable-line
    end)
  end)

  describe("relative_to invalid parents", function()
    local errs = {
      NOT_SUBPATH = "not in the subpath of",
      ONE_IS_REL = "one path is relative",
      ANOTHER_DISK = "not on the same disk",
    }
    local tests = {
      { absp, "/usr", errs.NOT_SUBPATH },
      { absp, relp, errs.ONE_IS_REL },
      { relp, absp, errs.ONE_IS_REL },
      { relp, "bar", errs.NOT_SUBPATH },
      { relp, "baz/baz", errs.NOT_SUBPATH },
      { absw, relw, errs.ONE_IS_REL },
      { relw, absw, errs.ONE_IS_REL },
      { absw, "D:/foo", errs.ANOTHER_DISK },
      { absw, "C:/bar", errs.NOT_SUBPATH },
      { relw, "bar", errs.NOT_SUBPATH },
    }
    for _, t in ipairs(tests) do
      local dst = t[1].new(t[2])
      it(string.format([[no walk_up: %s - %s -> %s]], t[1], dst, t[3]), function()
        local res = t[1]:relative_to(dst)
        assert.is_nil(res)
        assert.is_not_nil(string.find(t[1].error_msg, t[3]))
      end)
      it(string.format([[walk_up: %s - %s -> %s]], t[1], dst, t[3]), function()
        local res = t[1]:relative_to(dst, true)
        if t[3] == errs.NOT_SUBPATH then
          assert.is_not_nil(res)
        else
          assert.is_nil(res)
          assert.is_not_nil(string.find(t[1].error_msg, t[3]))
        end
      end)
    end
  end)

  describe("relative_to walk_up", function()
    local tests = {
      { absp, "/usr", 1 },
      { relp, "bar", 1 },
      { relp, "baz/baz", 2 },
      { absw, "C:/bar", 1 },
      { relw, "bar", 1 },
    }
    for _, t in ipairs(tests) do
      local dst = t[1].new(t[2])
      local walkups = string.rep(".." .. t[1].sep_str, t[3])
      it(string.format([[%s - %s -> '%s']], t[1], dst, walkups), function()
        local res = t[1]:relative_to(dst, true)
        assert.is_not_nil(res)
        assert.is_true(vim.startswith(tostring(res), walkups))
        local strip_abs = tostring(t[1]):sub(t[1]._drive_name:len() + 1)
        if vim.startswith(strip_abs, t[1].sep_str) then
          strip_abs = strip_abs:sub(2)
        end
        assert.is_true(vim.endswith(tostring(res), strip_abs))
        assert.are.equal(walkups:len() + strip_abs:len(), tostring(res):len())
      end)
    end
  end)
end)
