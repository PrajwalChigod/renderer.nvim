---@module 'luassert'

local manager = require('renderer.core.manager')
local state = require('renderer.state')
local util = require('tests.util')

---@param filetype string
---@param file_types string[]
---@param opts? renderer.UserConfig
---@return integer
local function setup(filetype, file_types, opts)
    local config =
        vim.tbl_deep_extend('force', { file_types = file_types }, opts or {})
    util.setup.text({ 'a,b', '1,2' }, config, filetype)
    return vim.api.nvim_get_current_buf()
end

describe('csv', function()
    for _, filetype in ipairs({ 'csv', 'tsv', 'psv' }) do
        it(filetype .. ' attaches when listed in file_types', function()
            local buf = setup(filetype, { 'markdown', filetype })
            assert.is_true(manager.attached(buf))
        end)

        it(filetype .. ' runs its handler with its own language', function()
            setup(filetype, { 'markdown', filetype })
            local handler = require('renderer.handler.csv')
            assert.is_not_nil(handler.queries[filetype])
            -- nothing is dispatched to a renderer yet
            util.assert_view(util.marks(), { 'a,b', '1,2' })
        end)

        it(filetype .. ' does not attach when not listed', function()
            local buf = setup(filetype, { 'markdown' })
            assert.is_false(manager.attached(buf))
        end)
    end

    it('format defaults reach the buffer config', function()
        setup('csv', { 'markdown', 'csv' })
        local wrap = state.get(0).win_options.wrap
        assert.same({ default = vim.o.wrap, rendered = false }, wrap)
        -- the markdown defaults are untouched
        assert.same(3, state.get(0).win_options.conceallevel.rendered)
    end)

    it('format defaults do not reach other formats', function()
        util.setup.text({ 'text' }, { file_types = { 'markdown', 'csv' } })
        assert.is_nil(state.get(0).win_options.wrap)
    end)

    it('config is valid and has the documented defaults', function()
        setup('csv', { 'markdown', 'csv' })
        assert.same({}, state.validate())
        assert.same({
            enabled = true,
            render_modes = false,
            header = true,
            sample_rows = 200,
            max_width = 40,
            border = '│',
            head = 'RendererTableHead',
            row = 'RendererTableRow',
        }, state.get(0).csv)
    end)

    it('config rejects a value of the wrong type', function()
        util.setup.text({ 'text' }, {
            file_types = { 'markdown' },
            csv = { sample_rows = 'many' },
        })
        assert.is_true(#state.validate() > 0)
    end)
end)
