---@mod yeet-conf CONF

---@class Config
---@field yeet_and_run boolean
---@field interrupt_before_yeet boolean
---@field clear_before_yeet boolean
---@field notify_on_success boolean
---@field warn_tmux_not_running boolean
---@field hide_term_buffers boolean
---@field default_target? string
---@field use_cache_file boolean
---@field cache fun():string
---@field cache_window_opts vim.api.keyset.win_config | fun():vim.api.keyset.win_config

local log = require("yeet.dev")

local cache = vim.fn.stdpath("cache") .. "/yeet"

local nl = "\n"
local clear = "clear"

if vim.fn.has("win32") == 1 then
    nl = "\r\n"
    clear = "cls"
end

local C = {
    nl = nl,
    clear = clear,
}

local function escape(cachedir, project)
    local sub = project:gsub("[/\\:]", "_")
    return vim.fn.fnameescape(cachedir .. "/" .. sub)
end

---Resolve filename for cache.
---Fallback is used if not a git project, if no fallback given,
---calls |yeet-conf.cachepath|.
---@param fallback? string
---@return string
---@usage [[
---require("yeet").setup({
---    cache = require("yeet.conf").git_root
---})
---@usage ]]
function C.git_root(fallback)
    local res = vim.system(
        { "git", "rev-parse", "--show-toplevel" },
        { text = true }
    )
        :wait()

    if res.code ~= 0 or res.stdout == nil then
        return fallback or C.cachepath()
    end

    local project = res.stdout
    assert(project ~= nil, "project root is nil")
    project = project:sub(1, #project - 1)

    local p = escape(cache, project)
    log("using cache:", p)
    return p
end

---Resolve filename for cache.
---Default root is `stdpath("cache") / yeet`, filename is generated
---from cwd.
---@param root? string
---@return string
---@usage [[
-----Keep the builtin naming scheme for cache files, but in
-----a different location:
---require("yeet").setup({
---    cache = function()
---        return require("yeet.conf").cachepath("~/some/dir")
---    end,
---})
---@usage ]]
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

    local p = escape(cache, project)
    log("using cache:", p)
    return p
end

local function check_notify_overrides()
    -- Check some common notification handling plugins, opt out
    -- if none available
    --
    if pcall(require, "noice") then
        return true
    end

    local ok, notify = pcall(require, "notify")
    if ok then
        -- only if nvim-notify is used as vim.notify
        return vim.notify == notify
    end

    if pcall(require, "fidget") then
        -- only if fidget.nvim used as vim.notify
        return require("fidget.notification").options.override_vim_notify
    end
    return false
end

---Default configuration.
---@type Config
C.defaults = {
    yeet_and_run = true,
    interrupt_before_yeet = false,
    clear_before_yeet = true,
    notify_on_success = check_notify_overrides(),
    warn_tmux_not_running = false,
    hide_term_buffers = false,
    default_target = nil,
    cache = C.cachepath,
    use_cache_file = true,
    cache_window_opts = function()
        local width = math.min(math.ceil(0.6 * vim.o.columns), 120)
        local height = math.min(15, vim.o.lines - 4)

        return {
            relative = "editor",
            row = (vim.o.lines - height) * 0.5,
            col = (vim.o.columns - width) * 0.5,
            width = width,
            height = height,
            border = "single",
            title = "Yeet",
        }
    end,
}

return C
