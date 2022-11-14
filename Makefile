INIT_RC 				?= test/minimal_init.lua
PLENARY_DIR 		?= $(XDG_DATA_HOME)/nvim/site/pack/packer/start/plenary.nvim
NVIM_TS_DIR 		?= $(XDG_DATA_HOME)/nvim/site/pack/packer/start/nvim-treesitter

test-data: test/data/bigdata.json test/data/bigdata.csv

test/data/bigdata.json:
	mkdir -p test/data
	curl -L --progress-bar -o test/data/bigdata.json \
		"https://raw.githubusercontent.com/miloyip/nativejson-benchmark/master/data/canada.json"

test/data/bigdata.csv:
	mkdir -p test/data
	curl -L --progress-bar -o test/data/bigdata.csv \
		"https://github.com/tblock/10kGNAD/blob/da845fe4a16f02a8de10903ffbc636d1c8d21862/test.csv"

deps: $(PLENARY_DIR) $(NVIM_TS_DIR)

$(PLENARY_DIR):
	git clone --depth=1 "https://github.com/nvim-lua/plenary.nvim" $(PLENARY_DIR)

$(NVIM_TS_DIR):
	git clone --depth=1 "https://github.com/nvim-lua/plenary.nvim" $(NVIM_TS_DIR)

test: deps test-data
	nvim --headless -u $(INIT_RC) -c "PlenaryBustedDirectory test/specs { minimal_init = '$(INIT_RC)' }"

test-file: deps
	nvim --headless -u $(INIT_RC) -c "lua require('plenary.busted').run('$(FILE)')"

lint:
	luacheck lua
	stylua --check lua

.PHONY: test test-file lint
