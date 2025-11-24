# bigfile.nvim

This plugin automatically disables certain features if the opened file is big.
File size and features to disable are configurable.

Features/integrations include: `LSP`, `treesitter`, `indent_blankline`, `illuminate.vim` `NoMatchParen`, `syntax off`, ... (full list at the end)

You can also add your own features.

# Setup

## Installation

> The plugin ships with common default options. No further setup is required.

* packer

```lua

-- packer example:
use {
  "LunarVim/bigfile.nvim",
}

```

* lazy

```lua
-- lazy example

---@diagnostic disable: undefined-global, unused-local

local function exec_bigfile_autocmds()

	local bigfile_ok, _ = pcall(require, "bigfile")
	if (bigfile_ok) then
		vim.g.force_bigfile = true

		-- bigfile plugin will set a buffer variable "bigfile_detected"
		-- must delete it first to retrigger the autocmds
		vim.api.nvim_buf_del_var(0,"bigfile_detected")
		vim.api.nvim_exec_autocmds("BufReadPre", {buffer = 0})
		vim.api.nvim_exec_autocmds("BufReadPost", {buffer = 0})

		vim.g.force_bigfile = nil
	end
end


return {

	"LunarVim/bigfile.nvim",

	enabled = true,
	lazy = false,
	--event = "VeryLazy",

	opts={
		-- size of the file in MiB, the plugin round file sizes to the closest MiB
		filesize = 1,

		-- autocmd pattern or function see <### Overriding the detection of big files>
		-- vim.g.force_bigfile can be set to true to force bigfile mode
		-- pattern = { "*" , function () return vim.g.force_bigfile end },
		pattern = function () return vim.g.force_bigfile end,


		-- features to disable
		features = {
			--lsp	detaches the lsp client from buffer
			--treesitter	disables treesitter for the buffer
			--illuminate	disables RRethy/vim-illuminate for the buffer
			--indent_blankline	disables lukas-reineke/indent-blankline.nvim for the buffer
			--syntax	:syntax off for the buffer
			--filetype	filetype = "" for the buffer
			--vimopts	swapfile = false foldmethod = "manual" undolevels = -1 undoreload = 0 list = false for the buffer
			--matchparen	:NoMatchParen globally, currently this feature will stay disabled, even after you close the big file

			"indent_blankline",
			"illuminate",
			"lsp",
			"treesitter",
			"syntax",
			"matchparen",
			"vimopts",
			"filetype",

			--[[
			{
				name = "mini.indentscope",
				disable = function (buf)
					vim.b[buf].miniindentscope_disable = true
				end
			},]]

			{
				name = "cmp",
				disable = function(buf)
					local ok, cmp = pcall(require, "cmp")
					if ok then
						cmp.setup.buffer({ enabled = false })
					end
				end,
			}
		},
	},

	config = function(_, opts)

		--initialize force_bigfile to false, use pattern '*'
		vim.g.force_bigfile = false
		require("bigfile").setup(opts)

		-- autocmds (when paste, insert thounds of text)
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
			callback = function()
				local bufnr = vim.api.nvim_get_current_buf()
				local size = vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))

				if (size > 2 * 1024 * 1024) then
					exec_bigfile_autocmds()
					print("Current size: " 
						.. size 
						.. " bytes" 
						.. " bigfile optimizations have been applied ")
				end

			end,
		})

	end,
}
```


## Customization

```lua
-- default config
require("bigfile").setup {
  filesize = 2, -- size of the file in MiB, the plugin round file sizes to the closest MiB
  pattern = { "*" }, -- autocmd pattern or function see <### Overriding the detection of big files>
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
