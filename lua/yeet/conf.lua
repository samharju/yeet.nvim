---@class Config
---@field yeet_and_run boolean
---@field clear_before_yeet boolean
---@field notify_on_success boolean
---@field warn_tmux_not_running boolean
---@field use_cache_file boolean
---@field cache fun():string
---@field cache_window_opts table

local log = require("yeet.dev")

local cache = vim.fn.stdpath("cache") .. "/yeet"

local C = {}

---@param root? string
function C.cachepath(root)
    cache = root or cache
    cache = vim.fn.expand(cache)
    if vim.fn.isdirectory(cache) ~= 1 then
        vim.fn.mkdir(cache, "p")
    end
    local project = vim.uv.cwd()
    if project == nil then
        return ".yeet"
    end

    local sub = project:gsub("/", "_")
    local p = vim.fn.fnameescape(cache .. "/" .. sub)
    log("using cache:", p)
    return p
end

local width = math.ceil(0.6 * vim.o.columns)
local height = 15

---@type Config
C.defaults = {
    yeet_and_run = true,
    clear_before_yeet = true,
    notify_on_success = true,
    warn_tmux_not_running = false,
    cache = C.cachepath,
    use_cache_file = true,
    cache_window_opts = {
        relative = "editor",
        row = (vim.o.lines - height) * 0.5,
        col = (vim.o.columns - width) * 0.5,
        width = width,
        height = height,
        border = "single",
        title = "Yeet",
    },
}

return C
