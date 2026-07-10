local source = debug.getinfo(1, "S").source:sub(2)
local repo_root = vim.fn.fnamemodify(source, ":p:h"):gsub("\\", "/")

local function bootstrap_fail(message)
    vim.api.nvim_err_writeln(message)
    if vim.env.CLARITY_NONINTERACTIVE == "1" or #vim.api.nvim_list_uis() == 0 then
        vim.cmd("cquit 1")
    end
    error(message)
end

vim.g.clarity_repo_root = repo_root

local nested_init = repo_root .. "/nvim/init.lua"
if vim.fn.filereadable(nested_init) == 1 then
    dofile(nested_init)
    return
end

bootstrap_fail(
    "Clarity bootstrap failed: expected nested runtime at "
        .. nested_init
        .. ". Restore the repository checkout before starting Neovim."
)
