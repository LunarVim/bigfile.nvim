local M = {}

---@class featureOpts
---@field defer boolean|nil If true the feature will be disabled in vim.schedule

---@class feature
---@field disable function Disables the feature
---@field opts featureOpts

---Add feature
---@param name string
---@param content feature
local function feature(name, content)
  vim.validate {
    name = { name, "string" },
    content = { content, "table" },
    disable = { content.disable, "function" },
    opts = { content.opts, "table", true },
  }
  M[name] = content
  M[name].opts = content.opts or {}
  M[name].name = name
end

feature("matchparen", {
  opts = { global = true },
  disable = function()
    if vim.fn.exists ":DoMatchParen" ~= 2 then
      return
    end
    vim.cmd "NoMatchParen"
  end,
})

feature("lsp", {
  disable = function()
    vim.api.nvim_create_autocmd({ "LspAttach" }, {
      callback = function(args)
        vim.schedule(function()
          vim.lsp.buf_detach_client(args.buf, args.data.client_id)
        end)
      end,
    })
  end,
})

feature("treesitter", {
  opts = { defer = true },
  disable = function()
    local ts_conf = require "nvim-treesitter.configs"
    local available_modules = ts_conf.available_modules()
    vim.cmd("TSBufDisable " .. unpack(available_modules))
  end,
})

feature("illuminate", {
  disable = function(buf)
    pcall(function()
      require("illuminate.engine").stop_buf(buf)
    end)
  end,
})

feature("indent_blankline", {
  disable = function(_)
    pcall(function()
      require("indent_blankline.commands").disable()
    end)
  end,
})

---@diagnostic disable: assign-type-mismatch
feature("vimopts", {
  disable = function()
    vim.opt_local.swapfile = false
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.undolevels = -1
    vim.opt_local.undoreload = 0
    vim.opt_local.list = false
  end,
})

feature("syntax", {
  opts = { defer = true },
  disable = function()
    vim.cmd "syntax clear"
    vim.opt_local.syntax = "OFF"
  end,
})

feature("filetype", {
  opts = { defer = true },
  disable = function()
    vim.opt_local.filetype = ""
  end,
})

----@return feature
function M.get_feature(raw_feature)
  local name
  if type(raw_feature) == "table" then -- builtin feature
    name = raw_feature.name
    feature(name, raw_feature)
  else
    name = raw_feature
  end

  if not M[name] then
    vim.notify("bigfile.nvim: feature " .. vim.inspect(raw_feature) .. " does not exist!", vim.log.levels.WARN)
    return raw_feature
  end
  return M[name]
end

return M
