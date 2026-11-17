-- ============================================
-- ЛИДЕР И ТЕМА
-- ============================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Для другой темы поменяй repo/name/colorscheme и функцию setup.
local theme = {
    repo = "catppuccin/nvim",
    name = "catppuccin",
    colorscheme = "catppuccin",
    lualine = "auto",
    setup = function()
        require("catppuccin").setup({ transparent_background = true })
    end,
}

-- ============================================
-- НАСТРОЙКИ
-- ============================================

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.clipboard = "unnamedplus"

local swapdir = vim.fn.stdpath("state") .. "/swap"
vim.fn.mkdir(swapdir, "p", "0700")
vim.fn.mkdir(vim.opt.undodir:get()[1], "p", "0700")
vim.opt.directory = swapdir .. "//"
vim.opt.swapfile = true

local group = vim.api.nvim_create_augroup("PersonalConfig", { clear = true })
local function map(mode, lhs, rhs, desc, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true, desc = desc }, opts or {}))
end

-- ============================================
-- ПРОЕКТЫ, UV И ЗАПУСК PYTHON
-- ============================================

local root_markers = { { "pyproject.toml", "uv.lock", "CMakeLists.txt", "compile_commands.json", ".git" } }

local function project_root(file)
    file = file or vim.api.nvim_buf_get_name(0)
    if file == "" or vim.bo.buftype ~= "" then
        return vim.fn.getcwd()
    end
    return vim.fs.root(file, root_markers) or vim.fs.dirname(file)
end

-- Не меняем глобальный cwd: каждый файловый сплит имеет корень своего проекта.
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
        if vim.bo[ev.buf].buftype == "" and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
            vim.cmd.lcd({ args = { project_root(vim.api.nvim_buf_get_name(ev.buf)) } })
        end
    end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function(ev)
        map("t", "<Esc>", [[<C-\><C-n>]], "Выйти в normal mode", { buffer = ev.buf })
        for _, key in ipairs({ "h", "j", "k", "l" }) do
            map("t", "<C-" .. key .. ">", [[<C-\><C-n><C-w>]] .. key,
                "Перейти в соседнее окно", { buffer = ev.buf })
        end
    end,
})

local function saved_python_file()
    local file = vim.api.nvim_buf_get_name(0)
    if vim.bo.buftype ~= "" or file == "" or vim.bo.filetype ~= "python" then
        vim.notify("Открой сохранённый Python-файл", vim.log.levels.WARN)
        return
    end
    local ok, err = pcall(vim.cmd, "update")
    if not ok then
        vim.notify("Не удалось сохранить файл: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    return file
end

local function python_command(file)
    local uv_root = vim.fs.root(file, { { "pyproject.toml", "uv.lock" } })
    if uv_root and vim.fn.executable("uv") == 1 then
        return { "uv", "run", "python" }, uv_root
    end
    if uv_root then
        vim.notify("uv не найден: используется python3", vim.log.levels.WARN)
    end
    return { "python3" }, project_root(file)
end

local function shell_command(argv)
    return table.concat(vim.tbl_map(vim.fn.shellescape, argv), " ")
end

local function terminal_run(argv, cwd)
    require("toggleterm.terminal").Terminal:new({
        -- Fish-конфиг может менять cwd при старте shell: возвращаемся в проект явно.
        cmd = "cd " .. vim.fn.shellescape(cwd) .. " && " .. shell_command(argv),
        dir = cwd,
        direction = "horizontal",
        hidden = true,
        close_on_exit = false,
        display_name = "Python / pytest",
    }):open(12)
end

-- Быстрый запуск асинхронный, stdin закрыт. Для input() используй <leader>R.
local function quick_run(argv, cwd)
    vim.cmd("botright 12new")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    local header = { "$ " .. shell_command(argv), "cwd: " .. cwd, "" }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.list_extend(vim.deepcopy(header), { "Выполняется…" }))
    vim.bo[buf].modifiable = false
    map("n", "q", "<cmd>close<CR>", "Закрыть вывод", { buffer = buf })
    local ok, err = pcall(vim.system, argv, { cwd = cwd, text = true }, function(result)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end
            local lines = vim.deepcopy(header)
            for _, output in ipairs({ result.stdout or "", result.stderr or "" }) do
                if output ~= "" then
                    vim.list_extend(lines, vim.split(output:gsub("\n$", ""), "\n", { plain = true }))
                end
            end
            table.insert(lines, "")
            table.insert(lines, "Код завершения: " .. result.code)
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
        end)
    end)
    if not ok then
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, { tostring(err) })
        vim.bo[buf].modifiable = false
        vim.notify(tostring(err), vim.log.levels.ERROR)
    end
