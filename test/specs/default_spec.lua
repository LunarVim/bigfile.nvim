local api = vim.api
local bufload = vim.fn.bufload
local bufadd = vim.fn.bufadd

local a = require "plenary.async_lib.tests"
local describe = a.describe

describe("callback", function()
  local bufnr
  before_each(function()
    require("bigfile").setup()
    vim.cmd [[syntax on]]
    vim.opt.swapfile = true
    vim.opt.foldmethod = "indent"
    vim.opt.list = true
  end)

  describe("for small files", function()
    local target_file = "./README.md"
    before_each(function()
      bufnr = bufadd(target_file)
    end)

    it("should cache detection", function()
      bufload(bufnr)
      assert.same(0, api.nvim_buf_get_var(bufnr, "bigfile_detected"))
    end)
    it("should not alter filetype", function()
      bufload(bufnr)
      assert.same("markdown", api.nvim_buf_get_option(bufnr, "filetype"))
    end)
  end)

  describe("for big files", function()
    local target_file = "test/data/bigdata.json"
    before_each(function()
      bufnr = bufadd(target_file)
    end)

    it("should cache detection", function()
      bufload(bufnr)
      assert.same(1, api.nvim_buf_get_var(bufnr, "bigfile_detected"))
    end)

    it("should disable slow vim options", function()
      bufload(bufnr)
      -- we can't use vim.schedule since it won't be caught by plenary
      api.nvim_buf_call(bufnr, function()
        assert.same(1, api.nvim_buf_get_var(bufnr, "bigfile_detected"))
        assert.same(false, vim.opt_local.swapfile:get())
        assert.same(-1, vim.opt_local.undolevels:get())
        assert.same(0, vim.opt_local.undoreload:get())
        assert.same(false, vim.opt_local.list:get())
      end)
    end)
    it("should not disable vim filetype", function()
      bufload(bufnr)
      -- we can't use vim.schedule since it won't be caught by plenary
      api.nvim_buf_call(bufnr, function()
        assert.same("json", api.nvim_buf_get_option(bufnr, "filetype"))
      end)
    end)
  end)
end)

describe("rules", function()
  local config = {
    rules = {
      { size = 1, pattern = { "*.json" }, features = { "vimopts" } },
    },
  }
  before_each(function()
    require("bigfile").setup(config)
  end)
  it("can define a pattern", function()
    local aus = api.nvim_get_autocmds { group = "bigfile", pattern = "*.json" }
    assert.same(1, #aus)
  end)
  it("will only match a defined pattern", function()
    local bufnr
    local target_file = "test/data/bigdata.json"
    local target_stats = vim.loop.fs_stat(target_file)
    local target_size = math.floor(0.5 + (target_stats.size / (1024 * 1024)))
    assert.True(target_size > config.rules[1].size)
    bufnr = bufadd(target_file)
    bufload(bufnr)
    assert.same(1, api.nvim_buf_get_var(bufnr, "bigfile_detected"))
    local target_file_2 = "test/data/bigdata.csv"
    assert.True(config.rules[1].pattern[1] ~= "*.csv")
    bufnr = bufadd(target_file_2)
    bufload(bufnr)
    assert.falsy(pcall(api.nvim_buf_get_var, bufnr, "bigfile_detected"))
  end)
end)
