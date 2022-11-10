local M = {}

local features = require("bigfile.features")

---@class big_buffer
---@field all_disabled_features feature[]
---@field disabled_global_features feature[]
-- list of open big buffers
---@type big_buffer[]
local big_buffers = {}

---@class rule
---@field size number file size in MiB
---@field features feature[] array of features

---@class config
---@field rules rule[] rules
local config = {
  rules = {
    { size = 1,
      features = { "illuminate", "matchparen", "treesitter", "syntax", "swapfile", "undofile", { "nvim_navic" } } },
    { size = 2, features = { { "lsp" } } },
    { size = 50, features = { "filetype" } },
  }
}

---@param bufnr number
---@param feature_name string
---@return boolean is_disabled Ture if `feature_name` is disabled in `bufnr` buffer
function M.is_feature_disabled(bufnr, feature_name)
  if big_buffers[bufnr] ~= nil then
    local disabled_features = big_buffers[bufnr].all_disabled_features
    for _, feature in ipairs(disabled_features) do
      if feature[1] == feature_name then
        return true
      end
    end
  end
  return false
end

---@param filesize number File size in MiB
---@return feature[] features Features from rules that match the `filesize`
local function match_features(filesize)
  local MB = 1024 * 1024
  local matched_features = {}
  for _, rule in ipairs(config.rules) do
    if filesize >= rule.size * MB then

      for _, raw_feature in ipairs(rule.features) do
        table.insert(matched_features, features.get_feature(raw_feature))
      end

    else -- since rules should be sorted, we can exit early
      return matched_features
    end
  end
  return matched_features
end

-- Enables global features that aren't disabled by different buffers
local function enable_global_features(buf, features_to_enable)
  local features_not_to_touch = {}
  for _, big_buffer in pairs(big_buffers) do
    for _, global_feature in pairs(big_buffer.disabled_global_features) do
      table.insert(features_not_to_touch, global_feature[1])
    end
  end

  for _, feature in ipairs(features_to_enable) do
    if not vim.tbl_contains(features_not_to_touch, feature[1]) then
      feature.enable(buf)
    end
  end
end

-- disables features matching the size of the `args.buf` buffer
local function pre_bufread_callback(args)
  if big_buffers[args.buf] ~= nil then
    return -- buffer aleady set-up
  end

  local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
  if not (ok and stats) then
    return
  end

  local matched_features = match_features(stats.size)
  if #matched_features == 0 then
    return
  end

  -- Categorize features and disable features that don't need deferring
  local matched_global_features = {}
  local matched_deferred_features = {}
  for _, feature in ipairs(matched_features) do
    if feature.global then
      table.insert(matched_global_features, feature)
    end

    if feature.defer then
      table.insert(matched_deferred_features, feature)
    elseif type(feature.disable) == "function" then
      feature.disable(args.buf)
    end
  end

  big_buffers[args.buf] = {
    disabled_global_features = matched_global_features,
    all_disabled_features = matched_features
  }

  -- Setup an autocommand to enable features after the bugger is deleted
  if #matched_global_features > 0 then
    vim.api.nvim_create_autocmd({ "BufDelete" }, {
      callback = function()
        local features_to_enable = big_buffers[args.buf].disabled_global_features
        big_buffers[args.buf] = nil
        enable_global_features(args.buf, features_to_enable)
      end,
      buffer = args.buf,
    })
  end

  -- Schedule disabling deferred features
  vim.schedule(function()
    vim.api.nvim_buf_call(args.buf, function()
      for _, feature in ipairs(matched_deferred_features) do
        feature.disable(args.buf)
      end
    end)
  end)

end

---@param user_config config|nil
function M.setup(user_config)
  if type(user_config) == "table" then
    if user_config.rules then
      config.rules = user_config.rules
    end
  end

  vim.api.nvim_create_augroup("bigfile", {})
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufReadPre" }, {
    group = "bigfile",
    callback = pre_bufread_callback
  })
end

return M;
