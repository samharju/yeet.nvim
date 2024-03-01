local buffer = require("yeet.buffer")
local defaultconf = require("yeet.conf")
local log = require("yeet.dev")
local tmux = require("yeet.tmux")

---@class YeetPlugin
local M = {
    config = defaultconf,
    _target = nil,
    _cmd = nil,
}

--- Apply user config and create user command.
---@param opts PartialYeetConfig?
function M.setup(opts)
    M.config = vim.tbl_extend("force", defaultconf, opts or {})
    log("setup:", M.config)
    M._create_user_command()
end

--- Fetch available term buffers and tmux panes.
--- Open prompt for selection.
---@param callback? function
function M.select_target(callback)
    local targets = M._update()

    log("updated targets:", targets)

    vim.ui.select(targets, {
        prompt = string.format("Yeet '%s' to:", M._cmd),
        format_item = function(item)
            if M._target ~= nil and (item.channel == M._target.channel) then
                return ">> " .. item.name
            end

            return "   " .. item.name
        end,
    }, function(choice)
        if choice == nil then
            return
        end
        log(choice)

        if choice.type == "new" then
            M._set_target(buffer.new())
        else
            log("_set_target", choice)
            M._set_target(choice)
        end

        if callback ~= nil then
            log("callback")
            callback()
        end
    end)
end

---Yeet given command to selected target.
---If no target is selected, prompt for selection.
---If no command is given, use current in-memory command.
-- If no in-memory command is set, prompt for command.
---@param cmd? string
---@param opts? PartialYeetConfig
function M.execute(cmd, opts)
    opts = vim.tbl_extend("force", M.config, opts or {})

    cmd = cmd or M._cmd

    if cmd ~= nil then
        M.set_cmd(cmd)
    else
        -- No command given and no cache, prompt for command and
        -- callback to execute
        log("no command, callback after set_cmd")
        return M.set_cmd(nil, function()
            M.execute(nil, opts)
        end)
    end

    if M._target == nil then
        -- Prompt for target and callback to execute
        log("no target, callback after select_target")
        return M.select_target(function()
            M.execute(cmd, opts)
        end)
    end

    -- Command and target are always set at this point
    log("execute", cmd)

    local ok = false

    if M._target.type == "buffer" then
        ok = buffer.send(M._target, cmd, opts)
    elseif M._target.type == "tmux" then
        ok = tmux.send(M._target, cmd, opts)
    end

    log("execute", cmd, "to", M._target.name, "ok:", ok)
    if ok and opts.notify_on_success then
        vim.notify(
            string.format("[yeet.nvim]: %s => %s", cmd, M._target.shortname)
        )
    end
end

---@param input string
---@return string subcommand
---@return string? arg
local function split_cmd(input)
    local subcommand = string.find(input, " ")
    if subcommand ~= nil then
        local cmd = string.sub(input, 1, subcommand - 1)
        local arg = string.sub(input, subcommand + 1)
        return cmd, arg
    end
    return input, nil
end

local onwrite = nil
local grp = vim.api.nvim_create_augroup("yeet", { clear = true })

function M.toggle_post_write()
    if onwrite ~= nil then
        vim.api.nvim_del_autocmd(onwrite)
        onwrite = nil
        return
    end
    onwrite = vim.api.nvim_create_autocmd("BufWritePost", {
        group = grp,
        pattern = "*",
        callback = function()
            M.execute()
        end,
    })
end

--- Set current in-memory command
---@param cmd? string
---@param callback? function
function M.set_cmd(cmd, callback)
    log("set command:", cmd)
    if cmd ~= nil then
        M._cmd = cmd
        return
    end

    vim.ui.input({
        prompt = "Current yeet: ",
        default = M._cmd,
    }, function(input)
        if input == nil then
            return
        end
        log(input)
        M._cmd = input

        if callback ~= nil then
            log("callback")
            callback()
        end
    end)
end

---@param cmd Target
function M._set_target(cmd)
    M._target = cmd
    log("target now:", M._target)
end

---@return Target[]
function M._update()
    local options = {
        { type = "new", name = "[create new term buffer]", channel = 0 },
    }
    for _, v in ipairs(buffer.get_channels()) do
        table.insert(options, v)
    end
    for _, v in ipairs(tmux.get_panes(M.config)) do
        table.insert(options, v)
    end

    return options
end

local function yeetcmd(args)
    local subcmd, arg = split_cmd(args.args)
    if subcmd == "" or subcmd == "execute" then
        if arg ~= nil then
            error("subcommand execute does not accept arguments")
        end
        M.execute()
    elseif subcmd == "select_target" then
        if arg ~= nil then
            error("subcommand select_target does not accept arguments")
            return
        end
        M.select_target()
    elseif subcmd == "set_cmd" then
        M.set_cmd(arg)
    elseif subcmd == "toggle_post_write" then
        if arg ~= nil then
            error("subcommand toggle_post_write does not accept arguments")
            return
        end
        M.toggle_post_write()
    end
end

function M._create_user_command()
    vim.api.nvim_create_user_command("Yeet", yeetcmd, {
        nargs = "?",
        complete = function()
            return { "select_target", "execute", "set_cmd", "toggle_post_write" }
        end,
    })
end

return M
