local log = require('renderer.core.log')

---@class (exact) renderer.Mark
---@field modes? renderer.Modes
---@field conceal renderer.mark.Conceal
---@field start_row integer
---@field start_col integer
---@field opts renderer.mark.Opts
---@field replace? renderer.mark.Line[]
---@field reveal? renderer.mark.Reveal

---@class (exact) renderer.mark.Reveal
---@field rows renderer.Range rows that reveal the mark, instead of its own
---@field always boolean reveal even when anti conceal is disabled

---@alias renderer.mark.Conceal boolean|renderer.Element

---@class renderer.mark.Opts: vim.api.keyset.set_extmark
---@field virt_text? renderer.mark.Line
---@field virt_lines? renderer.mark.Line[]

---@alias renderer.mark.Line renderer.mark.Text[]

---@class (exact) renderer.mark.Text
---@field [1] string text
---@field [2] renderer.mark.Hl highlight

---@alias renderer.mark.Hl string|string[]

---@class renderer.Marks
---@field private context renderer.request.Context
---@field private update boolean
---@field private marks renderer.Mark[]
local Marks = {}
Marks.__index = Marks

---@param context renderer.request.Context
---@param update boolean
---@return renderer.Marks
function Marks.new(context, update)
    local self = setmetatable({}, Marks)
    self.context = context
    self.update = update
    self.marks = {}
    return self
end

---@return renderer.Mark[]
function Marks:get()
    return self.marks
end

---@param config renderer.base.Config
---@param conceal renderer.mark.Conceal
---@param node renderer.Node
---@param opts renderer.mark.Opts
---@return boolean
function Marks:start(config, conceal, node, opts)
    return self:add(config, conceal, node.start_row, node.start_col, opts)
end

---@param config renderer.base.Config
---@param conceal renderer.mark.Conceal
---@param node? renderer.Node
---@param opts renderer.mark.Opts
---@param offset? Range4
---@return boolean
function Marks:over(config, conceal, node, opts, offset)
    if not node then
        return false
    end
    offset = offset or { 0, 0, 0, 0 }
    local start_row = node.start_row + offset[1]
    local start_col = node.start_col + offset[2]
    opts.end_row = node.end_row + offset[3]
    opts.end_col = node.end_col + offset[4]
    return self:add(config, conceal, start_row, start_col, opts)
end

---@param config renderer.base.Config
---@param node renderer.Node
---@param lines renderer.mark.Line[]
function Marks:replace(config, node, lines)
    self:insert(config, {
        conceal = true,
        start_row = node.start_row,
        start_col = node.start_col,
        opts = {
            end_row = node.end_row,
            end_col = node.end_col,
            conceal_lines = '',
        },
        replace = lines,
    })
end

---@param config renderer.base.Config
---@param conceal renderer.mark.Conceal
---@param start_row integer
---@param start_col integer
---@param opts renderer.mark.Opts
---@param reveal? renderer.mark.Reveal
---@return boolean
function Marks:add(config, conceal, start_row, start_col, opts, reveal)
    return self:insert(config, {
        conceal = conceal,
        start_row = start_row,
        start_col = start_col,
        opts = opts,
        reveal = reveal,
    })
end

---@private
---@param config renderer.base.Config
---@param mark renderer.Mark
---@return boolean
function Marks:insert(config, mark)
    mark.modes = config.render_modes
    log.add('trace', 'Mark', mark)
    if self.update then
        self:run_update(mark)
    end
    self.marks[#self.marks + 1] = mark
    return true
end

---@private
---@param mark renderer.Mark
function Marks:run_update(mark)
    local row, start_col, opts = mark.start_row, mark.start_col, mark.opts
    if opts.conceal then
        local end_col = assert(opts.end_col, 'conceal requires end_col')
        self.context.highlights:add(row, {
            conceal = {
                start_col,
                end_col,
                replacement = opts.conceal,
                blocks = 1,
            },
        })
    end
    if opts.hl_group and opts.end_col then
        self.context.highlights:add(row, {
            group = {
                start_col,
                opts.end_col,
                priority = opts.priority or 4096,
                highlight = opts.hl_group,
            },
        })
    end
    if opts.virt_text_pos == 'inline' then
        self.context.inline:add(row, {
            col = start_col,
            line = opts.virt_text or {},
        })
    end
end

return Marks
