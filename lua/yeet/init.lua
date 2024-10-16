---@toc yeet.nvim

local buffer = require("yeet.buffer")
local c = require("yeet.conf")
local cache = require("yeet.cache")
local get_selection = require("yeet.selection")
local log = require("yeet.dev")
local tmux = require("yeet.tmux")

local M = {
    ---@type Config
    config = c.defaults,
    ---@type string
    _cache = c.cachepath(),
    ---@type Target?
    _target = nil,
    ---@type string?
    _cmd = nil,
}

---@mod yeet-setup SETUP

---@class Options
---@field yeet_and_run? boolean Execute command immediately.
---@field clear_before_yeet? boolean Clear buffer before execution.
---@field interrupt_before_yeet? boolean Hit C-c before execution.
---@field notify_on_success? boolean Print success notifications.
---@field warn_tmux_not_running? boolean Print warning message if tmux is not up.
---@field use_cache_file? boolean Use cache-file for persisting commands.
---@field cache? fun():string Resolver for cache file.
---@field cache_window_opts? table | fun():table win_config passed to |nvim_open_win()|
---@see standard-path
---@see uv.cwd
---@see vim.api.keyset.win_config

---@brief [[
---Default cache solution is to create a cwd-specific file in
---stdpath("cache") .. "/yeet/". Modify cache file location with custom cache-function.
---Example of using a file named ".yeet" in project root:
--->lua
---   {
---     cache = function()
---       -- project local cache, maybe add to global .gitignore for commit hygiene
---       return ".yeet"
---     end
---   }
---<
---Keep the builtin naming scheme for cache files, but in different location:
---
--->lua
---   {
---     cache = function()
---       return require("yeet.conf").cachepath("~/some/dir")
---     end
---   }
---<
---@brief ]]

---Apply user config and register |yeet-command|.
---@param opts? Options Custom settings.
function M.setup(opts)
    log("user config:", opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    M._cache = M.config.cache()

    local subcmds = {
        select_target = M.select_target,
        execute = M.execute,
        set_cmd = M.set_cmd,
        toggle_post_write = M.toggle_post_write,
        list_cmd = M.list_cmd,
        execute_selection = M.execute_selection,
    }

    vim.api.nvim_create_user_command("Yeet", function(args)
        local subcmd = args.args
        if subcmd == "" then
            subcmd = "execute"
        end
        if subcmds[subcmd] ~= nil then
            M[subcmd]()
            return
        end
        vim.notify(
            string.format("Unknown subcommand: %s", subcmd),
            vim.log.levels.ERROR
        )
    end, {
        nargs = "?",
        complete = function()
            local k = {}
            for key, _ in pairs(subcmds) do
                table.insert(k, key)
            end
            return k
        end,
    })
end

---@mod yeet-command USER COMMAND
---
---@brief [[
---:Yeet <subcommand?>
---
---     Subcommands:
---         select_target       => |yeet.select_target|
---         execute             => |yeet.execute|
---         toggle_post_write   => |yeet.toggle_post_write|
---         set_cmd             => |yeet.set_cmd|
---         list_cmd            => |yeet.list_cmd|
---         execute_selection   => |yeet.execute_selection|
---
---Yeet is a wrapper for |yeet| api mostly for trying out the api functionality
---and for those calls that are not needed often enough to deserve a dedicated keymap.
---No subcommand will default to |yeet.execute|.
---@brief ]]

---@mod yeet API
---@brief [[
---Use these calls with your preferred keymaps.
---@brief ]]

---@param cmd Target
local function set_target(cmd)
    M._target = cmd
    log("target now:", M._target)
end

---@return Target[]
local function refresh_targets()
    local options = {
        { type = "new_term", name = "[create new term buffer]", channel = 0 },
    }

    if os.getenv("TMUX") ~= nil then
        table.insert(
            options,
            { type = "new_tmux", name = "[create new tmux pane]", channel = 0 }
        )
    end
    for _, v in ipairs(buffer.get_channels()) do
        table.insert(options, v)
    end
    for _, v in ipairs(tmux.get_panes(M.config)) do
        table.insert(options, v)
    end

    return options
end

---Fetch available term buffers and tmux panes. Open prompt for target selection.
---If callback given, it is called after target selection without any arguments.
---Callback is used internally to chain api calls, so it can be ignored.
---@param callback? fun()
function M.select_target(callback)
    local targets = refresh_targets()

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
        log("selection:", choice)

        if choice.type == "new_term" then
            set_target(buffer.new())
        elseif choice.type == "new_tmux" then
            set_target(tmux.new())
        else
            log("_set_target", choice)
            set_target(choice)
        end

        if callback ~= nil then
            callback()
        end
    end)
