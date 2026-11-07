local Context = require('renderer.request.context')
local Marks = require('renderer.lib.marks')
local Widths = require('renderer.render.csv.widths')

---@class renderer.handler.Csv: renderer.Handler
local M = {}

---@private
---@type table<string, vim.treesitter.Query>
M.queries = {}

---The handler map is shared between formats, so a csv block fenced in a
---markdown file reaches this handler as an injected tree. Only a buffer of the
---csv family is drawn as a table, the fenced block stays a code block.
---@private
---@param context renderer.request.Context
---@return string?
function M.language(context)
    local format = context.format
    local language = format and format.root
    if language and format.handlers[language] == 'renderer.handler.csv' then
        return language
    end
    return nil
end

---Used for csv, tsv and psv. `ts.parse` caches by query text alone, which
---would hand the csv query to a tsv tree.
---@private
---@param language string
---@return vim.treesitter.Query
function M.query(language)
    local result = M.queries[language]
    if not result then
        result = vim.treesitter.query.parse(language, '(row) @row')
        M.queries[language] = result
    end
    return result
end

---@param ctx renderer.handler.Context
---@return renderer.Mark[]
function M.parse(ctx)
    local context = Context.get(ctx.buf)
    local language = M.language(context)
    if not language or not context.config.csv.enabled then
        return {}
    end
    local query = M.query(language)
    ---@type table<string, renderer.Render>
    local renders = {
        row = require('renderer.render.csv.row'),
    }
    -- every row is padded to the widest field of its column, so the widths
    -- must be known before the first one is drawn
    ---@type { capture: string, node: renderer.Node }[]
    local nodes = {}
    context.view:nodes(ctx.root, query, function(capture, node)
        nodes[#nodes + 1] = { capture = capture, node = node }
    end)
    Widths.update(
        context,
        ctx.root,
        vim.tbl_map(function(item)
            return item.node
        end, nodes)
    )
    local marks = Marks.new(context, true)
    for _, item in ipairs(nodes) do
        local render = renders[item.capture]
        assert(render, ('unhandled csv capture: %s'):format(item.capture))
        render:execute(context, marks, item.node)
    end
    return marks:get()
end

return M
