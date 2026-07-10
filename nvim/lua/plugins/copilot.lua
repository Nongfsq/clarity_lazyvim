local enabled = vim.env.CLARITY_COPILOT == "1"

return {
    {
        "zbirenbaum/copilot.lua",
        cond = enabled,
        cmd = "Copilot",
        event = "InsertEnter",
        opts = function()
            return {
                -- Respect the user's active PATH. Host/profile health remains
                -- the audit layer's responsibility; plugin setup does not scan
                -- version-manager directories or start Node probes.
                copilot_node_command = vim.fn.exepath("node"),
                suggestion = {
                    auto_trigger = true,
                    keymap = {
                        accept = false,
                        accept_word = false,
                        accept_line = false,
                        next = false,
                        prev = false,
                        dismiss = false,
                    },
                },
                panel = {
                    enabled = true,
                    auto_refresh = true,
                    keymap = {
                        jump_prev = false,
                        jump_next = false,
                        accept = false,
                        refresh = false,
                        open = false,
                    },
                },
            }
        end,
        init = function()
            local comment_fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg

            vim.api.nvim_set_hl(0, "CopilotSuggestion", {
                fg = comment_fg,
                underline = true,
            })
        end,
    },
}
