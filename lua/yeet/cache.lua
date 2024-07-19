local log = require("yeet.dev")

M = {}

-- Open cache file.
---@param path string filepath for command list
---@param window_opts vim.api.keyset.win_config
---@param cmd? string
---@param callback? fun(cmd:string) callback to call with selected command as input
function M.open(path, window_opts, cmd, callback)
    log(path, cmd)
    local win = vim.api.nvim_open_win(0, true, window_opts)
    vim.cmd.e(path)
    local buf = vim.api.nvim_get_current_buf()
    if cmd ~= nil then
        vim.fn.matchadd("DiffText", cmd)
    end

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
end

return M
