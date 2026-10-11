local Base = require('renderer.render.base')
local Widths = require('renderer.render.csv.widths')
local str = require('renderer.lib.str')

---Draws a row of a csv, tsv or psv file as a line of a table: every field is
---padded to the width of its column and every separator becomes a border
---@class renderer.render.csv.Row: renderer.Render
---@field private config renderer.csv.Config
---@field private widths integer[]
---@field private highlight string
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
    self.config = self.context.config.csv
    if not self.config.enabled then
        return false
    end
    -- a quoted field can hold a line break, the row is left as source
    if self.node.start_row ~= self.node.end_row then
        return false
    end
    self.widths = Widths.get(self.context.buf)
    return true
end

---@protected
function Render:run()
    local header = self:header()
    self.highlight = header and self.config.head or self.config.row
    self.marks:over(self.config, true, self.node, { hl_group = self.highlight })

    local index = 0
    self.node:for_each_child(function(child)
        if child:get():named() then
            index = index + 1
            self:field(child, index)
        else
            self:separator(child)
        end
    end)

    if header then
        self:rule()
    end
end

---The first row of the document, the one without a row before it
---@private
---@return boolean
function Render:header()
    return self.config.header and self.node:get():prev_sibling() == nil
end

---Text is padded after the field, numbers before it
---@private
---@param field renderer.Node
---@param index integer
function Render:field(field, index)
    local fill = (self.widths[index] or 0) - str.width(field.text)
    if fill <= 0 then
        return
    end
    local col = Render.numeric(field) and field.start_col or field.end_col
    self.marks:add(self.config, true, field.start_row, col, {
        priority = 0,
        virt_text = self:line():pad(fill, self.highlight):get(),
        virt_text_pos = 'inline',
    })
end

---A tab fills up to the next tab stop, which depends on the padding in front
---of it, so it is hidden and the border added next to it instead of over it
---@private
---@param separator renderer.Node
function Render:separator(separator)
    local text = { { self.config.border, self.highlight } }
    if separator.text == '\t' then
        self.marks:over(self.config, 'table_border', separator, {
            conceal = '',
        })
        self.marks:start(self.config, 'table_border', separator, {
            virt_text = text,
            virt_text_pos = 'inline',
        })
    else
        self.marks:over(self.config, 'table_border', separator, {
            virt_text = text,
            virt_text_pos = 'overlay',
        })
    end
end

---A line below the header, borders cross it where the columns meet
---@private
function Render:rule()
    local border = self.context.config.pipe_table.border
    local parts = {} ---@type string[]
    for i, width in ipairs(self.widths) do
        parts[i] = border[11]:rep(width)
    end
    local line = self:line()
        :text(table.concat(parts, border[5]), self.highlight)
    self.marks:add(self.config, 'virtual_lines', self.node.start_row, 0, {
        virt_lines = { line:get() },
        virt_lines_above = false,
    })
end

---The grammar tells numbers from text, except for a leading sign
---@param field renderer.Node
---@return boolean
function Render.numeric(field)
    local kind = field:get():named_child(0)
    local name = kind and kind:type()
    return name == 'number'
        or name == 'float'
        or field.text:match('^[+-]%d+%.?%d*$') ~= nil
end

return Render
