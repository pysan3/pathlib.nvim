---@module 'busted'

describe("Hello World Test;", function()
  describe("Simple test to check if luarocks is working correctly.", function()
    it("Check: hello world", function()
      local foo = "Hello World"
      local bar = "Hello World"
      assert.are.equal(foo, bar)
    end)
  end)
end)
