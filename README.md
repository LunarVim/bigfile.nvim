# 🚧 WIP 🚧

# bigfile.nvim

This plugin disables certain features if the opened file is big.
File size and features to disable are configurable.

Automatic features/integrations include: `LSP`, `treesitter`, `indent_blankline`, `illuminate.vim` `NoMatchParen`, `syntax off`, ... (full list at the end)

Integrations that may manual configuration: `treesitter`.
You can also add your own features.

# Setup

## Installation

```lua
-- packer example:
use {
  "LunarVim/bigfile.nvim",
  config = function()
    require("bigfile").setup()
  end
}
```

## Integrate it with your config

Some features may need manual configuration

- Treesitter

  Manual configuration is needed if you have a custom `<module>.disable`

  Add a check to `highlight.disable` in treesitter's config:

  ```lua
  local bigfile = require("bigfile")
  local treesitter_configs = require("nvim-treesitter.configs")
  treesitter_configs.setup {
    highlight = {
      disable = function(lang, buf)
        local status_ok, detected = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
        return status_ok and detected
        -- ...
      end
  } }
  ```

# Configuration

Example with default config:

```lua
require("bigfile").setup{
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
```

## Features

Full list of features is at the end of this file.
You can also add your own feature like this:

```lua
local mymatchparen     = {
  name = "mymatchparen", -- name
  opts = {
    defer = false, -- true if `disable` should be called on `BufReadPost` and not `BufReadPre`
  },
  disable = function() -- called to disable the feature
    vim.cmd "NoMatchParen"
  end,
}
-- all fields except `name` and `disable` can be nil

-- you can put custom features in the features field in rules of the config:
require("bigfile").setup{
  filesize = 1,
  features = { "treesitter", mymatchparen }
}
```

# Caveats

- `matchparen` stays disabled, even after you close the big file, you can call `:DoMatchParen` manually to enable it

# Features/integrations

| name               | function                                                                                                    |
| ------------------ | ----------------------------------------------------------------------------------------------------------- |
| `lsp`              | detaches the lsp client from buffer                                                                         |
| `treesitter`       | disables treesitter for the buffer                                                                          |
| `illuminate`       | disables `RRethy/vim-illuminate` for the buffer                                                             |
| `indent_blankline` | disables `lukas-reineke/indent-blankline.nvim` for the buffer                                               |
| `syntax`           | `:syntax off` for the buffer                                                                                |
| `filetype`         | `filetype = ""` for the buffer                                                                              |
| `vimopts`          | `swapfile = false` `foldmethod = "manual"` `undolevels = -1` `undoreload = 0` `list = false` for the buffer |
| `matchparen`       | `:NoMatchParen` globally, currently this feature will stay disabled, even after you close the big file      |
