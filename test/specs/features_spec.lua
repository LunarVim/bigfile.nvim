local api = vim.api
local bufload = vim.fn.bufload
local bufadd = vim.fn.bufadd
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

describe("plenary", function()
  local bufnr
  local target_file = "test/data/bigdata.yml"
  local get_feature = require("bigfile.features").get_feature
  before_each(function()
    bufnr = bufadd(target_file)
    vim.opt.foldmethod = "indent"
    vim.cmd [[syntax on]]
  end)

  it("will retain vimopt feature", function()
    bufload(bufnr)
    api.nvim_buf_call(bufnr, function()
      assert.same("indent", vim.opt_local.foldmethod:get())
    end)
    api.nvim_buf_call(bufnr, function()
      get_feature("vimopts").disable()
    end)
    api.nvim_buf_call(bufnr, function()
      assert.same("manual", vim.opt_local.foldmethod:get())
    end)
  end)

  it("will retain the syntax feature", function()
    bufload(bufnr)
    api.nvim_buf_call(bufnr, function()
      assert.same("yaml", vim.opt_local.syntax:get())
    end)
    api.nvim_buf_call(bufnr, function()
      get_feature("syntax").disable()
    end)
    api.nvim_buf_call(bufnr, function()
      assert.same("OFF", vim.opt_local.syntax:get())
    end)
  end)
end)
