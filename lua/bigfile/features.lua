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

for name, _ in pairs(M) do
  M[name][1] = name
end

return M
