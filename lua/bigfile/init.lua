local M = {}

local features = require "bigfile.features"

---@class rule
---@field size integer file size in MiB
---@field features feature[] array of features

---@class config
---@field rules rule[] rules
local config = {
  rules = {
    {
      size = 1,
      features = {
        "indent_blankline",
        "illuminate",
        "lsp",
        "treesitter",
        "syntax",
        "matchparen",
        "vimopts",
      },
    },
    { size = 50, features = { "filetype" } },
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

---@param bufnr number buffer id to match against
---@return feature[] features Features from rules that match the `filesize`
local function match_features(bufnr)
  local matched_features = {}
  local filesize = get_buf_size(bufnr)
  if not filesize then
    return matched_features
  end
  for _, rule in ipairs(config.rules) do
    if filesize >= rule.size then
      for _, raw_feature in ipairs(rule.features) do
        matched_features[#matched_features + 1] = features.get_feature(raw_feature)
      end
    else -- since rules should be sorted, we can exit early
      return matched_features
    end
  end
  return matched_features
end

local function pre_bufread_callback(args)
  local status_ok, _ = pcall(vim.api.nvim_buf_get_var, args.buf, "bigfile_detected")
  if status_ok then
    return -- buffer has already been processed
  end

  local matched_features = vim.tbl_filter(function(feature)
    return type(feature.disable) == "function"
  end, match_features(args.bufnr))

  if #matched_features == 0 then
    vim.api.nvim_buf_set_var(args.buf, "bigfile_detected", 0)
    return
  end

  vim.api.nvim_buf_set_var(args.buf, "bigfile_detected", 1)

  -- Categorize features and disable features that don't need deferring
  local matched_deferred_features = {}
  for _, feature in ipairs(matched_features) do
    if feature.opts.defer then
      table.insert(matched_deferred_features, feature)
    else
      feature.disable(args.buf)
    end
  end

  -- Schedule disabling deferred features
  if #matched_deferred_features > 0 then
    vim.api.nvim_create_autocmd({ "BufReadPost" }, {
      callback = function()
        for _, feature in ipairs(matched_deferred_features) do
          feature.disable(args.buf)
        end
      end,
      buffer = args.buf,
    })
  end
end

---@param user_config config|nil
function M.setup(user_config)
  if type(user_config) == "table" then
    if user_config.rules then
      config.rules = user_config.rules
    end
  end

  local treesitter_configs = require "nvim-treesitter.configs"
  treesitter_configs.setup {
    highlight = {
      disable = function(_, buf)
        return pcall(vim.api.nvim_buf_get_var, buf, "bigfile_detected")
      end,
    },
  }

  vim.api.nvim_create_augroup("bigfile", {})
  vim.api.nvim_create_autocmd("BufReadPre", {
    group = "bigfile",
    callback = pre_bufread_callback,
  })
end

return M
