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
  disable = function(buf)
    vim.api.nvim_create_autocmd({ "LspAttach" }, {
      buffer = buf,
      callback = function(args)
        vim.schedule(function()
          vim.lsp.buf_detach_client(buf, args.data.client_id)
        end)
      end,
    })
  end,
})

local is_ts_configured = false

local function configure_treesitter()
  local status_ok, ts_config = pcall(require, "nvim-treesitter.configs")
  if not status_ok then
    return
  end

  local disable_cb = function(_, buf)
    local success, detected = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
    return success and detected
  end

  for _, mod_name in ipairs(ts_config.available_modules()) do
    local module_config = ts_config.get_module(mod_name) or {}
    local old_disabled = module_config.disable
    module_config.disable = function(lang, buf)
      return disable_cb(lang, buf)
        or (type(old_disabled) == "table" and vim.tbl_contains(old_disabled, lang))
        or (type(old_disabled) == "function" and old_disabled(lang, buf))
    end
  end

  is_ts_configured = true
end
feature("treesitter", {
  disable = function(buf)
    if not is_ts_configured then
      configure_treesitter()
    end

    vim.api.nvim_buf_set_var(buf, "bigfile_disable_treesitter", 1)
  end,
})

feature("illuminate", {
  disable = function(buf)
    pcall(function()
      require("illuminate.engine").stop_buf(buf)
    end)
  end,
})

feature("cmp", {
  disable = function()
    pcall(function()
      require("cmp").setup.buffer({ enabled = false})
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
  if type(raw_feature) == "table" then -- custom feature
    name = raw_feature.name
    feature(name, raw_feature)
  else -- builtin feature
    name = raw_feature
  end

  if not M[name] then
    vim.notify(
      "bigfile.nvim: feature " .. vim.inspect(raw_feature) .. " does not exist!",
      vim.log.levels.WARN
    )
    return raw_feature
  end
  return M[name]
end

return M
