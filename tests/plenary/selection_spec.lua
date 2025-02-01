require("plenary.busted")

local mock = require("luassert.mock")

require("yeet")

describe("get selection", function()
    it("cleans common whitespace", function()
        local fn = mock(vim.fn, true)
        fn.getpos = function(pos)
            if pos == "'<" then
                return { 0, 1, 1, 0 }
            elseif pos == "'>" then
                return { 0, 3, 10000, 0 }
            end
        end
        fn.getline = function(_)
            return {
                "    text",
                "      text",
                "    text",
            }
        end

        local selection = require("yeet.selection")
        local got = selection()

        assert.is.equal(got, "text\n  text\ntext")
    end)

    it("cleans empty lines", function()
        local fn = mock(vim.fn, true)
        fn.getpos = function(pos)
            if pos == "'<" then
                return { 0, 1, 1, 0 }
            elseif pos == "'>" then
                return { 0, 5, 10000, 0 }
            end
        end
        fn.getline = function(_)
            return {
                "    text",
                "",
                "    text",
                "",
                "",
            }
        end

        local selection = require("yeet.selection")
        local got = selection()
        assert.is.equal(got, "text\ntext\n\n")
    end)
end)
