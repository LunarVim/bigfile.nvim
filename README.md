# 🚧 WIP 🚧

# bigfile.nvim

This plugin disables certain features if the opened file is big
and re-enables them when the buffer is deleted
File sizes and features to disable are configurable.

Automatic features/integrations include: `indent_blankline`, `illuminate.vim` `NoMatchParen`, `syntax off`, ... (full list at the end)
Integrations requiring manual configuration: `LSP`, `treesitter`, `nvim_navic`
You can also add your own features.

## Setup

### Installation

```lua
-- packer example:
use {
  "LunarVim/bigfile.nvim",
  config = function()
    require("bigfile").setup()
  end
}
```

### Integrate it with your config
Some features need manual configuration

- Treesitter

  Add a check to highlight.disable in treesitter's config:

  ```lua
  local bigfile = require("bigfile")
  local treesitter_configs = require("nvim-treesitter.configs")
  treesitter_configs.setup {
    highlight = {
      disable = function(_, buf)
        return require("bigfile").is_feature_disabled(buf, "treesitter")
      end
  } }
  ```

- LSP

  Use this on_attatch:

  ```lua
  function on_attach(client, bufnr)
    local bigfile = require("bigfile")
    if bigfile.is_feature_disabled(bufnr, "lsp") then
      vim.lsp.buf_detach_client(bufnr, client.id)
      return
    end
    -- ...
  end
  ```

- nvim-navic

  Add this to the end of on_attatch:

  ```lua
  local symbols_supported = client.supports_method "textDocument/documentSymbol"
  local navic_disabled = bigfile.is_feature_disabled(bufnr, "nvim_navic")
  if symbols_supported and not navic_disabled then
    require("nvim-navic").attach(client, bufnr)
  end
  ```

# Configuration

Example with default config:

```lua
require("bigfile").setup{
  rules = {
    {
      size = 1,
      features = {
        "indent_blankline", "illuminate", { "nvim_navic" },
        "treesitter", "syntax",
        "matchparen", "swapfile", "undofile",
      }
    },
    { size = 2, features = { { "lsp" } } },
    { size = 50, features = { "filetype" } },
  }
}
```

## Features

Full list of features is at the end of this file.
You can also add your own feature like this:

```lua
local mymatchparen = {
  "mymatchparen",      -- name
  global = true,       -- NoMatchParen affects all buffers
  defer = false,       -- it doesn't need to wait for the filetype
  disable = function() -- called to disable the feature
    vim.cmd "NoMatchParen"
  end,
  enable = function()  -- called to enable the feature
    vim.cmd "DoMatchParen"
  end
}

-- all fields except the name can be nil, so you can do this:
local custom_feature = {"custom"}
-- a feature like this will require manual configuration by using
require("bigfile").is_feature_disabled(buf, "custom")
-- just like `LSP`, and `nvim_navic` from the default configuration

-- you can put custom featues in the features field in rules of the config:
require("bigfile").setup{ 
  rules = {
    size = 1,
    features = { "treesitter", mymatchparen, custom_feature }
  }
}
```

## Rules

Rules tell bigfile.nvim which features to disable
depending on the size of the opened file.

```lua
local rule = {
  -- minimal size of the file to activate this rule
  size = 1,
  -- list of features to disable
  features = { "treesitter", mymatchparen, {"custom"} }
}
```

rules need to be in ascending order sorted by size

```lua
-- in this example treesitter, mymatchparen, and syntax features will be disabled
-- if the file size is greater or equal than 1MiB
-- and lsp will be disabled for files with size >= 2MiB
require("bigfile").setup { 
  rules = {
    {
      size = 1,
      features = { "treesitter", mymatchparen, "syntax" }
    },
    {
      size = 2,
      features = { {"lsp"}, --[[...]] } -- shorter syntax for a custom feature, just wrap the name in `{}`
    }
  }
}
```

## Features/integrations

| name               | function                                         |
| ------------------ | ------------------------------------------------ |
| `illuminate`       | disables `RRethy/vim-illuminate`                 |
| `indent_blankline` | disables `lukas-reineke/indent-blankline.nvim`   |
| `treesitter`       | `:TSBufDisable highlight` `:TSBufDisable indent` |
| `matchparen`       | `:NoMatchParen`                                  |
| `syntax`           | `:syntax off`                                    |
| `filetype`         | `:filetype off`                                  |

The following features run `vim.opt_local[name] = false`:

```lua
{ "swapfile", "undofile", "list" }
```
