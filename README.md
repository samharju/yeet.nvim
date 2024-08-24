# Yeet.nvim

<!-- vim-markdown-toc GitLab -->

* [Usecase](#usecase)
* [Installation](#installation)
    * [lazy](#lazy)
* [Docs](#docs)
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
command/target selection just keep hammering `:Yeet` or your preferred keymap.

Demo:



https://github.com/user-attachments/assets/de628d05-d314-4ba5-a948-a6f6bd8db646



## Installation

### lazy

```lua
{
    'samharju/yeet.nvim',
    dependencies = {
        "stevearc/dressing.nvim" -- optional, provides sane UX
    },
    version = "*", -- update only on releases
    cmd = 'Yeet',
    opts = {},
}
```

## Docs

`:h yeet.nvim` or [doc/yeet.txt](doc/yeet.txt)

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
        -- Enable notify for yeets. Success notifications may be a little
        -- too much if you are using noice.nvim or fidget.nvim
        notify_on_success = true,
        -- Print warning if pane list could not be fetched, e.g. tmux not running.
        warn_tmux_not_running = false,
        -- Resolver for cache file
        cache = function()
           -- resolves project path and uses stdpath("cache")/yeet/<project>, see :h yeet
        end
        -- Use cache.
        cache = true
        -- Window options for cache float
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
}
```

Example keymappings:

```lua
{
    keys = {
        {
            -- Pop command cache open
            "<leader><BS>",
            function() require("yeet").list_cmd() end,
        },
        {
            -- Open target selection
            "<leader>yt", function() require("yeet").select_target() end,
        },
        {
            -- Douple tap \ to yeet at something
            "\\\\", function() require("yeet").execute() end,
        },
        {
            -- Toggle autocommand for yeeting after write.
            "<leader>yo", function() require("yeet").toggle_post_write() end,
        },
        {
            -- Run command without clearing terminal, send C-c
            "<leader>\\", function()
                require("yeet").execute(nil, { clear_before_yeet = false, interrupt_before_yeet = true })
            end,
        }
    }
}

```

Options can be passed directly to `Yeet.execute` for overriding something for specific command.
If you often need the same chore command in many projects, you can create a keymap with fixed
command:

```lua
vim.keymap.set("n", "<leader>yv", function()
    require("yeet").execute(
        "source venv/bin/activate",
        { clear_before_yeet = false }
    )
end)
```

## Harpoon

Implementing some kind of Yeet-specific logic for keeping track of project local commands, syncing
them on disk etc. extra hustle wasn't earlier on the feature list. I used the newly reworked
[harpoon2](https://github.com/ThePrimeagen/harpoon) for persistence backend for my commands. Harpoon
caches project specific named lists, so you can just open the list, have it run `Yeet.execute` on
select and then just keep repeating that latest command with your preferred keymap for
`Yeet.execute`. You can also use numerous list customization features, list local keymaps etc with
harpoon.

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

