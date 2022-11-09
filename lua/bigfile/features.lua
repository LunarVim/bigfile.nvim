local M = {}

M["match_paren"] = {
  global = true,
  disable = function()
    vim.cmd "NoMatchParen"
  end,
  enable = function()
    vim.cmd "DoMatchParen"
  end
}

M["nvim_navic"] = {
  manual = true
}

return M
