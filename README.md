# Yeet.nvim

<!-- vim-markdown-toc GitLab -->

* [Usecase](#usecase)
* [Installation](#installation)
    * [lazy](#lazy)
* [Configuration](#configuration)
* [Harpoon](#harpoon)

<!-- vim-markdown-toc -->

## Usecase

Plugin for running shell commands in terminal buffers or tmux panes.

There are many great plugins for integrating test tools and build systems into Neovim.
I wanted to have something super simple that works out of the box for any language or
project by just utilizing existing shell scripts and makefiles, with absolutely zero configuration.

Yeet sends the command provided to whatever terminal buffer or
tmux pane selected as target. There is no feedback loop, so indication of
success or failure of given task is not given. After initial command/target
selection just keep hammering `:Yeet` or your prefered keymap.

![image](https://github.com/samharju/yeet.nvim/assets/35364923/0a21786e-9506-4644-b628-8d57cebcf747)

![image](https://github.com/samharju/yeet.nvim/assets/35364923/8a63b72d-c39e-48c1-92df-5ba97eb17a3c)

![image](https://github.com/samharju/yeet.nvim/assets/35364923/e6b2f039-79c8-4207-b8d0-3f3c6629b141)

## Installation

### lazy

```lua
{
    'samharju/yeet.nvim',
    dependencies = {
        "stevearc/dressing.nvim" -- optional, provides sane UX
    },
    cmd = 'Yeet',
    opts = {},
}
```

## Configuration

Default options:

```lua
{
    opts = {
        -- Send <CR> to channel after command for immediate execution.
        yeet_and_run = true,
        -- Send 'clear<CR>' to channel before command for clean output.
        clear_before_yeet = true,
        -- Enable notify for yeets. Success notifications may be a little
        -- too much if you are using noice.nvim or fidget.nvim
        notify_on_success = true,
        -- Print warning if pane list could not be fetched, e.g. tmux not running.
        warn_tmux_not_running = false,
    }
}
```

Example keymappings:

```lua
{
    keys = {
        {
            -- Open target selection
            "<leader>yt", function() require("yeet").select_target() end,
        },
        {
            -- Update yeeted command
            "<leader>yc", function() require("yeet").set_cmd() end,
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
            -- Run command without clearing terminal
            "<leader>\\", function()
                require("yeet").execute(nil, { clear_before_yeet = false})
            end,
        }
    }
}

```

Options can be passed directly to `Yeet.execute` for overriding something for specific command.

```lua
require('yeet').execute("pytest -v --durations=5", { clear_before_yeet = false })
```

## Harpoon

Implementing some kind of Yeet-specific logic for keeping track of project
local commands, syncing them on disk etc. extra hustle is not on the feature list.
I use the newly reworked [harpoon2](https://github.com/ThePrimeagen/harpoon) for persistence
backend for my commands. Harpoon caches project specific named lists, so you can just open
the list, have it run `Yeet.execute` on select and then just keep repeating that latest
command with your preferred keymap for `Yeet.execute`.

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

![image](https://github.com/samharju/yeet.nvim/assets/35364923/48d0df0b-0b85-4f6a-9340-e06dad0f08cb)
