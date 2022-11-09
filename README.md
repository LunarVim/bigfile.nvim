# 🚧 WIP 🚧

# bigfile.nvim
This plugin disables certain features if the opened file is big.
File sizes and features to disable are configurable.

# Configuration

## Rules
Rules tell bigfile.nvim which features to disable
depending on the size of opened file.
```lua
local rule = { 
  --- minimal size of the file to activate this rule
  size = 1,           
  --- list of features to disable
  features = { "treesitter", "syntax" } 
}
```

rules need to be in ascending order sorted by size
```lua
-- in this example treesitter and syntax features will be disabled
-- if the file size is greater or equal than 1MiB
-- and lsp will be disabled for files with size size >= 2MiB
local rules = {
  { 
    size = 1,           
    features = { "treesitter", "syntax" } 
  },
  { 
    size = 2,           
    features = { "lsp" } 
  }
}
```


