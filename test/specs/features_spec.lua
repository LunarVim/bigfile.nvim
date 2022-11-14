local stub = require "luassert.stub"

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

  it("performs validation", function()
    local notify = stub(vim, "notify")
    local get_feature = require("bigfile.features").get_feature
    assert.truthy(get_feature "treesitter")
    assert.equal("foo", get_feature "foo")
    assert.stub(notify).was_called(1)
  end)
end)