end

---Send given command to selected target.
---
---Flow:
---     1. If no command given or previously selected, opens prompt
---     2. If no target previously selected, opens prompt
---     3. Sends command to target
---
---If command or target needs to be changed from what was given in the first
---call of this function, use |yeet.select_target| for target and
---|yeet.set_cmd| or |yeet.list_cmd| for command.
---
---Prefix command with `C-c` to send interrupt before entering command.
---Prefix command with `init:` to run command only if target is new.
---
---Options given are used for only this invocation, options registered
---in setup are not modified permanently.
---@param cmd? string
---@param opts? Options
---@usage [[
---require("yeet").execute()
---require("yeet").execute("echo hello world")
---require("yeet").execute(nil, { clear_before_yeet = false })
----- send interrupt before execution, local for this command
---require("yeet").execute("C-c python run_server.py")
----- use option version for interrupt for any command
---require("yeet").execute(nil, { interrupt_before_yeet = true })
---@usage ]]
function M.execute(cmd, opts)
    opts = vim.tbl_extend("force", M.config, opts or {})

    cmd = cmd or M._cmd

    if cmd == nil then
        -- No command given and no cache, prompt for command and
        -- callback to execute
        if M.config.use_cache_file then
            log("open cache")
            cache.open(
                M._cache,
                M.config.cache_window_opts,
                nil,
                function(choice)
                    log("open cache callback")
                    M.execute(choice, opts)
                end
            )
            return
        end

        log("no command")
        M.set_cmd(nil, function()
            log("no command callback")
            M.execute(nil, opts)
        end)
        return
    else
        if M._cmd ~= cmd then
            M.set_cmd(cmd)
        end
    end

    if M._target == nil then
        -- Prompt for target and callback to execute
        log("no target")
        return M.select_target(function()
            log("no target callback")
            M.execute(cmd, opts)
        end)
    end

    if M._target.new and M.config.use_cache_file then
        local init_cmds = cache.get_init_commands(M._cache)
        if init_cmds ~= "" then
            cmd = init_cmds .. "\n" .. cmd
        end
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
    elseif ok then
        log("executed successfully")
    else
        log("failed send, update target")
        M.select_target(function()
            log("failed send callback")
            M.execute(cmd, opts)
        end)
    end
end

local onwrite = nil
local grp = vim.api.nvim_create_augroup("yeet", { clear = true })

---Toggle autoyeeting, calls |yeet.execute| on |BufWritePost|.
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

---Prompts for command. Sets in-memory command which will be used for following
---calls for |yeet.execute|. Callback is called after setting the command.
---@param cmd? string
---@param callback? fun()
---@usage [[
---require("yeet").set_cmd()
---require("yeet").set_cmd("echo hello world")
---require("yeet").set_cmd(nil, require("yeet").execute)
---@usage ]]
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
            callback()
        end
    end)
end

---List commands stored in cache file. File will be opened to a new window with
---configuration defined in setup options. Optional filepath can be given to
---bypass what was given in setup.
---
---Commands prefixed with `init:` are considered init commands and are
---executed automatically when target is new, before the actual command.
---
---Example cache:
---
---     init: echo "init command"
---     init: echo "init command2"
---     echo "main command"
---
---Remaps:
---   Normal mode:
---     <CR> -> Calls |yeet.execute| with current line as command.
---
---   Visual mode:
---     <CR> -> Calls |yeet.execute| with visual-line selection as
---             command. Same behaviour as |yeet.execute_selection|.
---@param filepath? string
---@usage [[
---require("yeet").list_cmd()
---require("yeet").list_cmd(".yeet")
---require("yeet").list_cmd("~/some/dir/commands.txt")
---@usage ]]
function M.list_cmd(filepath)
    cache.open(
        filepath or M._cache,
        M.config.cache_window_opts,
        M._cmd,
        M.execute
    )
end

---Grab current or last visual selection and call |yeet.execute| with
---provided options.
---
---Does not support partial ranges, uses all the lines that are in the scope
---of the selection. Removes empty lines and indent common to all lines, making
---it behave nice when sending code snippets to a repl.
---@param opts? Options
function M.execute_selection(opts)
    local out = get_selection()
    M.execute(out, opts)
end

return M
