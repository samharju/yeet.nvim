# Yeet.nvim

<!-- vim-markdown-toc GitLab -->

* [Usecase](#usecase)
* [Installation](#installation)
* [Usage](#usage)
  * [Example keymappings](#example-keymappings)
* [Configuration](#configuration)
* [Harpoon](#harpoon)

<!-- vim-markdown-toc -->

## Usecase

![tmux2](https://github.com/user-attachments/assets/51e8bcf9-2e68-40f6-a88a-f5f9cde5f42f)

Plugin for running shell commands in terminal buffers or tmux panes.

There are many great plugins for integrating test tools and build systems into Neovim. I wanted to
have something super simple that works out of the box for any language or project by just utilizing
existing basic bash commands, shell scripts and makefiles, with absolutely zero configuration.
Just open a menu, write command, execute somewhere. It's a bonus to have project local command
history also available when needed.

Yeet sends the command provided to whatever terminal buffer or tmux pane selected as target. There
is no feedback loop, so indication of success or failure of given task is not given. After initial
command/target selection just keep hammering `:Yeet` or your preferred keymap. You can manually
parse the output of last command through errorformat with `:Yeet setqflist` or your keymaps.

Demo:

https://github.com/user-attachments/assets/de628d05-d314-4ba5-a948-a6f6bd8db646

## Installation

<details>
 <summary>lazy.nvim</summary>

```lua
{
    "samharju/yeet.nvim",
    dependencies = {
        "stevearc/dressing.nvim", -- optional, provides sane UX
    },
    version = "*", -- use the latest release, remove for master
    cmd = "Yeet",
    opts = {},
}
```

</details>

<details>
 <summary>packer.nvim</summary>

```lua
use({
    "samharju/yeet.nvim",
    requires = {
        "stevearc/dressing.nvim", -- optional, provides sane UX
    },
    tag = "*", -- use the latest release, remove for master
    cmd = "Yeet",
    config = function()
        require("yeet").setup({})
    end,
})
```

</details>

## Usage

- See user command documentation: `:h yeet-command`

- See api documentation: `:h yeet`

- See full documentation in github: [doc/yeet.txt](doc/yeet.txt)

Options can be passed directly to `Yeet.execute` for overriding something for specific command.
If you often need the same chore command in many projects, you can create a keymap with fixed
command:

```lua
vim.keymap.set("n", "<leader>yy", function()
    require("yeet").execute(
        "source venv/bin/activate",
        { clear_before_yeet = false }
    )
end)
```

Or you can use commands with `init:`-prefix in cache. These commands are executed first on a new
target created from the target prompt. Execution order for init commands is the same as in the
buffer.

<details>

<summary>Example init flow</summary>

With a cache buffer like this:

```
pytest -v -m fast
init: source venv/bin/activate
init: cd src
```

If first command is selected and then a new target created from the target list, executed commands
are:

```bash
source venv/bin/activate
cd src
pytest -v -m fast
```

</details>

### Example keymappings

<details>

<summary>lazy.nvim style</summary>

```lua
{
    "samharju/yeet.nvim",
    keys = {
        {
            -- Pop command cache open.
            "<leader><BS>", function() require("yeet").list_cmd() end,
        },
        {
            -- Douple tap \ to yeet at something.
            "\\\\",
            function() require("yeet").execute() end,
        },
        {
            -- Run command without clearing terminal, interrupt previous command.
            "<leader>\\",
            function() require("yeet").execute(nil, { clear_before_yeet = false, interrupt_before_yeet = true, }) end,
        },
        {
            -- Yeet visual selection. Useful sending code to a repl or running multiple shell commands.
            -- Using yeet_and_run = true and clear_before_yeet = false heavily suggested, if not
            -- already set in setup.
            "\\\\",
            function() require("yeet").execute_selection({ yeet_and_run = true, clear_before_yeet = false, }) end,
            mode = { "v" },
        },
        {
            -- Open target selection.
            "<leader>yt",
            function() require("yeet").select_target() end,
        },
        {
            -- Toggle autocommand for yeeting after write.
            "<leader>yo",
            function() require("yeet").toggle_post_write() end,
        },
        {
            -- Parse last command output with current vim.o.errorformat and send them to quickfix.
            "<leader>ye",
            function() require("yeet").setqflist({ open = true }) end,
        },
    },
}
```

</details>

<details>
 <summary>Builtin</summary>

```lua
-- Pop command cache open.
vim.keymap.set("n", "<leader><BS>", require("yeet").list_cmd)
-- Douple tap \ to yeet at something.
vim.keymap.set("n", "\\\\", require("yeet").execute)
-- Run command without clearing terminal, interrupt previous command.
vim.keymap.set("n", "<leader>\\", function()
    require("yeet").execute(
        nil,
        { clear_before_yeet = false, interrupt_before_yeet = true }
    )
end)
-- Yeet visual selection. Useful sending code to a repl or running multiple shell commands.
-- Using yeet_and_run = true and clear_before_yeet = false heavily suggested, if not
-- already set in setup.
vim.keymap.set("v", "\\\\", function()
    require("yeet").execute_selection({
        yeet_and_run = true,
        clear_before_yeet = false,
    })
end)
-- Open target selection.
vim.keymap.set("n", "<leader>yt", require("yeet").select_target)
-- Toggle autocommand for yeeting after write.
vim.keymap.set("n", "<leader>yo", require("yeet").toggle_post_write)
-- Parse last command output with current vim.o.errorformat and send them to quickfix.
vim.keymap.set("n", "<leader>ye", function()
    require("yeet").setqflist({ open = true })
end)
```

</details>

## Configuration

Default options:

```lua
{
    opts = {
        -- Send <CR> to channel after command for immediate execution.
        yeet_and_run = true,
        -- Send C-c before execution
        interrupt_before_yeet = false,
        -- Send 'clear<CR>' to channel before command for clean output.
        clear_before_yeet = true,

        -- Yeets pop a vim.notify by default if you have one of these available
        -- and configured to override `vim.notify`:
        --   noice.nvim, nvim-notify, fidget.nvim
        -- Force success notifications on or off by setting true/false:

        --notify_on_success = false,

        -- Print warning if pane list could not be fetched, e.g. tmux not running.
        warn_tmux_not_running = false,
        -- Command used by tmux to create a new pane
        tmux_split_pane_command = "tmux split-window -dhPF  '#D'",
        -- Retries the last used target if the target is unavailable (e.g., tmux pane closed).
        -- Useful for maintaining workflow without re-selecting the target manually.
        -- Works with: term buffers, tmux panes, tmux windows
        retry_last_target_on_failure = false,
        -- Hide neovim term buffers in `yeet.select_target`
        hide_term_buffers = false,
        -- Resolver for cache file
        cache = function()
           -- resolves project path and uses stdpath("cache")/yeet/<project>, see :h yeet
        end

        -- Open cache file instead of in memory prompt.
        use_cache_file = true

        -- Window options for cache float
        cache_window_opts = function()
           -- returns a default config for vim.api.nvim_open_win with width
           -- of max 120 columns and height of 15 lines. See yeet/conf.lua.
        end,
    }
})
```

## Harpoon

Implementing some kind of Yeet-specific logic for keeping track of project local commands, syncing
them on disk etc. extra hustle wasn't earlier on the feature list. I used the newly reworked
[harpoon2](https://github.com/ThePrimeagen/harpoon) for persistence backend for my commands. Harpoon
caches project specific named lists, so you can just open the list, have it run `Yeet.execute` on
select and then just keep repeating that latest command with your preferred keymap for
`Yeet.execute`. You can also use numerous list customization features, list local keymaps etc with
harpoon.

<details>

<summary>Example config</summary>

```lua
{
    "theprimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "samharju/yeet.nvim",
    },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup({
            yeet = {
                select = function(list_item, _, _)
                    require("yeet").execute(list_item.value)
                end,
            },
        })

        vim.keymap.set( "n", "<leader><BS>",
            function() harpoon.ui:toggle_quick_menu(harpoon:list("yeet")) end
        )

        -- other harpoon keymaps etc
        -- ...
    end,

}

```

</details>
