local M = {}

local features = require "bigfile.features"

---@alias filesize_unit "MiB"|"bytes"

---@class config
---@field filesize integer size in filesize_unit, default MiB
---@field filesize_unit filesize_unit filesize unit, default MiB
---@field pattern string|string[]|fun(bufnr: number, filesize: number): boolean an |autocmd-pattern| or callback to override detection of big files
---@field features string[] array of features
local default_config = {
  filesize = 2, -- 2 MiB
  filesize_unit = "MiB",
  pattern = { "*" },
  features = {
    "indent_blankline",
    "illuminate",
    "lsp",
    "treesitter",
    "syntax",
    "matchparen",
    "vimopts",
    "filetype",
  },
}

---@param bufnr number
---@return integer|nil size in bytes if buffer is valid, nil otherwise
local function get_buf_size(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, stats = pcall(function()
    return vim.loop.fs_stat(vim.api.nvim_buf_get_name(bufnr))
  end)
  if not (ok and stats) then
    return
  end
  return stats.size
end

---@param size number filesize in filesize_unit
---@param target_unit filesize_unit
local function convert_to_filesize_unit(size, target_unit)
  if target_unit == "MiB" then
    return math.floor(0.5 + size / (1024 * 1024))
  end
  return size
end

---@param bufnr number
---@param config config
local function pre_bufread_callback(bufnr, config)
  local status_ok, _ = pcall(vim.api.nvim_buf_get_var, bufnr, "bigfile_detected")
  if status_ok then
    return -- buffer has already been processed
  end

  local filesize = convert_to_filesize_unit(get_buf_size(bufnr) or 0, config.filesize_unit)
  local bigfile_detected = filesize >= config.filesize
  if type(config.pattern) == "function" then
    bigfile_detected = config.pattern(bufnr, filesize) or bigfile_detected
  end

  if not bigfile_detected then
    vim.api.nvim_buf_set_var(bufnr, "bigfile_detected", 0)
    return
  end

  vim.api.nvim_buf_set_var(bufnr, "bigfile_detected", 1)

  local matched_features = vim.tbl_map(function(feature)
    return features.get_feature(feature)
  end, config.features)

  -- Categorize features and disable features that don't need deferring
  local matched_deferred_features = {}
  for _, feature in ipairs(matched_features) do
    if feature.opts.defer then
      table.insert(matched_deferred_features, feature)
    else
      feature.disable(bufnr)
    end
  end

  -- Schedule disabling deferred features
  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    callback = function()
      for _, feature in ipairs(matched_deferred_features) do
        feature.disable(bufnr)
      end
    end,
    buffer = bufnr,
  })
end

---@param overrides config|nil
function M.setup(overrides)
  local config = vim.tbl_deep_extend("force", default_config, overrides or {})

  local augroup = vim.api.nvim_create_augroup("bigfile", {})

  local pattern = config.pattern

  vim.api.nvim_create_autocmd("BufReadPre", {
    pattern = type(pattern) ~= "function" and pattern or "*",
    group = augroup,
    callback = function(args)
      pre_bufread_callback(args.buf, config)
    end,
    desc = string.format(
      "[bigfile.nvim] Performance rule for handling files over %s %s",
      config.filesize,
      config.filesize_unit
    ),
  })

  vim.g.loaded_bigfile_plugin = true
end

M.config = M.setup

return M
