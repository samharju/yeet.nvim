---@class Target
---@field type string
---@field channel integer
---@field buffer integer?
---@field name string
---@field shortname string

---@class YeetPlugin
---@field config YeetConfig
---@field _target Target?
---@field _cmd string?
--
---@class PartialYeetConfig
---@field yeet_and_run? boolean
---@field clear_before_yeet? boolean
---@field notify_on_success? boolean
---@field warn_tmux_not_running? boolean

-- Default settings.
---@class YeetConfig
local defaults = {
    -- Send <CR> to channel after command for immediate execution.
    yeet_and_run = true,
    -- Send 'clear<CR>' to channel before command for clean output.
    clear_before_yeet = true,
    -- Enable notify for yeets.
    notify_on_success = true,
    -- Print warning if pane list could not be fetched, e.g. tmux not running.
    warn_tmux_not_running = false,
}

return defaults
