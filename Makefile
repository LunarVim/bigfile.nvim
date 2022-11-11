INIT_RC ?= test/minimal_init.lua

test-data: test/data/canada.json

test/data/canada.json:
	mkdir -p test/data
	curl -L --progress-bar -o test/data/canada.json \
		"https://raw.githubusercontent.com/miloyip/nativejson-benchmark/master/data/canada.json"

test: test-data
	nvim --headless -u $(INIT_RC) -c "PlenaryBustedDirectory test/specs { minimal_init = '$(INIT_RC)' }"

test-file:
	nvim --headless -u $(INIT_RC) -c "lua require('plenary.busted').run('$(FILE)')"

.PHONY: test test-file
