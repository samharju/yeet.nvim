local log = require("yeet.dev")

---@class Target
---@field type string
---@field channel integer
---@field buffer? integer
---@field name string
---@field shortname string
---@field new boolean

local M = {}

---@param cmd string
---@param on_stdout? function
---@param warn boolean
function M._job(cmd, on_stdout, warn)
    log(cmd)
    local job_id = vim.fn.jobstart(cmd, {
        stderr_buffered = true,
        stdout_buffered = true,

        on_exit = function(_, exit_code, _)
            if exit_code ~= 0 and warn then
                vim.notify(
                    string.format(
                        "[yeet.nvim] '%s...' failed",
                        string.sub(cmd, 1, 23)
                    ),
                    vim.log.levels.WARN
                )
            end
            log("exit:", exit_code)
        end,

        on_stderr = function(_, data, _)
            if not warn then
                return
            end
            for _, line in ipairs(data) do
                if line ~= "" then
                    vim.notify("[yeet.nvim] " .. line, vim.log.levels.WARN)
                end
            end
        end,

        on_stdout = on_stdout,
    })

    if job_id == 0 then
        vim.notify(
            "[yeet.nvim] invalid arguments on jobstart()",
            vim.log.levels.ERROR
        )
    elseif job_id == -1 then
        vim.notify("[yeet.nvim] tmux is not available", vim.log.levels.ERROR)
    end
    return vim.fn.jobwait({ job_id })
end

---Use send-keys to send command to tmux pane.
---@param target Target
---@param cmd string
---@param opts Config
---@return boolean ok
function M.send(target, cmd, opts)
    -- Scrolling logs in other pane puts tmux in copy mode, which blocks
    -- command execution. Try exiting that first.
    M._job(
        string.format("tmux send -t %%%s -X cancel", target.channel),
        nil,
        false
    )

    cmd = string.gsub(cmd, '"', '\\"')
    cmd = string.gsub(cmd, "%$", "\\$")
    local c = string.format('tmux send -t %%%s "%s"', target.channel, cmd)

    local _, cc_idx = string.find(cmd, "^C%-c%s*")
    if cc_idx ~= nil then
        c = string.format(
            'tmux send -t %%%s "%s"',
            target.channel,
            cmd:sub(cc_idx + 1)
        )
    end

    if not target.new then
        if opts.interrupt_before_yeet or cc_idx ~= nil then
            M._job(
                string.format("tmux send -t %%%s C-c", target.channel),
                nil,
                true
            )
        end
        if opts.clear_before_yeet then
            M._job(
                string.format("tmux send -t %%%s clear ENTER", target.channel),
                nil,
                true
            )
        end
    else
        target.new = false
    end

    if opts.yeet_and_run then
        c = c .. " ENTER"
    end

    return M._job(c, nil, true)[1] == -0
end

local listpanefmt = "#D #{session_name}:#{window_index}.#{pane_index} "
    .. "cwd: #{b:pane_current_path}"
    .. "#{?#{==:#{window_panes},1},,, "
    .. "position: #{?pane_at_top,top,#{?pane_at_bottom,bottom,}}"
    .. "#{?pane_at_left,left,#{?pane_at_right,right,}} "
    .. "#{?pane_active,(active),}}"

---Create new tmux pane in vertical split.
---@return Target
function M.new()
    local target = {}
    M._job("tmux split-window -dhPF '#D'", function(_, data, _)
        for _, line in ipairs(data) do
            local channel = line:match("^%%(%d+)")
            if channel ~= nil then
                ---@type Target
                target = {
                    channel = channel,
                    type = "tmux",
                    name = "[tmux] new",
                    shortname = "[tmux] new",
                    new = true,
                }
            end
        end
    end, false)
    return target
end

---@return Target[]
---@param opts Config
function M.get_panes(opts)
    log("update targets")

    local temp = {}
    local cmd = string.format("tmux list-panes -a -F '%s'", listpanefmt)

    M._job(cmd, function(_, data, _)
        for _, t in ipairs(data) do
            if t ~= "" then
                table.insert(temp, t)
            end
        end
    end, opts.warn_tmux_not_running)

    local current_pane = os.getenv("TMUX_PANE")

    local targets = {}
    for _, line in ipairs(temp) do
        local channel, long, short = line:match("^%%(%d+) ((.*) cwd.*)")

        if channel ~= nil and current_pane ~= "%" .. channel then
            ---@type Target
            local t = {
                channel = channel,
                type = "tmux",
                name = "[tmux] " .. long,
                shortname = "[tmux] " .. short,
                new = false,
            }
            table.insert(targets, t)
        end
    end

    return targets
end

return M
