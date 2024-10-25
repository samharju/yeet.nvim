
test: test-buffer test-tmux

test-buffer:
	@nvim --headless -c "PlenaryBustedDirectory ./tests/plenary/buffer_spec.lua { sequential=true }"
	@nvim --headless -c "PlenaryBustedDirectory ./tests/plenary/buffer_capture_spec.lua { sequential=true }"

test-tmux:
	@[ -z "$$TMUX" ] && echo "tmux is not running" && exit 1 || true
	@nvim --headless -c "PlenaryBustedDirectory ./tests/plenary/tmux_spec.lua { sequential=true }"
	@nvim --headless -c "PlenaryBustedDirectory ./tests/plenary/tmux_capture_spec.lua { sequential=true }"
