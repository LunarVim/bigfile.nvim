if vim.g.loaded_bigfile_plugin then
  return
end

vim.g.loaded_bigfile_plugin = true

require("bigfile").setup()
