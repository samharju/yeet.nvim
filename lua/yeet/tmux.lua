local log = require("yeet.dev")

local M = {}

function M._job(cmd, on_stdout)
    log(cmd)
    local job_id = vim.fn.jobstart(cmd, {
        stderr_buffered = true,
        stdout_buffered = true,

        on_exit = function(_, exit_code, _)
            if exit_code ~= 0 then
                vim.notify(
                    string.format("[yeet.nvim] '%s' failed", cmd:sub(1, 20)),
                    vim.log.levels.WARN
                )
            end
            log("exit:", exit_code)
        end,

        on_stderr = function(_, data, _)
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
---@param opts YeetConfig
---@return boolean ok
function M.send(target, cmd, opts)
    if opts.clear_before_yeet then
        M._job(
            string.format("tmux send -t %%%s clear ENTER", target.channel),
            nil
        )
    end

    local c = string.format("tmux send -t %%%s '%s'", target.channel, cmd)

    if opts.yeet_and_run then
        c = c .. " ENTER"
    end

    return M._job(c, nil)[1] == -0
end

local prefix = "#D #{session_name}:#{window_index}.#{pane_index} cwd: #{b:pane_current_path}"
local position =
"#{?#{==:#{window_panes},1},,, position: #{?pane_at_top,top,#{?pane_at_bottom,bottom,}}#{?pane_at_left,left,#{?pane_at_right,right,}}"
local active = " #{?pane_active,(active),}}"

---@return Target[]
function M.get_panes()
    log("update targets")

    local temp = {}
    local cmd = "tmux list-panes -a -F '" .. prefix .. position .. active .. "'"
    local job_id = M._job(cmd, function(_, data, _)
        for _, t in ipairs(data) do
            if t ~= "" then
                table.insert(temp, t)
            end
        end
    end)

    vim.fn.jobwait({ job_id })

    local targets = {}
    for _, line in ipairs(temp) do
        local channel, short = line:match("^%%(%d+) (.*) cwd")

        if channel ~= nil then
            ---@type Target
            local t = {
                channel = channel,
                type = "tmux",
                name = "[tmux] " .. line,
                shortname = "[tmux] " .. short
            }
            table.insert(targets, t)
        end
    end

    return targets
end

return M
