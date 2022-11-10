local M = {}

local features = require("bigfile.features")

local big_buffers = {}

---@class config
---@field rules table fds
---@field rules.size string fds
local config = {
  rules = {
    { size = 0.001, features = { "match_paren", "nvim_navic" } },
  }
}

function M.is_feature_disabled(bufnr, feature_name)
  if big_buffers[bufnr] ~= nil then
    local disabled_features = big_buffers[bufnr].disabled_features
    for _, feature in ipairs(disabled_features) do
      if feature[1] == feature_name then
        return true
      end
    end
  end
  return false
end

local function match_rules(filesize)
  local MB = 1024 * 1024
  local matched_features = {}
  for _, rule in ipairs(config.rules) do
    if filesize >= rule.size * MB then

      for _, raw_feature in ipairs(rule.features) do
        local feature
        if (type(raw_feature) == "string") then
          feature = features[raw_feature];
        else
          feature = raw_feature
        end
        table.insert(matched_features, feature)
      end

    else
      return matched_features
    end
  end
  return matched_features
end

local function enable_global_features(features_to_enable)
  -- TODO: don't enable features present in big_buffers
  for _, feature in ipairs(features_to_enable) do
    feature.enable()
  end
end

local function pre_bufread_callback(args)
  if big_buffers[args.buf] ~= nil then
    return
  end

  local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
  if not (ok and stats) then
    return
  end

  local matched_features = match_rules(stats.size)
  if #matched_features == 0 then
    return
  end

  local matched_global_features = {}
  local matched_deferred_features = {}

  for _, feature in ipairs(matched_features) do

    if feature.global then
      table.insert(matched_global_features, feature)
    end

    if feature.defer then
      table.insert(matched_deferred_features, feature)
    elseif not feature.manual then
      feature.disable()
    end
  end

  big_buffers[args.buf] = {
    disabled_global_features = matched_global_features,
    disabled_features = matched_features
  }

  if #matched_global_features > 0 then
    vim.api.nvim_create_autocmd({ "BufDelete" }, {
      callback = function()
        local features_to_enable = big_buffers[args.buf].disabled_global_features
        big_buffers[args.buf] = nil
        enable_global_features(features_to_enable)
      end,
      buffer = args.buf,
    })
  end

  vim.schedule(function()
    vim.api.nvim_buf_call(args.buf, function()
      for _, feature in ipairs(matched_deferred_features) do
        feature.disable()
      end
    end)
  end)

end

local function setup_autocmd()
  vim.api.nvim_create_augroup("bigfile", {})
  vim.api.nvim_create_autocmd("BufReadPre", {
    group = "bigfile",
    callback = pre_bufread_callback
  })
end

setup_autocmd()

return M;
