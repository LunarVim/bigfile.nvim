local M = {}

---@class feature
---@field disable function|nil Disables the feature
---@field enable function|nil Enables the feature
---@field global boolean|nil If true the feature has a global effect
---@field window_local boolean|nil If true the feature has a window local effect
---@field defer boolean|nil If true the feature will be disabled in vim.schedule
---@field [1] string Name of the feature

---@return feature
function M.get_feature(raw_feature)
  if (type(raw_feature) == "string") then -- builtin feature
    if not M[raw_feature] then
      vim.notify("bigfile.nvim: feature " .. raw_feature .. " does not exist!", vim.log.levels.WARN)
    end
    return M[raw_feature];
  else -- custom feature
    return raw_feature
  end
end

-- TODO: find out why these couse an error in cmp when inside `content` of function call
--[[ ---@param name string
---@param content feature ]]
local function feature(name, content)
  M[name] = content
  M[name][1] = name
end

local function local_feature(name, option, value)
  option = option or name
  value = value or false
  feature(name, {
    disable = function()
      vim.opt_local[option] = value
    end,
  })
end

local local_features = { "swapfile", "undofile", "list" }

for _, feat in pairs(local_features) do
  local_feature(feat)
end


feature("matchparen", {
  global = true,
  disable = function()
    vim.cmd "NoMatchParen"
  end,
  enable = function()
    vim.cmd "DoMatchParen"
  end
})

feature("syntax", {
  global = true,
  disable = function()
    vim.cmd "syntax off"
    vim.cmd "syntax clear"
  end,
  enable = function()
    vim.cmd "syntax on"
  end
})

feature("filetype", {
  global = true,
  disable = function()
    vim.cmd "filetype off"
  end,
  enable = function()
    vim.cmd "filetype on"
  end
})

feature("treesitter", {
  defer = true,
  disable = function()
    vim.cmd "TSBufDisable highlight"
    vim.cmd "TSBufDisable indent"
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
  disable = function(buf)
    pcall(function()
      require("indent_blankline.commands").disable()
    end)
  end,
})

return M
