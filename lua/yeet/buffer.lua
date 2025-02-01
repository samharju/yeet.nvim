local conf = require("yeet.conf")
local log = require("yeet.dev")

local M = {}

---Create new term buffer in vertical split.
---@return Target
function M.new()
    local current = vim.api.nvim_get_current_win()
    vim.cmd("vert split")
    vim.cmd.terminal()

    local buf = vim.api.nvim_get_current_buf()

    ---@type Target
    local termtarget = {
        buffer = buf,
        channel = vim.api.nvim_get_option_value("channel", { buf = buf }),
        name = vim.api.nvim_buf_get_name(buf),
        shortname = string.format("buffer: %s", buf),
        type = "buffer",
        new = true,
    }
    log("created", termtarget)

    vim.api.nvim_set_current_win(current)
    return termtarget
end

---Get all terminal buffers.
---@return Target[]
function M.get_channels()
    ---@type Target[]
    local chans = {}

    for _, chan in ipairs(vim.api.nvim_list_chans()) do
        if chan.mode == "terminal" then
            ---@type Target
            local c = {
                type = "buffer",
                channel = chan.id,
                name = vim.api.nvim_buf_get_name(chan.buffer),
                shortname = string.format("buffer: %s", chan.buffer),
                buffer = chan.buffer,
                new = false,
            }

            table.insert(chans, c)
        end
    end

    return chans
end

---Send command to target term buffer.
---@param target Target
---@param cmd string
---@param opts Config
---@return boolean ok
function M.send(target, cmd, opts)
    if not vim.api.nvim_buf_is_valid(target.buffer) then
        log("invalid target:", target)
        vim.notify(
            string.format(
                "[yeet.nvim] Invalid buffer %s, update target",
                target.buffer
            ),
            vim.log.levels.WARN
        )
        return false
    end

    local _, cc_idx = string.find(cmd, "^C%-c%s*")
    if cc_idx ~= nil then
        cmd = cmd:sub(cc_idx + 1)
    end

    if not target.new then
        if opts.interrupt_before_yeet or cc_idx ~= nil then
            log("C-c")
            vim.api.nvim_chan_send(target.channel, "" .. conf.nl)
        end
        if opts.clear_before_yeet then
            log("clear")
            vim.api.nvim_chan_send(target.channel, conf.clear .. conf.nl)
        end
    else
        target.new = false
    end

    if opts.yeet_and_run then
        log("nl")
        cmd = cmd .. conf.nl
    end

    log("send channel:", target.channel, "cmd:", cmd)
    vim.api.nvim_chan_send(target.channel, cmd)
    return true
end

---@param target Target
---@param fname string
---@param cmd string
---@return boolean
function M.capture_pane(target, fname, cmd)
    local data = vim.api.nvim_buf_get_lines(target.buffer, 0, -1, false)

    local from_str = ""
    for line in cmd:gmatch("[^\r\n\\]+") do
        from_str = line
        break
    end

    -- remove prefixes init: or C-c from the command, trailing whitespace
    from_str =
        from_str:gsub("^init:%s*", ""):gsub("^C%-c%s*", ""):gsub("%s*$", "")

    local from_line = 1
    for lineno, line in ipairs(data) do
        if line:find(from_str, 0, true) then
            from_line = lineno
        end
    end

    local f = io.open(fname, "w+")
    if f == nil then
        return false
    end

    for i = from_line, #data do
        if #data[i] ~= 0 then
            f:write(data[i] .. conf.nl)
        end
    end

    local ok = f:close()
    return ok == true
end

return M
