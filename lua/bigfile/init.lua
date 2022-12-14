local M = {}

local features = require "bigfile.features"

---@class config
---@field filesize integer size in MiB
---@field pattern string|string[] see |autocmd-pattern|
---@field features string[] array of features
local default_config = {
  filesize = 2,
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
---@return integer|nil size in MiB if buffer is valid, nil otherwise
local function get_buf_size(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, stats = pcall(function()
    return vim.loop.fs_stat(vim.api.nvim_buf_get_name(bufnr))
  end)
  if not (ok and stats) then
    return
  end
  return math.floor(0.5 + (stats.size / (1024 * 1024)))
end

local function pre_bufread_callback(bufnr, rule)
  local status_ok, _ = pcall(vim.api.nvim_buf_get_var, bufnr, "bigfile_detected")
  if status_ok then
    return -- buffer has already been processed
  end

  local filesize = get_buf_size(bufnr)
  if not filesize or filesize < rule.filesize then
    vim.api.nvim_buf_set_var(bufnr, "bigfile_detected", 0)
    return
  end

  vim.api.nvim_buf_set_var(bufnr, "bigfile_detected", 1)

  local matched_features = vim.tbl_map(function(feature)
    return features.get_feature(feature)
  end, rule.features)

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

local function configure_treesitter_disable(cb, modules)
  local status_ok, ts_config = pcall(require, "nvim-treesitter.configs")
  if not status_ok then
    return
  end

  modules = modules or ts_config.available_modules()
  for _, mod_name in ipairs(modules) do
    local module_config = ts_config.get_module(mod_name) or {}
    module_config.disable = module_config.disable or {}
    if type(module_config.disable) == "table" and #module_config.disable == 0 then
      module_config.disable = cb
    end
  end
end

---@param overrides config|nil
function M.config(overrides)
  default_config = vim.tbl_deep_extend("force", default_config, overrides or {})
end

---@param overrides config|nil
function M.setup(overrides)
  local config = vim.tbl_deep_extend("force", default_config, overrides or {})

  local augroup = vim.api.nvim_create_augroup("bigfile", {})

  vim.api.nvim_create_autocmd("BufReadPre", {
    pattern = config.pattern,
    group = augroup,
    callback = function(args)
      pre_bufread_callback(args.buf, config)
    end,
    desc = string.format("Performance rule for handling files over %sMiB", config.filesize),
  })

  if vim.tbl_contains(config.features, "treesitter") then
    local disable_cb = function(_, buf)
      local status_ok, detected = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
      return status_ok and detected
    end
    configure_treesitter_disable(disable_cb)
  end
end

return M
