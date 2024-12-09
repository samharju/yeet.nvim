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
})

describe("tmux target", function()
    local tmux = require("yeet.tmux")
    local target = tmux.new_pane()
    yeet._target = target

    vim.system({
        "tmux",
        "send-keys",
        "-t",
        string.format("%%%s", target.channel),
        "bash",
        "ENTER",
        "PS1='$ '",
        "ENTER",
    }):wait()
    print("wait for bash")
    vim.wait(1000)

    it("captures last output", function()
        yeet.execute("echo test1")
        vim.wait(250)
        yeet.execute("echo test2")
        vim.wait(250)
        yeet.execute("echo test3\necho test4")
        vim.wait(250)

        yeet.setqflist({ open = false, errorfile = fname })
        local data = io.open(fname):read("*a")
        assert.is.equal("$ echo test3\ntest3\n$ echo test4\ntest4\n$\n", data)
    end)

    print("teardown")
    vim.system({
        "tmux",
        "kill-pane",
        "-t",
        string.format("%%%s", target.channel),
    }):wait()
end)
