local Base = require('renderer.render.base')
local env = require('renderer.lib.env')
local iter = require('renderer.lib.iter')
local job = require('renderer.lib.job')
local log = require('renderer.core.log')
local state = require('renderer.state')
local str = require('renderer.lib.str')

---@class renderer.mermaid.Data
---@field open renderer.Node
---@field close renderer.Node
---@field output string[]

---Draws a mermaid code block as its diagram, made by an external tool that
---runs in the background. Until the diagram is ready, or when the tool fails,
---the block is left to the code renderer
---@class renderer.render.Mermaid: renderer.Render
---@field private config renderer.mermaid.Config
---@field private data renderer.mermaid.Data
local Render = setmetatable({}, Base)
Render.__index = Render

---Buffers with an update already scheduled
---@private
---@type table<integer, true>
Render.pending = {}

---@protected
---@return boolean
function Render:setup()
    self.config = self.context.config.mermaid
    if not self.config.enabled or self.node:height() <= 2 then
        return false
    end
    local info = self.node:child('info_string')
    local language = info and info:child('language')
    if not language or language.text ~= 'mermaid' then
        return false
    end
    local delim = 'fenced_code_block_delimiter'
    local open = self.node:child(delim, self.node.start_row)
    -- the block ends on the row after its fence, unless it ends the buffer
    local close = self.node:child(delim, self.node.end_row - 1)
        or self.node:child(delim, self.node.end_row)
    if close and close.start_row == self.node.start_row then
        close = nil
    end
    local content = self.node:child('code_fence_content')
    if not open or not close or not content then
        return false
    end
    -- neovim does not hide lines below this level
    if self.context.conceal.level < 2 then
        return false
    end
    -- the quote bar cannot be drawn on virtual lines
    if self.node:parent('block_quote') then
        return false
    end
    local cmd = self.config.converter
    if #cmd == 0 or vim.fn.executable(cmd[1]) ~= 1 then
        log.add('debug', 'ConverterNotFound', cmd)
        return false
    end

    local buf = self.context.buf
    local result = job.run({
        cmd = cmd,
        stdin = Render.input(content),
        timeout = self.config.timeout,
    }, function(out)
        -- half typed diagrams fail on every edit, so this is not an error
        if not out.ok then
            log.add('debug', 'ConverterFailed', cmd, out.stderr)
        end
        Render.refresh(buf)
    end)
    if not result or not result.ok then
        return false
    end
    local output =
        iter.list.map(str.split(result.stdout, '\n', false), Render.clean)
    while #output > 0 and vim.trim(output[#output]) == '' do
        output[#output] = nil
    end
    if #output == 0 then
        return false
    end

    self.data = { open = open, close = close, output = output }
    return true
end

---@protected
function Render:run()
    local open, close = self.data.open, self.data.close
    -- the cursor anywhere from the opening to the closing fence shows source
    ---@type renderer.mark.Reveal
    local reveal = {
        rows = { open.start_row, close.start_row },
        always = self.config.always_reveal,
    }

    self.marks:add(self.config, true, open.start_row + 1, 0, {
        end_row = close.start_row,
        end_col = close.end_col,
        conceal_lines = '',
    }, reveal)

    -- pad to one width so the highlight reads as a block
    local output = self.data.output
    local width = vim.fn.max(iter.list.map(output, str.width))
    local col = open.start_col + str.spaces('start', open.text)
    local indent = self:indent():line(true):pad(col)
    local lines = iter.list.map(output, function(line)
        local text = line .. str.pad(width - str.width(line))
        return indent:copy():text(text, self.config.highlight):get()
    end)
    self.marks:add(self.config, true, open.start_row, 0, {
        virt_lines = lines,
        virt_lines_above = false,
    }, reveal)
end

---The text between the fences as the tool expects it. The first line starts
---at the column of the content, every other line at column 0 of the buffer,
---so the block's own indentation is removed from those
---@private
---@param content renderer.Node
---@return string
function Render.input(content)
    local lines = str.split(content.text, '\n', false)
    for i = 2, #lines do
        local line = lines[i]
        local spaces = math.min(str.spaces('start', line), content.start_col)
        lines[i] = line:sub(spaces + 1)
    end
    return table.concat(lines, '\n')
end

---Virtual text shows control characters as ^M and ^I, so carriage returns are
---dropped and tabs expanded
---@private
---@param line string
---@return string
function Render.clean(line)
    line = line:gsub('\r', '')
    local parts = {} ---@type string[]
    local width = 0
    for text, tab in line:gmatch('([^\t]*)(\t?)') do
        parts[#parts + 1] = text
        width = width + str.width(text)
        if tab ~= '' then
            local spaces = 8 - width % 8
            parts[#parts + 1] = str.pad(spaces)
            width = width + spaces
        end
    end
    return table.concat(parts)
end

---Updates the buffer once for every batch of jobs that finish together
---@private
---@param buf integer
function Render.refresh(buf)
    if Render.pending[buf] then
        return
    end
    Render.pending[buf] = true
    vim.schedule(function()
        Render.pending[buf] = nil
        -- rendering may have been turned off while the job ran
        if not env.buf.valid(buf) or not state.get(buf).enabled then
            return
        end
        local win = env.buf.win(buf)
        if win ~= -1 then
            require('renderer.core.ui').update(buf, win, 'Job', true)
        end
    end)
end

return Render
