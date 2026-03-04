
test: test-buffer test-tmux test-selection

test-buffer: $(PLENARY_DIR)
	nvim -u tests/minimal.lua --headless -c "PlenaryBustedDirectory ./tests/plenary/buffer_spec.lua { minimal_init = 'tests/minimal.lua' , sequential = true}"
	nvim -u tests/minimal.lua --headless -c "PlenaryBustedDirectory ./tests/plenary/buffer_capture_spec.lua { minimal_init = 'tests/minimal.lua' , sequential = true}"

test-tmux: $(PLENARY_DIR)
	@[ -z "$$TMUX" ] && echo "tmux is not running" && exit 1 || true
	nvim -u tests/minimal.lua --headless -c "PlenaryBustedDirectory ./tests/plenary/tmux_spec.lua { minimal_init = 'tests/minimal.lua' , sequential = true}"
	nvim -u tests/minimal.lua --headless -c "PlenaryBustedDirectory ./tests/plenary/tmux_capture_spec.lua { minimal_init = 'tests/minimal.lua' , sequential = true}"

test-selection: $(PLENARY_DIR)
	nvim -u tests/minimal.lua --headless -c "PlenaryBustedDirectory ./tests/plenary/selection_spec.lua { minimal_init = 'tests/minimal.lua' , sequential = true}"

PLENARY_DIR=tests/plenary.nvim

$(PLENARY_DIR):
	git clone https://github.com/nvim-lua/plenary.nvim/ $(PLENARY_DIR)
