local log = require("yeet.dev")

local M = {}

---Create new term buffer in vertical split.
---@return Target
function M.new()
    vim.cmd("vert split")
    vim.cmd.terminal()

    local buf = vim.api.nvim_get_current_buf()

    ---@type Target
    local termtarget = {
        buffer = buf,
        channel = vim.api.nvim_buf_get_option(buf, "channel"),
        name = vim.api.nvim_buf_get_name(buf),
        shortname = string.format("buffer: %s", buf),
        type = "buffer",
    }
    log("created", termtarget)

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
            }

            table.insert(chans, c)
        end
    end

    return chans
end

---Send command to target term buffer.
---@param target Target
---@param cmd string
---@param opts YeetConfig
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

    if opts.clear_before_yeet then
        log("clear")
        vim.api.nvim_chan_send(target.channel, "clear\n")
    end

    if opts.yeet_and_run then
        log("nl")
        cmd = cmd .. "\n"
    end

    log("send channel:", target.channel, "cmd:", cmd)
    vim.api.nvim_chan_send(target.channel, cmd)
    return true
end

return M
