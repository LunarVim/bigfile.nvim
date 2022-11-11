local M = {}

---@class featureOpts
---@field global boolean|nil If true the feature has a global effect
---@field window_local boolean|nil If true the feature has a window local effect
---@field defer boolean|nil If true the feature will be disabled in vim.schedule

---@class feature
---@field disable function Disables the feature
---@field enable function|nil Enables the feature
---@field opts featureOpts

---Add feature
---@param name string
---@param content feature
local function feature(name, content)
  vim.validate {
    name = { name, "string" },
    content = { content, "table" },
    disable = { content.disable, "function" },
    enable = { content.enable, "function", true },
    opts = { content.opts, "table", true },
  }
  content.opts = content.opts or {}
  M[name] = content
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
  enable = function()
    vim.cmd "DoMatchParen"
  end,
})

local function nvim_set_local(option, value)
  vim.api.nvim_set_option_value(option, value { scope = "local" })
end

feature("syntax", {
  disable = function()
    if not vim.g.syntax_on then
      return
    end
    nvim_set_local("syntax", "OFF")
    vim.cmd "syntax clear"
  end,
})

feature("vimopts", {
  disable = function()
    nvim_set_local("filetype", "")
    nvim_set_local("swapfile", false)
    nvim_set_local("list", false)
    nvim_set_local("foldmethod", "manual")
    nvim_set_local("undolevels", -1)
    nvim_set_local("undoreload", 0)
  end,
})

feature("treesitter", {
  opts = { defer = true },
  disable = function()
    pcall(function()
      local ts_conf = require "nvim-treesitter.configs"
      local available_modules = ts_conf.available_modules()
      vim.cmd("TSBufDisable " .. unpack(available_modules))
    end)
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

----@return feature
function M.get_feature(raw_feature)
  if type(raw_feature) == "string" then -- builtin feature
    if not M[raw_feature] then
      vim.notify("bigfile.nvim: feature " .. raw_feature .. " does not exist!", vim.log.levels.WARN)
    end
    return M[raw_feature]
  else -- custom feature
    return raw_feature
  end
end

return M
