-- ============================================
-- ЛИДЕР (пробел)
-- ============================================

vim.g.mapleader = " "

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
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- ПРОЗРАЧНОСТЬ ФОНА
vim.opt.termguicolors = true

-- Убираем фон у всех элементов
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
vim.api.nvim_set_hl(0, "PmenuSel", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "none" })

-- СИСТЕМНЫЙ БУФЕР ОБМЕНА (чтобы работал с браузером)
vim.opt.clipboard = "unnamedplus"

-- ============================================
-- АВТОКОМАНДЫ
-- ============================================

-- Выход из терминала по ESC
vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "term://*",
    callback = function()
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true })
        vim.cmd("startinsert")
    end
})

-- ============================================
-- ГОРЯЧИЕ КЛАВИШИ
-- ============================================

-- Файлы
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
vim.keymap.set("n", "<leader>wq", ":wq<CR>")

-- Файловый менеджер и поиск
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
vim.keymap.set("n", "<leader>f", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>g", "<cmd>Telescope live_grep<CR>")

-- -- Терминал и запуск
-- vim.keymap.set('n', '<leader>t', ':bo terminal<cr>a', {})
-- vim.keymap.set("n", "<leader>r", ":!python3 %<CR>")

-- Терминал и запуск
vim.keymap.set('n', '<leader>t', ':bo terminal<cr>a', {})

-- Запуск БЕЗ терминала (быстрый, но input() не работает)
vim.keymap.set("n", "<leader>r", ":!python3 %<CR>")

-- Запуск С терминалом (поддерживает input())
vim.keymap.set("n", "<leader>R", function()
    vim.cmd("bo terminal")
    vim.cmd("startinsert")
    vim.api.nvim_feedkeys("python3 " .. vim.fn.expand("%") .. "\n", "n", false)
end)

-- Буфер обмена
vim.keymap.set({"n", "v"}, "<leader>y", '"+y')
vim.keymap.set({"n", "v"}, "<leader>Y", '"+Y')
vim.keymap.set({"n", "v"}, "<leader>p", '"+p')
vim.keymap.set({"n", "v"}, "<leader>P", '"+P')

-- Переключение между окнами
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- ============================================
-- МЕНЕДЖЕР ПЛАГИНОВ (Lazy.nvim)
-- ============================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================
-- ПЛАГИНЫ
-- ============================================

require("lazy").setup({

    -- ========== ТЕМА ==========
    -- {
    --     "catppuccin/nvim",
    --     name = "catppuccin",
    --     priority = 1000,
    --     config = function()
    --         vim.cmd.colorscheme("catppuccin")
    --     end
    -- },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                transparent_background = true,
            })
            vim.cmd.colorscheme("catppuccin")
        end
    },

    -- ========== ФАЙЛОВЫЙ МЕНЕДЖЕР ==========
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup()
        end
    },

    -- ========== ПОИСК ==========
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup()
        end
    },

    -- ========== АВТОДОПОЛНЕНИЕ ==========
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "L3MON4D3/LuaSnip",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                }),
            })
        end
    },

    -- ========== LSP (Python + C++) ==========
    {
        "neovim/nvim-lspconfig",
        config = function()
            -- Python
            vim.lsp.config.pyright = {
                cmd = { "pyright-langserver", "--stdio" },
                filetypes = { "python" },
                root_markers = { "pyproject.toml", "setup.py", ".git" },
            }
            vim.lsp.enable("pyright")

            -- C++
            vim.lsp.config.clangd = {
                cmd = { "clangd" },
                filetypes = { "c", "cpp", "cxx", "cc", "h", "hpp" },
                root_markers = { "compile_commands.json", "CMakeLists.txt", ".git" },
            }
            vim.lsp.enable("clangd")
        end
    },

    -- ========== ФОРМАТИРОВАНИЕ ==========
    {
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    python = { "black" },
                    cpp = { "clang-format" },
                    c = { "clang-format" },
                },
                format_on_save = {
                    timeout_ms = 500,
                    lsp_fallback = true,
                },
            })
        end
    },

    -- ========== ПОДСКАЗКИ КЛАВИШ (помогает запоминать) ==========
    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup({
                delay = 500,
                -- Показывать подсказки через 0.5 секунды после нажатия лидера
            })
        end
    },

    -- ========== СТАТУСНАЯ СТРОКА ==========
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "catppuccin",
                },
            })
        end
    },

    -- ========== УЛУЧШЕННЫЙ НЕЙМ ==========
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end
    },

    -- ========== РАБОТА С GIT ==========
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "G" },
    },

    -- ========== ПОДСВЕТКА СИНТАКСИСА ДЛЯ МАРКДАУНА ==========
    {
        "ellisonleao/glow.nvim",
        cmd = "Glow",
        config = function()
            require("glow").setup({
                width = 100,
                height = 30,
            })
        end
    },

})
