local env = require('renderer.lib.env')
local icons = require('renderer.lib.icons')
local state = require('renderer.state')

---@alias renderer.health.Language
---| 'csv'
---| 'html'
---| 'latex'
---| 'markdown'
---| 'markdown_inline'
---| 'psv'
---| 'tsv'
---| 'yaml'

---@class renderer.Health
local M = {}

---@private
M.version = '0.2.1'

function M.check()
    M.start('versions')
    M.neovim('0.12')
    vim.health.ok('tree-sitter ABI: ' .. vim.treesitter.language_version)
    vim.health.ok('plugin: ' .. M.version)

    M.start('configuration')
    local errors = state.validate()
    if #errors == 0 then
        vim.health.ok('valid')
    else
        for _, message in ipairs(errors) do
            vim.health.error(message)
        end
    end

    local config = state.get(0)
    local latex = config.latex

    M.ts_infos(config)

    M.start('icons')
    local provider = icons.name()
    if provider then
        vim.health.ok('using: ' .. provider)
    else
        vim.health.warn('none installed')
    end

    local latex_works = false
    if latex.enabled then
        M.start('latex')
        local cmds = env.commands(latex.converter)
        if #cmds == 0 then
            local message = 'none installed: ' .. vim.inspect(latex.converter)
            vim.health.warn(message, M.disable('latex'))
        else
            latex_works = true
            vim.health.ok('using: ' .. vim.inspect(cmds))
        end
    end

    M.start('conflicts')
    M.plugin('headlines')
    M.plugin('markview')
    M.plugin('obsidian', function(obsidian)
        -- selene: allow(undefined_variable)
        local client = Obsidian or obsidian.get_client()
        if client.opts.ui.enable == false then
            return nil
        end
        return [[
        disable the ui in your obsidian.nvim config
        require("obsidian").setup({
            ui = { enable = false },
        })
        ]]
    end)
    if latex_works then
        M.plugin('snacks', function(snacks)
            local image = snacks.config.image
            if not image or not image.enabled then
                return nil
            end
            if image.doc and image.doc.enabled == false then
                return nil
            end
            if image.math and image.math.enabled == false then
                return nil
            end
            return [[
            disable latex math rendering in your snacks.nvim config
            require("snacks").setup({
                image = {
                    enabled = true,
                    math = { enabled = false },
                },
            })
            ]]
        end)
    end
end

---@private
---@param name string
function M.start(name)
    vim.health.start(('renderer.nvim [%s]'):format(name))
end

---@private
---@param min string
function M.neovim(min)
    if vim.fn.has('nvim-' .. min) == 0 then
        vim.health.error('neovim < ' .. min)
    else
        vim.health.ok('neovim >= ' .. min)
    end
end

---@private
---@param config renderer.buf.Config
function M.ts_infos(config)
    local required, optional, active = M.languages()
    for _, language in ipairs(required) do
        M.ts_info(language, true, active[language] == true)
    end
    for _, language in ipairs(optional) do
        local section = config[language] ---@type { enabled: boolean }?
        if section and section.enabled then
            M.ts_info(language, false, false)
        end
    end
end

---@private
---@return string[] required
---@return string[] optional
---@return table<string, boolean> active
function M.languages()
    local registry = require('renderer.format')
    local languages = {} ---@type table<string, boolean>
    local active = {} ---@type table<string, boolean>
    for _, file_type in ipairs(state.file_types) do
        local lang = vim.treesitter.language.get_lang(file_type)
        local format = registry.root(lang)
        if format then
            active[format.root] = true
            for language, required in pairs(format.languages) do
                -- required by one format wins over optional in another
                languages[language] = languages[language] or required
            end
        end
    end
    local required, optional = {}, {} ---@type string[], string[]
    for language, value in pairs(languages) do
        table.insert(value and required or optional, language)
    end
    table.sort(required)
    table.sort(optional)
    return required, optional, active
end

---@private
---@param language renderer.health.Language
---@param required boolean
---@param active boolean
function M.ts_info(language, required, active)
    M.start('tree-sitter ' .. language)

    local has_parser, parser = pcall(vim.treesitter.get_parser, 0, language)
    if has_parser and parser then
        vim.health.ok('parser: installed')
    else
        local message = 'parser: not installed'
        local install = M.install(language)
        if not required then
            vim.health.warn(message, { install, M.disable(language) })
        else
            vim.health.error(message, install)
        end
    end

    local has_info, info = pcall(vim.treesitter.language.inspect, language)
    if has_info and info then
        vim.health.ok('ABI: ' .. info.abi_version)
    else
        local message = 'ABI: unknown'
        if not required then
            vim.health.warn(message, M.disable(language))
        else
            vim.health.error(message)
        end
    end

    if required then
        local files = vim.treesitter.query.get_files(language, 'highlights')
        if #files > 0 then
            for _, file in ipairs(files) do
                local path = vim.fn.fnamemodify(file, ':~')
                vim.health.ok('highlights: ' .. path)
            end
        else
            vim.health.error('highlights: unknown')
        end
    end

    if active then
        -- create a temporary buffer to check if vim.treesitter.start gets called
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].filetype = language
        local ok = vim.treesitter.highlighter.active[buf] ~= nil
        vim.api.nvim_buf_delete(buf, { force = true })
        if ok then
            vim.health.ok('highlighter: enabled')
        else
            vim.health.error('highlighter: not enabled', {
                ('call vim.treesitter.start() on %s buffers'):format(language),
            })
        end
    end
end

---@private
---@param name string
---@param validate? fun(plugin: any): string?
function M.plugin(name, validate)
    local has_plugin, plugin = pcall(require, name) ---@type boolean, any
    if not has_plugin then
        vim.health.ok(name .. ': not installed')
    elseif not validate then
        vim.health.error(name .. ': installed')
    else
        local advice = validate(plugin)
        if advice then
            vim.health.error(name .. ': installed', M.trim(advice))
        else
            vim.health.ok(name .. ': installed but should not conflict')
        end
    end
end

---@private
---@param language renderer.health.Language
---@return string
function M.install(language)
    return 'install it with :TSInstall ' .. language
end

---@private
---@param language renderer.health.Language
---@return string
function M.disable(language)
    local format = [[
    disable %s support to avoid this warning
    require("renderer").setup({
        %s = { enabled = false },
    })
    ]]
    return M.trim(format:format(language, language))
end

---@private
---@param s string
---@return string
function M.trim(s)
    return (s:gsub('%s+$', ''))
end

return M
