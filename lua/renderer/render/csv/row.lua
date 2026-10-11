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

---Text is padded after the field, numbers before it, and a field wider than
---its column is cut
---@private
---@param field renderer.Node
---@param index integer
function Render:field(field, index)
    local width = self.widths[index] or 0
    local fill = width - str.width(field.text)
    if fill < 0 then
        self:cut(field, width)
        return
    end
    if fill == 0 then
        return
    end
    local col = Render.numeric(field) and field.start_col or field.end_col
    self.marks:add(self.config, true, field.start_row, col, {
        priority = 0,
        virt_text = self:line():pad(fill, self.highlight):get(),
        virt_text_pos = 'inline',
    })
end

---Keep what fits in front of an ellipsis and conceal the rest
---@private
---@param field renderer.Node
---@param width integer
function Render:cut(field, width)
    if width < 1 then
        return
    end
    local kept, used = 0, 0 ---@type integer, integer
    for _, char in ipairs(str.chars(field.text)) do
        local next = used + str.width(char)
        if next > width - 1 then
            break
        end
        kept, used = kept + #char, next
    end
    local col = field.start_col + kept
    self.marks:add(self.config, true, field.start_row, col, {
        priority = 0,
        end_row = field.end_row,
        end_col = field.end_col,
        conceal = '',
    })
    -- a wide character that did not fit leaves the column short of the width
    local line = self:line():text('…', self.highlight)
    self.marks:add(self.config, true, field.start_row, col, {
        priority = 0,
        virt_text = line:pad(width - used - 1, self.highlight):get(),
        virt_text_pos = 'inline',
    })
end

---A tab fills up to the next tab stop, which depends on the padding in front
---of it, so it is hidden and the border added next to it instead of over it.
---The same goes for a border that is not one cell wide: drawn over the
---separator it would cover the field after it
---@private
---@param separator renderer.Node
function Render:separator(separator)
    local text = { { self.config.border, self.highlight } }
    if separator.text == '\t' or str.width(self.config.border) ~= 1 then
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

---A line below the header, borders cross it where the columns meet. The
---crossing is as wide as the border, and the line scrolls sideways with the
---rows, a virtual line stays in place otherwise
---@private
function Render:rule()
    local border = self.context.config.pipe_table.border
    local parts = {} ---@type string[]
    for i, width in ipairs(self.widths) do
        parts[i] = border[11]:rep(width)
    end
    local size = str.width(self.config.border)
    local cross = ''
    if size > 0 then
        local before = math.floor((size - 1) / 2)
        cross = border[11]:rep(before)
            .. border[5]
            .. border[11]:rep(size - 1 - before)
    end
    local line = self:line():text(table.concat(parts, cross), self.highlight)
    self.marks:add(self.config, 'virtual_lines', self.node.start_row, 0, {
        virt_lines = { line:get() },
        virt_lines_above = false,
        virt_lines_overflow = 'scroll',
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
