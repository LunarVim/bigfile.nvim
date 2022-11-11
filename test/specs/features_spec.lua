describe("features", function()

  it("should be available", function()
    local features = require "bigfile.features"
    assert.True(#vim.tbl_keys(features) > 0)
  end)

  it("can be accessed", function()
    local features = require "bigfile.features"
    assert.truthy(features["treesitter"])
    assert.same("function", type(features["treesitter"].disable))
  end)

end)
