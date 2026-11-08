---@enum renderer.config.Preset
local Preset = {
    obsidian = 'obsidian',
    lazy = 'lazy',
    none = 'none',
}

---@class renderer.Presets
local M = {}

---@param user renderer.UserConfig
---@return renderer.UserConfig
function M.get(user)
    return vim.tbl_deep_extend(
        'force',
        M.config(user),
        M.partial(user) or {},
        M.overrides(user)
    )
end

---@private
---@param user renderer.UserConfig
---@return renderer.UserConfig
function M.config(user)
    ---@type table<renderer.config.Preset?, renderer.UserConfig?>
    local presets = {
        [Preset.obsidian] = { render_modes = true },
        ---https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/markdown.lua
        [Preset.lazy] = {
            file_types = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion' },
            code = {
                sign = false,
                width = 'block',
                right_pad = 1,
            },
            heading = {
                sign = false,
                icons = {},
            },
            checkbox = {
                enabled = false,
            },
        },
    }
    return presets[user.preset] or {}
end

---@private
---@param user? renderer.partial.UserConfig?
---@return renderer.partial.UserConfig?
function M.partial(user)
    if type(user) ~= 'table' then
        return nil
    end
    ---@type renderer.partial.UserConfig
    return {
        code = M.code(user),
        pipe_table = M.pipe_table(user),
        win_options = M.win_options(user),
    }
end

---@private
---@param user renderer.UserConfig
---@return renderer.UserConfig
function M.overrides(user)
    ---@param configs? table<any, renderer.partial.UserConfig>
    ---@return table<any, renderer.partial.UserConfig>?
    local function partials(configs)
        if type(configs) ~= 'table' then
            return nil
        end
        local result = {} ---@type table<any, renderer.partial.UserConfig>
        for value, override in pairs(configs) do
            result[value] = M.partial(override)
        end
        return result
    end

    ---@type renderer.overrides.UserConfig
    local overrides = {
        buflisted = partials((user.overrides or {}).buflisted),
        buftype = partials((user.overrides or {}).buftype),
        filetype = partials((user.overrides or {}).filetype),
        convert = M.partial((user.overrides or {}).convert),
        preview = M.partial((user.overrides or {}).preview),
    }

    ---@type renderer.UserConfig
    return { overrides = vim.tbl_count(overrides) > 0 and overrides or nil }
end

---@private
---@param user renderer.partial.UserConfig
---@return renderer.code.UserConfig?
function M.code(user)
    ---@type table<renderer.code.Style?, renderer.code.UserConfig?>
    local styles = {
        ['none'] = { enabled = false },
        ['normal'] = { language = false },
        ['language'] = { disable_background = true, inline = false },
    }
    return styles[(user.code or {}).style]
end

---@private
---@param user renderer.partial.UserConfig
---@return renderer.table.UserConfig?
function M.pipe_table(user)
    ---@type table<renderer.table.Preset?, renderer.table.UserConfig?>
    local presets = {
        ['round'] = {
            -- stylua: ignore
            border = {
                '╭', '┬', '╮',
                '├', '┼', '┤',
                '╰', '┴', '╯',
                '│', '─',
            },
        },
        ['double'] = {
            -- stylua: ignore
            border = {
                '╔', '╦', '╗',
                '╠', '╬', '╣',
                '╚', '╩', '╝',
                '║', '═',
            },
        },
        ['heavy'] = {
            alignment_indicator = '─',
            -- stylua: ignore
            border = {
                '┏', '┳', '┓',
                '┣', '╋', '┫',
                '┗', '┻', '┛',
                '┃', '━',
            },
        },
    }
    ---@type table<renderer.table.Style?, renderer.table.UserConfig?>
    local styles = {
        ['none'] = { enabled = false },
        ['normal'] = { border_enabled = false },
    }
    local preset = presets[(user.pipe_table or {}).preset] or {}
    local style = styles[(user.pipe_table or {}).style] or {}
    local result = vim.tbl_deep_extend('force', preset, style)
    return vim.tbl_count(result) > 0 and result or nil
end

---@private
---@param user renderer.partial.UserConfig
---@return renderer.window.UserConfigs?
function M.win_options(user)
    ---@type table<boolean?, renderer.window.UserConfigs?>
    local anti_conceals = {
        [false] = { concealcursor = { rendered = 'nvic' } },
    }
    return anti_conceals[(user.anti_conceal or {}).enabled]
end

return M
