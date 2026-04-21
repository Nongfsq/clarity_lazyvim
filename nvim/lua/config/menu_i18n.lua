local M = {}

local i18n = require("config.i18n")

local function zh(text)
    return { zh = text }
end

local desc_translations = {
    ["Buffers"] = zh("缓冲区"),
    ["Buffers (all)"] = zh("缓冲区（全部）"),
    ["Buffer Keymaps (which-key)"] = zh("当前缓冲区键位"),
    ["Buffer Diagnostics"] = zh("当前缓冲区诊断"),
    ["Buffer Lines"] = zh("当前缓冲区内容"),
    ["Find Files (Root Dir)"] = zh("查找文件（项目根目录）"),
    ["Find Files (cwd)"] = zh("查找文件（当前目录）"),
    ["Find Files (git-files)"] = zh("查找文件（Git 已跟踪）"),
    ["Find Config File"] = zh("查找配置文件"),
    ["New File"] = zh("新建文件"),
    ["Projects"] = zh("项目列表"),
    ["Recent"] = zh("最近文件"),
    ["Recent (cwd)"] = zh("最近文件（当前目录）"),
    ["Grep (Root Dir)"] = zh("搜索文本（项目根目录）"),
    ["Grep (cwd)"] = zh("搜索文本（当前目录）"),
    ["Grep Open Buffers"] = zh("搜索已打开缓冲区"),
    ["Visual selection or word (Root Dir)"] = zh("搜索选中内容或当前单词（项目根目录）"),
    ["Visual selection or word (cwd)"] = zh("搜索选中内容或当前单词（当前目录）"),
    ["Search History"] = zh("搜索历史"),
    ["Command History"] = zh("命令历史"),
    ["Commands"] = zh("命令列表"),
    ["Autocmds"] = zh("自动命令"),
    ["Registers"] = zh("寄存器"),
    ["Jumps"] = zh("跳转历史"),
    ["Keymaps"] = zh("键位列表"),
    ["Location List"] = zh("位置列表"),
    ["Quickfix List"] = zh("快速修复列表"),
    ["Marks"] = zh("标记"),
    ["Help Pages"] = zh("帮助页面"),
    ["Highlights"] = zh("高亮组"),
    ["Icons"] = zh("图标"),
    ["Man Pages"] = zh("Man 手册"),
    ["Resume"] = zh("恢复上次搜索"),
    ["Search for Plugin Spec"] = zh("搜索插件定义"),
    ["Notification History"] = zh("通知历史"),
    ["Dismiss All Notifications"] = zh("清空全部通知"),
    ["Noice All"] = zh("Noice 全部消息"),
    ["Dismiss All"] = zh("清空全部消息"),
    ["Noice History"] = zh("Noice 历史消息"),
    ["Noice Last Message"] = zh("Noice 最后一条消息"),
    ["Noice Picker (Telescope/FzfLua)"] = zh("Noice 选择器（Telescope/FzfLua）"),
    ["Toggle Scratch Buffer"] = zh("切换临时缓冲区"),
    ["Select Scratch Buffer"] = zh("选择临时缓冲区"),
    ["Switch to Other Buffer"] = zh("切换到另一个缓冲区"),
    ["Delete Buffer"] = zh("删除缓冲区"),
    ["Delete Other Buffers"] = zh("删除其他缓冲区"),
    ["Delete Buffer and Window"] = zh("删除缓冲区并关闭窗口"),
    ["Split Window Below"] = zh("水平分屏（下方）"),
    ["Split Window Right"] = zh("垂直分屏（右侧）"),
    ["Delete Window"] = zh("关闭窗口"),
    ["New Tab"] = zh("新建标签页"),
    ["Previous Tab"] = zh("上一个标签页"),
    ["Next Tab"] = zh("下一个标签页"),
    ["Close Tab"] = zh("关闭标签页"),
    ["First Tab"] = zh("第一个标签页"),
    ["Last Tab"] = zh("最后一个标签页"),
    ["Close Other Tabs"] = zh("关闭其他标签页"),
    ["Format"] = zh("格式化"),
    ["Format Injected Langs"] = zh("格式化注入语言"),
    ["Line Diagnostics"] = zh("当前行诊断"),
    ["Diagnostics"] = zh("诊断列表"),
    ["Lazy"] = zh("Lazy 插件管理"),
    ["LazyVim Changelog"] = zh("LazyVim 更新日志"),
    ["Mason"] = zh("Mason 工具管理"),
    ["Keywordprg"] = zh("关键字帮助"),
    ["Terminal (cwd)"] = zh("终端（当前目录）"),
    ["Terminal (Root Dir)"] = zh("终端（项目根目录）"),
    ["Explorer Snacks (cwd)"] = zh("文件浏览器（当前目录）"),
    ["Explorer Snacks (root dir)"] = zh("文件浏览器（项目根目录）"),
    ["Git Status"] = zh("Git 状态"),
    ["Git Stash"] = zh("Git 暂存栈"),
    ["Git Log"] = zh("Git 日志"),
    ["Git Log (cwd)"] = zh("Git 日志（当前目录）"),
    ["Git Blame Line"] = zh("Git 当前行归因"),
    ["Git Current File History"] = zh("Git 当前文件历史"),
    ["Git Diff (hunks)"] = zh("Git Diff（改动块）"),
    ["Git Diff (origin)"] = zh("Git Diff（对比 origin）"),
    ["Git Browse (open)"] = zh("Git 浏览（打开）"),
    ["Git Browse (copy)"] = zh("Git 浏览（复制链接）"),
    ["GitHub Issues (open)"] = zh("GitHub Issues（未关闭）"),
    ["GitHub Issues (all)"] = zh("GitHub Issues（全部）"),
    ["GitHub Pull Requests (open)"] = zh("GitHub Pull Requests（未关闭）"),
    ["GitHub Pull Requests (all)"] = zh("GitHub Pull Requests（全部）"),
    ["Quit All"] = zh("全部退出"),
    ["Inspect Pos"] = zh("检查当前位置"),
    ["Inspect Tree"] = zh("检查语法树"),
    ["Colorschemes"] = zh("颜色主题"),
    ["Toggle Tabline"] = zh("切换标签栏"),
    ["Toggle Dimming"] = zh("切换暗化效果"),
    ["Toggle Auto Format (Buffer)"] = zh("切换自动格式化（当前缓冲区）"),
    ["Toggle Auto Format (Global)"] = zh("切换自动格式化（全局）"),
    ["Toggle Relative Number"] = zh("切换相对行号"),
    ["Toggle Line Numbers"] = zh("切换行号"),
    ["Toggle Diagnostics"] = zh("切换诊断"),
    ["Toggle Treesitter Highlight"] = zh("切换语法树高亮"),
    ["Toggle Zoom Mode"] = zh("切换放大模式"),
    ["Toggle Zen Mode"] = zh("切换专注模式"),
    ["Toggle Animations"] = zh("切换动画效果"),
    ["Toggle Dark Background"] = zh("切换深色背景"),
    ["Toggle Conceal Level"] = zh("切换文本隐藏级别"),
    ["Toggle Indent Guides"] = zh("切换缩进辅助线"),
    ["Toggle Inlay Hints"] = zh("切换内联提示"),
    ["Toggle Smooth Scroll"] = zh("切换平滑滚动"),
    ["Toggle Spelling"] = zh("切换拼写检查"),
    ["Toggle Wrap"] = zh("切换自动换行"),
    ["Toggle Mini Pairs"] = zh("切换括号配对"),
    ["Toggle Profiler"] = zh("切换性能分析器"),
    ["Toggle Profiler Highlights"] = zh("切换性能分析高亮"),
    ["Redraw / Clear hlsearch / Diff Update"] = zh("重绘 / 清除搜索高亮 / 更新 Diff"),
    ["Profiler Scratch Buffer"] = zh("性能分析临时缓冲区"),
    ["Undotree"] = zh("撤销树"),
    ["+noice"] = zh("+消息"),
}

