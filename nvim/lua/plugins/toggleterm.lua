local i18n = require("config.i18n")

local floating_terminal

local function toggle_floating_terminal()
    if not floating_terminal then
        local Terminal = require("toggleterm.terminal").Terminal
        floating_terminal = Terminal:new({
            direction = "float",
            float_opts = {
                border = "curved",
                winblend = 5,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                },
            },
        })
    end
    floating_terminal:toggle()
end

local function setup_terminal_keymaps(buffer)
    local opts = { buffer = buffer, silent = true }
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
    vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
    vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
end

return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            {
                "<leader>tf",
                toggle_floating_terminal,
                desc = i18n.t("keymaps.terminal_float_center"),
            },
        },
        opts = {
            hide_numbers = true,
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "toggleterm",
                callback = function(event)
                    setup_terminal_keymaps(event.buf)
                end,
            })
        end,
    },
}
