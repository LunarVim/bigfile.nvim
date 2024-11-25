# bigfile.nvim

This plugin automatically disables certain features if the opened file is big.
File size and features to disable are configurable.

Features/integrations include: `LSP`, `treesitter`, `indent_blankline`, `illuminate.vim` `NoMatchParen`, `syntax off`, ... (full list at the end)

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

## Customization

```lua
-- default config
require("bigfile").setup {
  filesize = 2, -- size of the file in MiB, the plugin round file sizes to the closest MiB
  pattern = { "*" }, -- autocmd pattern or function see <### Overriding the detection of big files>
  features = { -- features to disable
    "indent_blankline",
    "illuminate",
    "cmp",
    "lsp",
    "treesitter",
    "syntax",
    "matchparen",
    "vimopts",
    "filetype",
  },
}
```

Full description of the default features is at the end of this file.

You can override the default configuration, or add your own custom features

```lua
-- all fields except `name` and `disable` are optional
local mymatchparen = {
  name = "mymatchparen", -- name
  opts = {
    defer = false, -- set to true if `disable` should be called on `BufReadPost` and not `BufReadPre`
  },
  disable = function() -- called to disable the feature
    vim.cmd "NoMatchParen"
  end,
}

require("bigfile").setup {
  filesize = 1,
  features = { "treesitter", mymatchparen }
}
```

### Overriding the detection of big files

You can add your own logic for detecting big files by setting `pattern` in the
config to a function. If the function returns true file will be considered big,
otherwise `filesize` will be used as a fallback

example:

```lua
require("bigfile").setup {
  -- detect long python files
  pattern = function(bufnr, filesize_mib)
    -- you can't use `nvim_buf_line_count` because this runs on BufReadPre
    local file_contents = vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr))
    local file_length = #file_contents
    local filetype = vim.filetype.match({ buf = bufnr })
    if file_length > 5000 and filetype == "python" then
      return true
    end
  end
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
