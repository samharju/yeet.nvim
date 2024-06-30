return {
    check = function()
        vim.health.start("yeet.nvim")

        local out = vim.fn.systemlist("tmux list-sessions")
        if vim.v.shell_error ~= 0 then
            if vim.v.shell_error == 1 then
                vim.health.warn(out[1], {
                    "Start tmux server to enable tmux integration.",
                })
            elseif vim.v.shell_error == 127 then
                vim.health.warn(out[1], {
                    "Install tmux to enable tmux integration.",
                })
            end
        else
            vim.health.ok("tmux server running")
        end

        local yeet = require("yeet")

        if yeet.config.use_cache_file then
            vim.health.info("using cache: " .. yeet.config.cache())
        end
    end,
}
