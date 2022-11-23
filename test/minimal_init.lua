local base_dir = vim.loop.cwd()

local function join_paths(...)
  local path_sep = vim.loop.os_uname().version:match "Windows" and "\\" or "/"
  local result = table.concat({ ... }, path_sep)
  return result
end

local tests_dir = join_paths(base_dir, "tests")

vim.opt.rtp = "$VIMRUNTIME"

vim.opt.rtp:append(tests_dir)
vim.opt.rtp:append(base_dir)
vim.opt.rtp:append(base_dir)

vim.o.swapfile = false
vim.bo.swapfile = false

require("nvim-treesitter.configs").setup {
  indent = { enable = true },
  highlight = { enable = true },
}
