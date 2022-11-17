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
        assert.same(false, vim.opt_local.swapfile:get())
        assert.same(-1, vim.opt_local.undolevels:get())
        assert.same(0, vim.opt_local.undoreload:get())
        assert.same(false, vim.opt_local.list:get())
      end)
    end)
    it("should disable vim filetype", function()
      bufload(bufnr)
      -- we can't use vim.schedule since it won't be caught by plenary
      api.nvim_buf_call(bufnr, function()
        assert.same("", api.nvim_buf_get_option(bufnr, "filetype"))
      end)
    end)
    it("should disable treesitter", function()
      bufload(bufnr)
      -- we can't use vim.schedule since it won't be caught by plenary
      local status_ok, detected = pcall(api.nvim_buf_get_var, bufnr, "bigfile_disable_treesitter")
      assert.True(status_ok)
      assert.same(1, detected)

      local ts_configs = require "nvim-treesitter.configs"
      local is_enabled = ts_configs.is_enabled

      assert.False(is_enabled("highlight", "json", bufnr))
      assert.False(is_enabled("indent", "json", bufnr))
    end)
  end)
end)

describe("setup", function()
  it("will respect user rules", function()
    local config = {
      size = 1,
      pattern = { "*.json" },
      features = { "vimopts" },
    }
    require("bigfile").setup(config)
    local aus = api.nvim_get_autocmds { group = "bigfile", pattern = "*.json" }
    assert.same(1, #aus)
    aus = api.nvim_get_autocmds { group = "bigfile", pattern = "*" }
    assert.same(0, #aus)
  end)
end)

describe("rules", function()
  local config = {
    size = 1,
    pattern = { "*.json" },
    features = { "vimopts" },
  }
  local bufnr
  local target_file = "test/data/bigdata.yml"
  before_each(function()
    require("bigfile").setup(config)
    vim.opt.foldmethod = "indent"
    bufnr = bufadd(target_file)
  end)

  it("can define a pattern", function()
    local aus = api.nvim_get_autocmds { group = "bigfile", pattern = "*.json" }
    assert.same(1, #aus)
  end)

  it("will only match a defined pattern", function()
    bufload(bufnr)
    vim.opt.foldmethod = "indent"
    local status_ok, detected = pcall(api.nvim_buf_get_var, bufnr, "bigfile_detected")
    assert.same(false, status_ok)
    assert.same("Key not found: bigfile_detected", detected)
  end)
end)
