local Context = require('renderer.request.context')
local Marks = require('renderer.lib.marks')
local ts = require('renderer.core.ts')

---@class renderer.handler.Markdown: renderer.Handler
local M = {}

---@param ctx renderer.handler.Context
---@return renderer.Mark[]
function M.parse(ctx)
    -- stylua: ignore
    local query = ts.parse('markdown', [[
        (fenced_code_block) @code

        [
            (thematic_break)
            (minus_metadata)
            (plus_metadata)
        ] @dash

        (document) @document

        (link_reference_definition (link_label) @footnote)

        [
            (atx_heading)
            (setext_heading)
        ] @heading

        (list_item) @list

        (section (paragraph) @paragraph)

        (block_quote) @quote

        (section) @section

        (pipe_table) @table
    ]])
    ---@type table<string, renderer.Render>
    local renders = {
        code = require('renderer.render.markdown.code'),
        dash = require('renderer.render.markdown.dash'),
        document = require('renderer.render.markdown.document'),
        footnote = require('renderer.render.common.footnote'),
        heading = require('renderer.render.markdown.heading'),
        list = require('renderer.render.markdown.list'),
        paragraph = require('renderer.render.markdown.paragraph'),
        quote = require('renderer.render.markdown.quote'),
        section = require('renderer.render.markdown.section'),
        table = require('renderer.render.markdown.table'),
    }
    -- run after the renderer of the same capture, on the same node
    ---@type table<string, renderer.Render>
    local extras = {
        code = require('renderer.render.markdown.mermaid'),
    }
    local context = Context.get(ctx.buf)
    local marks = Marks.new(context, false)
    context.view:nodes(ctx.root, query, function(capture, node)
        local render = renders[capture]
        assert(render, ('unhandled markdown capture: %s'):format(capture))
        render:execute(context, marks, node)
        local extra = extras[capture]
        if extra then
            extra:execute(context, marks, node)
        end
    end)
    return marks:get()
end

return M
