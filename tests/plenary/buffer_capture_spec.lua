require("plenary.busted")

local fname = os.tmpname()

local yeet = require("yeet")
yeet.setup({
    yeet_and_run = true,
    use_cache_file = false,
    clear_before_yeet = false,
    notify_on_success = false,
    interrupt_before_yeet = false,
    warn_tmux_not_running = false,
    shell = "/bin/bash"
})

describe("buffer target", function()
    local buffer = require("yeet.buffer")
    local target = buffer.new(yeet.config)
    yeet._target = target

    vim.api.nvim_chan_send(target.channel, "PS1='$ '\n")
    vim.wait(100)

    it("captures last output", function()
        yeet.execute("echo test1")
        vim.wait(100)
        yeet.execute("echo test2")
        vim.wait(100)
        yeet.execute("echo test3\necho test4")
        vim.wait(100)

        yeet.setqflist({ open = false, errorfile = fname })
        local data = io.open(fname):read("*a")
        assert.is.equal("$ echo test3\ntest3\n$ echo test4\ntest4\n$ \n", data)
    end)

    vim.api.nvim_buf_delete(target.buffer, { force = true })
end)