end

local function run_python(interactive)
    local file = saved_python_file()
    if not file then
        return
    end
    local argv, cwd = python_command(file)
    table.insert(argv, file)
    if interactive then
        terminal_run(argv, cwd)
    else
        quick_run(argv, cwd)
    end
end

local function nearest_test()
    local ok, parser = pcall(vim.treesitter.get_parser, 0, "python")
    if not ok or not parser then
        vim.notify("Для теста под курсором нужен Python-парсер: :TSInstall python", vim.log.levels.WARN)
        return
    end
    parser:parse()
    local node = vim.treesitter.get_node()
    local names, found_test = {}, false
    while node do
        if node:type() == "function_definition" or node:type() == "class_definition" then
            local name_node = node:field("name")[1]
            local name = name_node and vim.treesitter.get_node_text(name_node, 0)
            if name and (name:match("^test_") or (node:type() == "class_definition" and name:match("^Test"))) then
                table.insert(names, 1, name)
                found_test = true
            end
        end
        node = node:parent()
    end
    if found_test then
        return table.concat(names, "::")
    end
    vim.notify("Поставь курсор внутри test_* или класса Test*", vim.log.levels.WARN)
end

local function run_pytest(scope)
    local file = saved_python_file()
    if not file then
        return
    end
    local target
    if scope == "nearest" then
        local test = nearest_test()
        if not test then
            return
        end
        target = file .. "::" .. test
    elseif scope == "file" then
        target = file
    end
    local argv, cwd = python_command(file)
    vim.list_extend(argv, { "-m", "pytest" })
    if target then
        table.insert(argv, target)
    end
    terminal_run(argv, cwd)
end

-- ============================================
-- ГОРЯЧИЕ КЛАВИШИ
-- ============================================

map("n", "<leader>w", "<cmd>write<CR>", "Сохранить")
map("n", "<leader>q", "<cmd>quit<CR>", "Закрыть окно")
map("n", "<leader>wq", "<cmd>wq<CR>", "Сохранить и закрыть")
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", "Файловое дерево")
map("n", "<leader>f", function()
    require("telescope.builtin").find_files({ cwd = project_root() })
end, "Найти файл проекта")
map("n", "<leader>g", function()
    require("telescope.builtin").live_grep({ cwd = project_root() })
end, "Поиск текста в проекте")
map("n", "<leader>r", function() run_python(false) end, "Запустить Python (uv / python3)")
map("n", "<leader>R", function() run_python(true) end, "Запустить Python с input()")
map("n", "<leader>Tt", function() run_pytest("file") end, "Pytest: текущий файл")
map("n", "<leader>Tf", function() run_pytest("nearest") end, "Pytest: тест или класс под курсором")
map("n", "<leader>Ta", function() run_pytest("all") end, "Pytest: весь проект")

local shell_terminals = {}
map("n", "<leader>t", function()
    if vim.bo.buftype == "terminal" and vim.b.toggle_number
        and vim.fn.jobwait({ vim.b.terminal_job_id }, 0)[1] ~= -1 then
        vim.cmd.close()
        return
    end
    local terminals = require("toggleterm.terminal")
    local current = terminals.get(terminals.get_focused_id(), true)
    if current then
        current:close()
        return
    end
    local root = project_root()
    if not shell_terminals[root] or (shell_terminals[root].bufnr
        and not vim.api.nvim_buf_is_valid(shell_terminals[root].bufnr)) then
        shell_terminals[root] = terminals.Terminal:new({
            dir = root,
            direction = "horizontal",
            on_create = function(term)
                term:send("cd " .. vim.fn.shellescape(root), false)
            end,
        })
    end
    shell_terminals[root]:toggle(12)
end, "Терминал проекта")

