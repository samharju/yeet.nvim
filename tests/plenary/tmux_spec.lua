require("plenary.busted")

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
    local target = tmux.new_pane(require("yeet").config)
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

    before_each(function()
        print("before_each")
        local res = vim.system({
            "tmux",
            "send-keys",
            "-t",
            string.format("%%%s", target.channel),
            "clear",
            "ENTER",
        }):wait()
        assert.is.True(res.code == 0)
        vim.wait(250)
    end)

    local function assert_output(expected)
        local res = vim.system({
            "tmux",
            "capture-pane",
            "-t",
            string.format("%%%s", target.channel),
            "-p",
        }):wait()
        assert.is.True(res.code == 0)

        local lines = {}
        for line in res.stdout:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        local lineno = 0
        for i = #lines, 1, -1 do
            if lines[i] ~= "" then
                lineno = i
                break
            end
        end

        local out = {}

        for i = 1, lineno do
            out[#out + 1] = lines[i]
        end
        assert.is.equal(expected, table.concat(lines, "\n"))
        vim.wait(250)
    end

    it("yeets and runs", function()
        yeet.execute("echo hello")
        assert_output("$ echo hello\nhello\n$")
    end)

    it("yeets and does not run", function()
        yeet.execute("echo hello", { yeet_and_run = false })
        assert_output("$ echo hello")
        yeet.execute("clear")
    end)

    it("escapes $variables", function()
        yeet.execute("ASD=123 && echo $ASD")
        assert_output("$ ASD=123 && echo $ASD\n123\n$")
    end)

    it("interrupts with C-c", function()
        yeet.execute("sleep 100")
        yeet.execute("C-c echo hello")
        assert_output("$ sleep 100\n^C\n$ echo hello\nhello\n$")
    end)

    it("interrupts with option", function()
        yeet.execute("sleep 200")
        yeet.execute("echo hello", { interrupt_before_yeet = true })
        assert_output("$ sleep 200\n^C\n$ echo hello\nhello\n$")
    end)

    it("accepts multiple commands sent", function()
        yeet.execute("echo 1\necho 2\necho 3")
        assert_output("$ echo 1\n1\n$ echo 2\n2\n$ echo 3\n3\n$")
    end)

    it("clears", function()
        yeet.execute("echo test")
        yeet.execute("echo 4", { clear_before_yeet = true })
        assert_output("$ echo 4\n4\n$")
    end)

    print("teardown")
    vim.system({
        "tmux",
        "kill-pane",
        "-t",
        string.format("%%%s", target.channel),
    }):wait()
end)
