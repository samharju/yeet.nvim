local get_selection = require("yeet.selection")
local log = require("yeet.dev")

M = {}

-- Open cache file.
---@param path string filepath for command list
---@param window_opts vim.api.keyset.win_config | fun():vim.api.keyset.win_config
---@param cmd? string
---@param callback? fun(cmd:string) callback to call with selected command as input
function M.open(path, window_opts, cmd, callback)
    local win_opts = {}
    if type(window_opts) == "function" then
        win_opts = window_opts()
    else
        win_opts = window_opts
    end
    log(path, cmd)
    local win = vim.api.nvim_open_win(0, true, win_opts)
    vim.cmd.e(path)
    local buf = vim.api.nvim_get_current_buf()
    if cmd ~= nil then
        local lines = vim.split(cmd, "\r?\n")
        for _, line in ipairs(lines) do
            vim.fn.matchadd("DiffText", vim.fn.escape(line, "\\"))
        end
    end

    vim.fn.matchadd("Special", "^init:")

    local function close()
        if vim.bo.modified then
            vim.cmd("silent w")
        end
        vim.api.nvim_buf_delete(buf, { force = true })
    end

    vim.api.nvim_create_autocmd("BufLeave", {
        callback = close,
        buffer = buf,
    })

    vim.keymap.set("n", "<Esc>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("n", "<CR>", function()
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1

        local choice = vim.api.nvim_buf_get_text(0, row, 0, row, -1, {})
        if callback ~= nil then
            callback(choice[1])
        end
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("v", "<CR>", function()
        local choice = get_selection()
        if callback ~= nil and choice ~= nil then
            callback(choice)
        end
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })
end

---@param path string filepath for command list
---@param init? boolean include init commands
---@return table
function M.read_cache(path, init)
    local file = io.open(path, "r")
    if file == nil then
        return {}
    end
    local commands = {}
    for line in file:lines() do
        if init == false then
            local _, cmd_idx = string.find(line, "^init:%s*")
            if cmd_idx == nil then
                table.insert(commands, line)
            end
        else
            table.insert(commands, line)
        end
    end
    file:close()
    return commands
end

-- Open cache file.
---@param path string filepath for command list
---@return string
function M.get_init_commands(path)
    local commands = M.read_cache(path)

    local exec = {}

    for _, cmd in ipairs(commands) do
        local _, cmd_idx = string.find(cmd, "^init:%s*")
        if cmd_idx ~= nil then
            table.insert(exec, cmd:sub(cmd_idx + 1))
        end
    end
    return table.concat(exec, "\n")
end
return M
