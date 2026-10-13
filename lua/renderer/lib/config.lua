local Line = require('renderer.lib.line')
local Resolved = require('renderer.lib.resolved')
local env = require('renderer.lib.env')
local iter = require('renderer.lib.iter')

---@class renderer.buf.Config: renderer.partial.Config
---@field resolved renderer.resolved.Config
local Config = {}
Config.__index = Config

---@private
---@type string[]
Config.components = {
    'anti_conceal',
    'bullet',
    'callout',
    'checkbox',
    'code',
    'csv',
    'dash',
    'document',
    'heading',
    'html',
    'indent',
    'inline_highlight',
    'latex',
    'link',
    'padding',
    'paragraph',
    'pipe_table',
    'quote',
    'render',
    'sign',
    'win_options',
    'yaml',
}

---@param root renderer.Config
---@param enabled boolean
---@param buf integer
---@param custom? renderer.partial.UserConfig
---@return renderer.buf.Config
function Config.new(root, enabled, buf, custom)
    ---@type renderer.partial.Config
    local config = {
        enabled = enabled,
        render_modes = root.render_modes,
        debounce = root.debounce,
    }
    for _, name in ipairs(Config.components) do
        config[name] = root[name]
    end
    config = vim.deepcopy(config)

    ---@param override? renderer.partial.UserConfig
    local function extend(override)
        config = vim.tbl_deep_extend('force', config, override or {})
    end

    local src = require('renderer.core.preview').get(buf)
    local format = require('renderer.format').get(src or buf)
    extend(format and format.defaults)
    extend(root.overrides.buflisted[env.buf.get(src or buf, 'buflisted')])
    extend(root.overrides.buftype[env.buf.get(src or buf, 'buftype')])
    extend(root.overrides.filetype[env.buf.get(src or buf, 'filetype')])
    extend(src and root.overrides.preview)
    extend(custom)

    local self = setmetatable(config, Config)
    self.resolved = Resolved.new(config)
    ---@cast self -renderer.partial.Config
    return self
end

---@return renderer.Line
function Config:line()
    return Line.new(self.padding.highlight)
end

---@param destination string
---@param icon renderer.mark.Text
function Config:set_link_text(destination, icon)
    local options = iter.table.filter(self.link.custom, function(custom)
        if custom.kind == 'suffix' then
            return vim.endswith(destination, custom.pattern)
        elseif custom.kind == 'url' then
            local prefix = destination:match('^(.*)' .. custom.pattern) ---@type string?
            if not prefix then
                return false
            end
            prefix = prefix:gsub('^https?://', '', 1)
            prefix = prefix:gsub('^www%.', '', 1)
            local last = prefix:sub(-1)
            return last == '' or last == '.'
        else
            return destination:find(custom.pattern) ~= nil
        end
    end)
    iter.list.sort(options, function(custom)
        return custom.priority or #custom.pattern
    end)
    local result = options[#options]
    if result then
        icon[1] = result.icon
        icon[2] = result.highlight or icon[2]
    end
end

---@param child renderer.schema.Record
---@return renderer.Schema
function Config.schema(child)
    local settings = require('renderer.settings')
    ---@type renderer.schema.Record
    local parent = { debounce = { type = 'number' } }
    for _, name in ipairs(Config.components) do
        parent[name] = settings[name].schema()
    end
    local record = vim.tbl_deep_extend('error', parent, child)
    return settings.base.schema(record)
end

return Config
