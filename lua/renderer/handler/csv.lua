local Context = require('renderer.request.context')
local Marks = require('renderer.lib.marks')
local Widths = require('renderer.render.csv.widths')

---@class renderer.handler.Csv: renderer.Handler
local M = {}

---@private
---@type table<string, vim.treesitter.Query>
M.queries = {}

---Used for csv, tsv and psv, so the language comes from the tree. `ts.parse`
---caches by query text alone, which would hand the csv query to a tsv tree.
---@private
---@param ctx renderer.handler.Context
---@return vim.treesitter.Query
function M.query(ctx)
    local parser = vim.treesitter.get_parser(ctx.buf)
    local language = parser:language_for_range({ ctx.root:range() }):lang()
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
    local query = M.query(ctx)
    ---@type table<string, renderer.Render>
    local renders = {
        row = require('renderer.render.csv.row'),
    }
    local context = Context.get(ctx.buf)
    if not context.config.csv.enabled then
        return {}
    end
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
