local WIDTH = 35
local i18n = require("config.i18n")

local function on_buffer_enter()
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "auto"
    vim.cmd("vertical resize " .. WIDTH)
end

local function append_buffer_enter_handler(opts)
    opts.event_handlers = opts.event_handlers or {}
    for _, handler in ipairs(opts.event_handlers) do
        if handler.event == "neo_tree_buffer_enter" and handler.handler == on_buffer_enter then
            return
        end
    end
    table.insert(opts.event_handlers, { event = "neo_tree_buffer_enter", handler = on_buffer_enter })
end

return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        keys = {
            {
                "<leader>e",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
                end,
                desc = i18n.t("keymaps.explorer_root"),
            },
            {
                "<leader>E",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
                end,
                desc = i18n.t("keymaps.explorer_cwd"),
            },
        },
        opts = function(_, opts)
            vim.opt.fillchars:append({ vert = "┃" })

            local delta = {
                close_if_last_window = false,
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = true,
                filesystem = {
                    filtered_items = {
                        visible = true,
                        hide_dotfiles = false,
                        hide_gitignored = false,
                    },
                    follow_current_file = { enabled = true },
                    hijack_netrw_behavior = "open_default",
                    use_libuv_file_watcher = true,
                },
                window = {
                    position = "left",
                    width = WIDTH,
                    mapping_options = {
                        noremap = true,
                        nowait = true,
                    },
                },
                default_component_configs = {
                    name = {
                        trailing_slash = false,
                        use_git_status_colors = true,
                    },
                },
            }

            local merged = vim.tbl_deep_extend("force", opts, delta)
            for key in pairs(opts) do
                opts[key] = nil
            end
            for key, value in pairs(merged) do
                opts[key] = value
            end
            append_buffer_enter_handler(opts)
            return opts
        end,
    },
}
