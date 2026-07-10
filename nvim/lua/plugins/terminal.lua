local i18n = require("config.i18n")

local function toggle_terminal()
    Snacks.terminal.toggle(nil, {
        cwd = vim.fn.getcwd(),
        win = {
            position = "float",
            border = "rounded",
            width = 0.8,
            height = 0.8,
            keys = {
                term_normal = { "<esc>", [[<C-\><C-n>]], mode = "t", desc = "Terminal normal mode" },
                nav_left = { "<C-h>", [[<Cmd>wincmd h<CR>]], mode = "t", desc = "Window left" },
                nav_down = { "<C-j>", [[<Cmd>wincmd j<CR>]], mode = "t", desc = "Window down" },
                nav_up = { "<C-k>", [[<Cmd>wincmd k<CR>]], mode = "t", desc = "Window up" },
                nav_right = { "<C-l>", [[<Cmd>wincmd l<CR>]], mode = "t", desc = "Window right" },
                nav_prefix = { "<C-w>", [[<C-\><C-n><C-w>]], mode = "t", desc = "Window command" },
            },
        },
    })
end

return {
    {
        "folke/snacks.nvim",
        keys = {
            {
                "<leader>tf",
                toggle_terminal,
                desc = i18n.t("keymaps.terminal_float_center"),
            },
        },
    },
}
