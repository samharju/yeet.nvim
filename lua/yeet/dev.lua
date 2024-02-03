if os.getenv("YEET_DEBUG") == nil then
    return function() end
end

local logfile = vim.fn.stdpath("cache") .. "/yeet.log"

local function log(...)
    local w = io.open(logfile, "a")
    if w == nil then
        vim.notify_once("yeet logging failed", vim.log.levels.ERROR)
        return
    end

    local args = { ... }
    for index, value in ipairs(args) do
        if type(value) == "table" then
            args[index] = vim.inspect(value)
        else
            args[index] = tostring(value)
        end
    end

    local msg = table.concat(args, " ")

    local s = debug.getinfo(2, "Sl")
    local file = s.source:match("lua/(.*.lua)$")
    local line = s.currentline

    w:write(string.format("[%s] %s:%s: %s\n", os.date(), file, line, msg))
    w:close()
end

return log
