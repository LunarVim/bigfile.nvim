local base_dir = vim.loop.cwd()

local function join_paths(...)
  local path_sep = vim.loop.os_uname().version:match "Windows" and "\\" or "/"
  local result = table.concat({ ... }, path_sep)
  return result
end
local tests_dir = join_paths(base_dir, "tests")

local plenary_dir = join_paths(vim.fn.stdpath "data", "site", "pack", "packer", "start", "plenary.nvim")

if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system { "git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir }
end

vim.cmd("packadd plenary.nvim")

vim.opt.rtp:append(tests_dir)
vim.opt.rtp:append(base_dir)
