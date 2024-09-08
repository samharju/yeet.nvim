require("plenary.busted")

local tmp_out = os.tmpname()

local yeet = require("yeet")
yeet.setup({
    yeet_and_run = true,
    use_cache_file = false,
    clear_before_yeet = false,
    notify_on_success = false,
    interrupt_before_yeet = false,
    warn_tmux_not_running = false,
})

local function clean_tmux_output(file_path)
    local cmd = string.format(
        "cat %s | sed -r 's/\\x1B\\[[0-9;]*[a-zA-Z]//g'",
        file_path
    )
    local res = vim.system({
        "sh",
        "-c",
        cmd,
    }, { text = true }):wait()
    return res.stdout
end

local function assert_output(expected)
    assert.is.equal(expected, clean_tmux_output(tmp_out))
end

describe("tmux target", function()
    local tmux = require("yeet.tmux")
    local target = tmux.new()
    yeet._target = target

    vim.system({
        "tmux",
        "send-keys",
        "-t",
        string.format("%%%s", target.channel),
        "sh",
        "ENTER",
        "PS1=",
        "ENTER",
    }):wait()
    vim.wait(1000)

    before_each(function()
        local res = vim.system({
            "tmux",
            "pipe-pane",
            "-t",
            string.format("%%%s", target.channel),
            string.format("cat > %s", tmp_out),
        }):wait()
        assert.is.True(res.code == 0)
    end)

    after_each(function()
        local res = vim.system({
            "tmux",
            "pipe-pane",
        }):wait()
        assert.is.True(res.code == 0)
        res = vim.system({
            "tmux",
            "send-keys",
            "-t",
            string.format("%%%s", target.channel),
            "ENTER",
        }):wait()
        assert.is.True(res.code == 0)
        vim.wait(250)
    end)

    it("yeets and runs", function()
        yeet.execute("echo hello")
        assert_output("echo hello\nhello\n")
    end)

    it("yeets and does not run", function()
        yeet.execute("echo hello", { yeet_and_run = false })
        assert_output("echo hello")
    end)

    it("escapes $variables", function()
        yeet.execute("ASD=123 && echo $ASD")
        assert_output("ASD=123 && echo $ASD\n123\n")
    end)

    it("interrupts with C-c", function()
        yeet.execute("sleep 100")
        yeet.execute("C-c echo hello")
        assert_output("sleep 100\n^C\necho hello\nhello\n")
    end)

    it("interrupts with option", function()
        yeet.execute("sleep 200")
        yeet.execute("echo hello", { interrupt_before_yeet = true })
        assert_output("sleep 200\n^C\necho hello\nhello\n")
    end)

    it("accepts multiple commands sent", function()
        yeet.execute("echo 1\necho 2\necho 3")
        assert_output("echo 1\necho 2\necho 3\n1\n2\n3\n")
    end)

    it("clears", function()
        yeet.execute("echo 4", { clear_before_yeet = true })
        assert_output("clear\necho 4\n4\n")
    end)

    vim.system({
        "tmux",
        "kill-pane",
        "-t",
        string.format("%%%s", target.channel),
    }):wait()
end)