map({ "n", "v" }, "<leader>y", '"+y', "Копировать в системный буфер")
map({ "n", "v" }, "<leader>Y", '"+Y', "Копировать строку в системный буфер")
map({ "n", "v" }, "<leader>p", '"+p', "Вставить из системного буфера")
map({ "n", "v" }, "<leader>P", '"+P', "Вставить перед курсором")
for _, key in ipairs({ "h", "j", "k", "l" }) do
    map("n", "<C-" .. key .. ">", "<C-w>" .. key, "Перейти в соседнее окно")
end
map("n", "J", ":m .+1<CR>==", "Переместить строку вниз")
map("n", "K", ":m .-2<CR>==", "Переместить строку вверх")
map("v", "J", ":m '>+1<CR>gv=gv", "Переместить выделение вниз")
map("v", "K", ":m '<-2<CR>gv=gv", "Переместить выделение вверх")
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Предыдущая диагностика")
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Следующая диагностика")
map("n", "<leader>xx", function() require("telescope.builtin").diagnostics() end, "Диагностика открытых файлов")
map("n", "<leader>xd", vim.diagnostic.open_float, "Диагностика строки")
map({ "n", "v" }, "<leader>cf", function()
    require("conform").format({ async = true, lsp_format = "fallback", timeout_ms = 3000 })
end, "Форматировать код")

-- ============================================
-- МЕНЕДЖЕР ПЛАГИНОВ (Lazy.nvim)
-- ============================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath,
    })
    if vim.v.shell_error ~= 0 then
        error("Не удалось установить lazy.nvim:\n" .. out)
    end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================
-- ПЛАГИНЫ
-- ============================================

