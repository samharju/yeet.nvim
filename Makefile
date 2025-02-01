
test: test-buffer test-tmux test-selection

test-buffer:
	@nvim --headless -c "PlenaryBustedFile ./tests/plenary/buffer_spec.lua"
	@nvim --headless -c "PlenaryBustedFile ./tests/plenary/buffer_capture_spec.lua"

test-tmux:
	@[ -z "$$TMUX" ] && echo "tmux is not running" && exit 1 || true
	@nvim --headless -c "PlenaryBustedFile ./tests/plenary/tmux_spec.lua"
	@nvim --headless -c "PlenaryBustedFile ./tests/plenary/tmux_capture_spec.lua"

test-selection:
	@nvim --headless -c "PlenaryBustedFile ./tests/plenary/selection_spec.lua"
