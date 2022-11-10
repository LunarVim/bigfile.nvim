local M = {}

---@class feature
---@field disable function|nil Disables the feature
---@field enable function|nil Enables the feature
---@field global boolean|nil If true the feature has a global effect
---@field defer boolean|nil If true the feature will be disabled in vim.schedule
---@field [1] string Name of the feature

---@return feature
function M.get_feature(raw_feature)
  if (type(raw_feature) == "string") then -- builtin feature
    return M[raw_feature];
  else -- custom feature
    return raw_feature
  end
end

local function feature(name, content)
  M[name] = content
  M[name][1] = name
end

feature("match_paren", {
  global = true,
  disable = function()
    vim.cmd "NoMatchParen"
  end,
  enable = function()
    vim.cmd "DoMatchParen"
  end
})

return M