local group_translations = {
    tabs = { en = "Tabs", zh = "标签页" },
    buffer = { en = "Buffer", zh = "缓冲区" },
    code = { en = "Code", zh = "代码" },
    insight = { en = "Inspect", zh = "分析" },
    find = { en = "Find", zh = "查找" },
    git = { en = "Git", zh = "Git" },
    clarity = { en = "Clarity", zh = "Clarity" },
    search = { en = "Search", zh = "搜索" },
    messages = { en = "Messages", zh = "消息" },
    terminal = { en = "Terminal", zh = "终端" },
    toggle = { en = "Toggle", zh = "切换" },
    window = { en = "Window", zh = "窗口" },
    lists = { en = "Lists", zh = "列表" },
}

local group_specs = {
    { "<leader><tab>", "tabs" },
    { "<leader>b", "buffer" },
    { "<leader>c", "code" },
    { "<leader>d", "insight" },
    { "<leader>f", "find" },
    { "<leader>g", "git" },
    { "<leader>h", "clarity" },
    { "<leader>s", "search" },
    { "<leader>sn", "messages" },
    { "<leader>t", "terminal" },
    { "<leader>u", "toggle" },
    { "<leader>w", "window" },
    { "<leader>x", "lists" },
}

local function translate_desc(desc)
    local entry = desc_translations[desc]
    if not entry then
        return desc
    end

    return entry[i18n.get_locale()] or desc
