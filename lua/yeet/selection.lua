return function()
    vim.cmd.normal("!<Esc>")
    local start = vim.fn.getpos("'<")
    local finish = vim.fn.getpos("'>")

    local lines = vim.fn.getline(start[2], finish[2])
    if type(lines) == "string" then
        lines = { lines }
    end

    local trailing_nl = 0
    local trailing = true

    if start[2] == finish[2] then
        lines[1] = lines[1]:sub(start[3], finish[3])
    else
        lines[1] = lines[1]:sub(start[3])
        lines[#lines] = lines[#lines]:sub(1, finish[3])

        -- drop empty lines,
        -- but keep trailing for more consistent evaluation
        -- of snippets
        for i = #lines, 1, -1 do
            if lines[i] == "" then
                if trailing then
                    trailing_nl = trailing_nl + 1
                end
                table.remove(lines, i)
            else
                trailing = false
            end
        end
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

    if trailing_nl > 0 then
        for _ = 1, trailing_nl do
            lines[#lines + 1] = ""
        end
    end

    return table.concat(lines, require("yeet.conf").nl)
end