require("lazy").setup({
    {
        theme.repo,
        name = theme.name,
        priority = 1000,
        config = function()
            theme.setup()
            vim.cmd.colorscheme(theme.colorscheme)
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            { "windwp/nvim-autopairs", opts = {} },
            { "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
        },
        config = function()
            local cmp = require("cmp")
            local snippets = require("luasnip")
            snippets.config.setup({ history = true, updateevents = "TextChanged,TextChangedI" })
            require("luasnip.loaders.from_vscode").lazy_load()
            cmp.setup({
                snippet = { expand = function(args) snippets.lsp_expand(args.body) end },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<Esc>"] = cmp.mapping(function(fallback)
                        cmp.abort()
                        fallback()
                    end, { "i" }),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
                        if before:match("^%s*$") then
                            if snippets.locally_jumpable(1) then
                                snippets.jump(1)
                            else
                                fallback()
                            end
                        elseif snippets.expandable() then
                            snippets.expand()
                        elseif cmp.visible() then
                            cmp.select_next_item()
                        elseif snippets.locally_jumpable(1) then
                            snippets.jump(1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif snippets.locally_jumpable(-1) then
                            snippets.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "path" },
                }, { { name = "buffer" } }),
            })
            cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp" },
        config = function()
            vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

            local function python_interpreter(root)
                if root then
                    local env_root = vim.fs.root(root, function(name, path)
                        return name == ".venv" and vim.fn.executable(path .. "/.venv/bin/python") == 1
                    end)
                    if env_root then
                        return env_root .. "/.venv/bin/python"
                    end
                end
                local active = vim.env.VIRTUAL_ENV
                if active and vim.fn.executable(active .. "/bin/python") == 1 then
                    return active .. "/bin/python"
                end
                return vim.fn.exepath("python3")
            end

            vim.lsp.config("pyright", {
                root_markers = { "pyrightconfig.json", "pyproject.toml", "uv.lock", "setup.py", ".git" },
                before_init = function(_, config)
                    config.settings = config.settings or {}
                    config.settings.python = config.settings.python or {}
                    config.settings.python.pythonPath = python_interpreter(config.root_dir)
                end,
            })
            vim.lsp.config("ruff", {
                root_markers = { "pyproject.toml", "uv.lock", "ruff.toml", ".ruff.toml", ".git" },
                on_attach = function(client)
                    client.server_capabilities.hoverProvider = false
                end,
            })
            vim.lsp.config("clangd", {
                cmd = { "clangd", "--background-index", "--clang-tidy" },
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
                root_markers = { "compile_commands.json", ".clangd", "CMakeLists.txt", ".git" },
            })
            for _, server in ipairs({ "pyright", "ruff", "clangd" }) do
                local cmd = vim.lsp.config[server].cmd
                if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
                    vim.lsp.enable(server)
                end
            end

            vim.api.nvim_create_user_command("UvRefresh", function()
                for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "pyright" })) do
                    client.settings.python = client.settings.python or {}
                    client.settings.python.pythonPath = python_interpreter(client.config.root_dir)
                    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
                    vim.notify("Pyright: " .. client.settings.python.pythonPath)
                end
            end, { desc = "Обновить окружение Pyright после uv sync" })

            vim.diagnostic.config({
                virtual_text = { severity = vim.diagnostic.severity.ERROR },
                severity_sort = true,
                float = { border = "rounded", source = true },
            })
            vim.api.nvim_create_autocmd("LspAttach", {
                group = group,
                callback = function(ev)
                    local opts = { buffer = ev.buf }
                    -- Neovim создаёт стандартный K для hover; у нас K переносит строку.
                    map("n", "K", ":m .-2<CR>==", "Переместить строку вверх", opts)
                    map("n", "<leader>k", vim.lsp.buf.hover, "Документация под курсором", opts)
                    map("n", "gd", vim.lsp.buf.definition, "Перейти к определению", opts)
                    map("n", "gD", vim.lsp.buf.declaration, "Перейти к объявлению", opts)
                    map("n", "gi", vim.lsp.buf.implementation, "Найти реализации", opts)
                    map("n", "gr", vim.lsp.buf.references, "Найти использования", opts)
                    map("n", "<leader>rn", vim.lsp.buf.rename, "Переименовать символ", opts)
                    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Действия над кодом", opts)
                end,
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                python = { "ruff_format" },
                cpp = { "clang_format" },
                c = { "clang_format" },
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local treesitter = require("nvim-treesitter")
            treesitter.setup({})
            if vim.fn.executable("tree-sitter") == 1 then
                treesitter.install({
                    "python", "c", "cpp", "lua", "vim", "vimdoc", "query",
                    "bash", "json", "toml", "yaml", "markdown", "markdown_inline",
                })
            end
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                callback = function(ev)
                    if vim.bo[ev.buf].buftype == "" then
                        pcall(vim.treesitter.start, ev.buf)
                    end
                end,
            })
            -- Экспериментальные Treesitter-отступы не включаем, особенно для Python.
        end,
    },
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        opts = {
            open_mapping = false,
            direction = "horizontal",
            size = 12,
            start_in_insert = true,
            shade_terminals = false,
        },
    },
    {
        "folke/which-key.nvim",
        opts = { delay = 500 },
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = { options = { theme = theme.lualine } },
    },
    { "numToStr/Comment.nvim", opts = {} },
    { "tpope/vim-fugitive", cmd = { "Git", "G" } },
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            on_attach = function(buf)
                local gs = require("gitsigns")
                local opts = { buffer = buf }
                map("n", "]c", function()
                    if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
                end, "Следующее изменение Git", opts)
                map("n", "[c", function()
                    if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
                end, "Предыдущее изменение Git", opts)
                map("n", "<leader>gp", gs.preview_hunk, "Git: показать изменение", opts)
                map("n", "<leader>gs", gs.stage_hunk, "Git: добавить изменение в индекс", opts)
                map("n", "<leader>gr", gs.reset_hunk, "Git: отменить изменение", opts)
                map("n", "<leader>gb", gs.blame_line, "Git: автор строки", opts)
            end,
        },
    },
    {
        "ellisonleao/glow.nvim",
        cmd = "Glow",
        opts = { width = 100, height = 30 },
    },
})
