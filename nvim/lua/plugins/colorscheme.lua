return {
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "custom_colorblind_theme",
        },
    },
    -- The colorscheme uses Lush's HSL and theme DSL directly. Keep this eager so
    -- it is available when LazyVim applies the startup colorscheme.
    {
        "rktjmp/lush.nvim",
        lazy = false,
        priority = 1000,
    },
}
