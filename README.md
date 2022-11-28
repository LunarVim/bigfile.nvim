# bigfile.nvim

This plugin disables certain features if the opened file is big.
File size and features to disable are configurable.

Automatic features/integrations include: `LSP`, `treesitter`, `indent_blankline`, `illuminate.vim` `NoMatchParen`, `syntax off`, ... (full list at the end)

Integrations that may need manual configuration: `treesitter`.
You can also add your own features.

# Setup

## Installation

```lua
-- packer example:
use {
  "LunarVim/bigfile.nvim",
}
```

The plugin ships with common default options. No further setup is required.

```lua
local default_config = {
  filesize = 2, -- size of the file in MiB
  pattern = { "*" }, -- autocmd pattern
  features = { -- features to disable
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

Full description of features is at the end of this file.

## Customization

You can override the default configuration, or add your own custom features

```lua
-- all fields except `name` and `disable` can be nil
local mymatchparen = {
  name = "mymatchparen", -- name
  opts = {
    defer = false, -- true if `disable` should be called on `BufReadPost` and not `BufReadPre`
  },
  disable = function() -- called to disable the feature
    vim.cmd "NoMatchParen"
  end,
}

require("bigfile").config {
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
