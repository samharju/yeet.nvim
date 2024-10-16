return function()
    vim.cmd.normal("!<Esc>")
    local start = vim.fn.getpos("'<")
    local finish = vim.fn.getpos("'>")

    local lines = vim.fn.getline(start[2], finish[2])
    if type(lines) == "string" then
        lines = { lines }
    end

    -- drop empty lines, keep last though
    for i = #lines, 1, -1 do
        if i ~= #lines and lines[i] == "" then
            table.remove(lines, i)
        end
    end
    if #lines == 0 then
        return
    end

    -- drop indentation
    local ws = 9999
    for _, line in ipairs(lines) do
        local lws = line:match("^%s*")
        if lws and #lws < ws then
            ws = #lws
        end
    end

    for i, line in ipairs(lines) do
        lines[i] = line:sub(ws + 1)
    end

    return table.concat(lines, "\n")
end
