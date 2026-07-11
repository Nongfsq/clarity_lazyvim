local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath:append(repo_root .. "/nvim")

local options = require("config.options")
local audit = require("config.audit")

local original_clipboard = vim.g.clipboard
local original_option = vim.o.clipboard

vim.g.clipboard = nil
assert(options.configure_clipboard({ ssh = true, display = false }) == "osc52", "plain SSH must select OSC52")
assert(vim.g.clipboard == "osc52", "OSC52 must be configured before provider use")
assert(vim.o.clipboard:find("unnamedplus", 1, true), "unnamedplus product mode must remain enabled")

vim.g.clipboard = "fixture-provider"
options.configure_clipboard({ ssh = true, display = false })
assert(vim.g.clipboard == "fixture-provider", "user clipboard override must not be replaced")

vim.g.clipboard = nil
options.configure_clipboard({ ssh = false, display = false })
assert(vim.g.clipboard == nil, "non-SSH headless session must not force OSC52")

local kind, copy, paste = audit.classify_clipboard({ provider = "pbcopy" })
assert(kind == "desktop" and copy and paste, "desktop provider classification failed")
kind, copy, paste = audit.classify_clipboard({ provider = "win32yank", wsl = true })
assert(kind == "wsl" and copy and paste, "WSL provider classification failed")
kind, copy, paste = audit.classify_clipboard({ provider = "osc52", ssh = true, forced_osc52 = true })
assert(kind == "ssh_osc52" and copy and not paste, "SSH OSC52 must promise copy but not paste")
kind, copy, paste = audit.classify_clipboard({ ssh = false })
assert(kind == "missing" and not copy and not paste, "missing provider classification failed")

vim.g.clipboard = original_clipboard
vim.o.clipboard = original_option

print("clipboard contract tests: OK")
