local str = require('renderer.lib.str')

---Column widths of a csv, tsv or psv buffer. Measuring the whole file is too
---slow for large files and measuring only the rows on screen makes the columns
---jump while scrolling, so the widths are taken from the first rows plus every
---row that has been in view, and a width only grows until the buffer changes.
---@class renderer.csv.Widths
local M = {}

---@class renderer.csv.widths.Cache
---@field tick integer
---@field sample_rows integer
---@field max_width integer
---@field widths integer[]

---@private
---@type table<integer, renderer.csv.widths.Cache>
M.cache = {}

---@private
---@type boolean
M.initialized = false

---The widths computed for the buffer by the last `update`
---@param buf integer
---@return integer[]
function M.get(buf)
    local cache = M.cache[buf]
    return cache and cache.widths or {}
end

---Make sure the widths cover the first rows of the file and the given rows
---@param context renderer.request.Context
---@param root TSNode
---@param rows renderer.Node[] the rows in view
function M.update(context, root, rows)
    M.init()
    local config = context.config.csv
    local tick = vim.api.nvim_buf_get_changedtick(context.buf)
    local cache = M.cache[context.buf]
    if
        not cache
        or cache.tick ~= tick
        or cache.sample_rows ~= config.sample_rows
        or cache.max_width ~= config.max_width
    then
        cache = {
            tick = tick,
            sample_rows = config.sample_rows,
            max_width = config.max_width,
            widths = {},
        }
        M.cache[context.buf] = cache
        for i = 0, config.sample_rows - 1 do
            local row = root:named_child(i)
            if not row then
                break
            end
            M.grow(context.buf, cache, row)
        end
    end
    for _, row in ipairs(rows) do
        M.grow(context.buf, cache, row:get())
    end
end

---@param buf integer
function M.clear(buf)
    M.cache[buf] = nil
end

---@private
function M.init()
    if M.initialized then
        return
    end
    M.initialized = true
    vim.api.nvim_create_autocmd('BufWipeout', {
        group = vim.api.nvim_create_augroup('RendererCsvWidths', {}),
        callback = function(args)
            M.clear(args.buf)
        end,
    })
end

---A row that holds a line break is drawn as source, so it takes no part
---@private
---@param buf integer
---@param cache renderer.csv.widths.Cache
---@param row TSNode
function M.grow(buf, cache, row)
    local start_row, _, end_row = row:range()
    if row:type() ~= 'row' or start_row ~= end_row or row:has_error() then
        return
    end
    local index = 0
    for child in row:iter_children() do
        if child:named() then
            index = index + 1
            local text = vim.treesitter.get_node_text(child, buf)
            local width = math.min(str.width(text), cache.max_width)
            cache.widths[index] = math.max(cache.widths[index] or 0, width)
        end
    end
end

return M