end

local function translate_group(group_id)
    local entry = group_translations[group_id]
    if not entry then
        return group_id
    end

    return entry[i18n.get_locale()] or entry.en or group_id
end

local function is_leader_map(lhs)
    if type(lhs) ~= "string" or lhs == "" then
        return false
    end

    return lhs:find("^<leader>") ~= nil
        or lhs:find("^<Leader>") ~= nil
        or lhs:find("^<Space>") ~= nil
        or lhs:sub(1, 1) == " "
end

local function remap_with_desc(mode, lhs, translated_desc)
    local map = vim.fn.maparg(lhs, mode, false, true)
    if type(map) ~= "table" or vim.tbl_isempty(map) then
        return false
    end

    local rhs = map.callback or map.rhs
    if rhs == nil or rhs == "" then
        return false
    end

    local opts = {
        desc = translated_desc,
        expr = map.expr == 1,
        nowait = map.nowait == 1,
        replace_keycodes = map.replace_keycodes == 1,
        remap = map.noremap == 0,
        silent = map.silent == 1,
    }

    vim.keymap.set(mode, lhs, rhs, opts)
    return true
end

function M.apply_keymap_desc_overrides()
    for _, mode in ipairs({ "n", "x", "v" }) do
        local seen = {}

        for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
            local desc = map.desc or ""
            local translated = translate_desc(desc)
            local id = mode .. "\0" .. map.lhs

            if desc ~= "" and translated ~= desc and is_leader_map(map.lhs) and not seen[id] then
                seen[id] = true
                remap_with_desc(mode, map.lhs, translated)
            end
        end
    end
end

function M.register_group_labels()
    local ok, which_key = pcall(require, "which-key")
    if not ok then
        return
    end

    local spec = {}

    for _, item in ipairs(group_specs) do
        table.insert(spec, { item[1], group = translate_group(item[2]) })
    end

    which_key.add(spec)
end

function M.apply()
    M.apply_keymap_desc_overrides()
    M.register_group_labels()
end

function M.setup()
    local group = vim.api.nvim_create_augroup("clarity_menu_i18n", { clear = true })

    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VeryLazy",
        callback = function()
            vim.schedule(M.apply)
        end,
    })
end

return M
