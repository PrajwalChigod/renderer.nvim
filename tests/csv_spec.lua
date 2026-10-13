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
            assert.not_nil(handler.queries[filetype])
        end)

        it(filetype .. ' does not attach when not listed', function()
            local buf = setup(filetype, { 'markdown' })
            assert.is_false(manager.attached(buf))
        end)
    end

    it('leaves a csv block fenced in markdown as a code block', function()
        util.setup.text(
            { '# heading', '', '```csv', 'a,b', '1,2', '```' },
            { file_types = { 'markdown', 'csv' } }
        )
        -- the injected tree reaches the csv handler, which must not stop the
        -- markdown render nor draw the block as a table
        assert.is_true(#util.actual_marks() > 0)
        for _, text in ipairs(util.actual_screen()) do
            assert.is_nil(text:find('│', 1, true))
        end
    end)

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

---@param marks renderer.test.Marks
---@param row integer
---@param width integer
---@param highlight string
local function line(marks, row, width, highlight)
    marks:add({ row, row }, { 0, width }, {
        hl_eol = false,
        hl_group = highlight,
    })
end

---@param marks renderer.test.Marks
---@param row integer
---@param col integer
---@param highlight string
---@param char? string
local function border(marks, row, col, highlight, char)
    marks:add({ row, row }, { col, col + 1 }, {
        virt_text = { { char or '│', highlight } },
        virt_text_pos = 'overlay',
    })
end

---@param marks renderer.test.Marks
---@param row integer
---@param col integer
---@param spaces integer
---@param highlight string
local function pad(marks, row, col, spaces, highlight)
    marks:add(row, col, {
        priority = 0,
        virt_text = { { (' '):rep(spaces), highlight } },
        virt_text_pos = 'inline',
    })
end

---@param marks renderer.test.Marks
---@param row integer
---@param text string
local function rule(marks, row, text)
    marks:add(row, 0, {
        virt_lines = { { { text, 'RmTableHead' } } },
        virt_lines_above = false,
    })
end

---@param opts? renderer.UserConfig
---@param lines? string[]
---@param filetype? string
local function render(lines, opts, filetype)
    local config = vim.tbl_deep_extend('force', {
        file_types = { 'markdown', 'csv', 'tsv', 'psv' },
    }, opts or {})
    util.setup.text(lines, config, filetype or 'csv')
end

---@type string[]
local plain = { 'name,city', 'Ada,London', 'Alan Turing,Rome' }

describe('csv rows', function()
    it('line up fields in columns, header rule below the first row', function()
        render(plain)
        local marks = util.marks()
        line(marks, 0, 9, 'RmTableHead')
        pad(marks, 0, 4, 7, 'RmTableHead')
        border(marks, 0, 4, 'RmTableHead')
        pad(marks, 0, 9, 2, 'RmTableHead')
        rule(marks, 0, '───────────┼──────')
        line(marks, 1, 10, 'RmTableRow')
        pad(marks, 1, 3, 8, 'RmTableRow')
        border(marks, 1, 3, 'RmTableRow')
        line(marks, 2, 16, 'RmTableRow')
        border(marks, 2, 11, 'RmTableRow')
        pad(marks, 2, 16, 2, 'RmTableRow')
        util.assert_view(marks, {
            'name       │city',
            '───────────┼──────',
            'Ada        │London',
            'Alan Turing│Rome',
        })
    end)

    it('header = false draws the first row like any other', function()
        render(plain, { csv = { header = false } })
        local marks = util.marks()
        line(marks, 0, 9, 'RmTableRow')
        pad(marks, 0, 4, 7, 'RmTableRow')
        border(marks, 0, 4, 'RmTableRow')
        pad(marks, 0, 9, 2, 'RmTableRow')
        line(marks, 1, 10, 'RmTableRow')
        pad(marks, 1, 3, 8, 'RmTableRow')
        border(marks, 1, 3, 'RmTableRow')
        line(marks, 2, 16, 'RmTableRow')
        border(marks, 2, 11, 'RmTableRow')
        pad(marks, 2, 16, 2, 'RmTableRow')
        util.assert_view(marks, {
            'name       │city',
            'Ada        │London',
            'Alan Turing│Rome',
        })
    end)

    it('align numbers to the right and text to the left', function()
        render({
            'item,qty,price',
            'apple,3,0.5',
            'melon,120,-12.25',
            'fig,7,4',
        })
        util.assert_screen({
            'item │qty│price',
            '─────┼───┼──────',
            'apple│  3│   0.5',
            'melon│120│-12.25',
            'fig  │  7│     4',
        })
    end)

    it('keep a quoted field with a comma in one column', function()
        render({ 'a,b', '"x, y",z', 'q,r' })
        util.assert_screen({
            'a     │b',
            '──────┼─',
            '"x, y"│z',
            'q     │r',
        })
    end)

    it('leave a row with a missing last field aligned', function()
        render({ 'id,name,score', '1,Ada', '22,Alan,5' })
        util.assert_screen({
            'id│name│score',
            '──┼────┼─────',
            ' 1│Ada',
            '22│Alan│    5',
        })
    end)

    it('pad an empty field', function()
        render({ 'a,b,c', '1,,3', '22,x,' })
        util.assert_screen({
            'a │b│c',
            '──┼─┼─',
            ' 1│ │3',
            '22│x│',
        })
    end)

    it('leave a row with a line break in a field as source', function()
        render({ 'a,b', '"x', 'y",z', 'q,r' })
        util.assert_screen({
            'a│b',
            '─┼─',
            '"x',
            'y",z',
            'q│r',
        })
    end)

    it('cut a field longer than max_width with an ellipsis', function()
        render(
            { 'id,note', '1,short', '2,a rather long note' },
            { csv = { max_width = 6 } }
        )
        util.assert_screen({
            'id│note',
            '──┼──────',
            ' 1│short',
            ' 2│a rat…',
        })
    end)

    it('cut before a wide character that does not fit', function()
        render({ 'a,b', '1,日本語日本語' }, { csv = { max_width = 4 } })
        util.assert_screen({
            'a│b',
            '─┼────',
            '1│日…',
        })
    end)

    it('shows the whole field on the cursor row', function()
        render(
            { 'id,note', '2,a rather long note' },
            { csv = { max_width = 6 }, anti_conceal = { enabled = true } }
        )
        util.set_row(2)
        util.assert_screen({
            'id│note',
            '──┼──────',
            '2,a rather long note',
        })
    end)

    it('hide the separator for a border wider than one cell', function()
        render({ 'a,b,c', '1,2,3' }, { csv = { border = ' │ ' } })
        util.assert_screen({
            'a │ b │ c',
            '──┼───┼──',
            '1 │ 2 │ 3',
        })
    end)

    it('render nothing when disabled', function()
        render(plain, { csv = { enabled = false } })
        util.assert_marks({})
        util.assert_screen(plain)
    end)

    for filetype, separator in pairs({ tsv = '\t', psv = '|' }) do
        it(filetype .. ' renders the same table', function()
            local lines = vim.tbl_map(function(text)
                return (text:gsub(',', separator))
            end, plain)
            render(lines, nil, filetype)
            util.assert_screen({
                'name       │city',
                '───────────┼──────',
                'Ada        │London',
                'Alan Turing│Rome',
            })
        end)
    end

    it('shows the source of the row under the cursor', function()
        render(plain, { anti_conceal = { enabled = true } })
        util.set_row(2)
        util.assert_screen({
            'name       │city',
            '───────────┼──────',
            'Ada,London',
            'Alan Turing│Rome',
        })
    end)
end)

describe('csv window', function()
    -- the first update of a buffer runs at once and the next ones inside the
    -- debounce window are dropped, so wait before acting on the buffer
    local function settle()
        vim.wait(150)
    end

    it('keeps rendering after scrolling right', function()
        local long = ('x'):rep(120)
        render({ 'a,b', long .. ',1', 'c,d' })
        local before = #util.actual_marks()
        assert.is_true(before > 0)
        settle()
        vim.cmd('normal! 5zl')
        vim.api.nvim_exec_autocmds('WinScrolled', {})
        vim.wait(0)
        assert.same(5, vim.fn.winsaveview().leftcol)
        assert.same(before, #util.actual_marks())
    end)

    it('moves the header rule with the rows when scrolled right', function()
        render(plain)
        settle()
        vim.cmd('normal! 5zl')
        vim.api.nvim_exec_autocmds('WinScrolled', {})
        vim.wait(0)
        util.assert_screen({
            '      │city',
            '──────┼──────',
            '      │London',
            'Turing│Rome',
        })
    end)

    for filetype, separator in pairs({ csv = ',', psv = '|' }) do
        it(filetype .. ' hides a border scrolled out on the left', function()
            local lines = vim.tbl_map(function(text)
                return (text:gsub(',', separator))
            end, plain)
            render(lines, nil, filetype)
            settle()
            -- far enough for the separator to leave the window, an overlay
            -- is drawn at the first column otherwise and covers a character
            vim.cmd('normal! 13zl')
            vim.api.nvim_exec_autocmds('WinScrolled', {})
            vim.wait(0)
            assert.same(13, vim.fn.winsaveview().leftcol)
            util.assert_screen({
                'ity',
                '─────',
                'ondon',
                'ome',
            })
        end)
    end

    it('turns wrap off while rendered and restores it after', function()
        local filetype =
            { csv = { win_options = { wrap = { default = true } } } }
        render(plain, { overrides = { filetype = filetype } })
        assert.is_false(vim.wo.wrap)
        settle()
        require('renderer').disable()
        vim.wait(0)
        assert.is_true(vim.wo.wrap)
        settle()
        require('renderer').enable()
        vim.wait(0)
        assert.is_false(vim.wo.wrap)
    end)

    it('widens a column when a field becomes the widest', function()
        render(plain)
        settle()
        local row = { 'Ada Lovelace Byron,London' }
        vim.api.nvim_buf_set_lines(0, 1, 2, false, row)
        vim.api.nvim_exec_autocmds('TextChanged', {})
        vim.wait(0)
        util.assert_screen({
            'name              │city',
            '──────────────────┼──────',
            'Ada Lovelace Byron│London',
            'Alan Turing       │Rome',
        })
    end)

    it('keeps a column wide after its widest row scrolls away', function()
        local lines = { 'a,b', 'wide field,1' }
        for i = 1, 100 do
            lines[#lines + 1] = ('%d,%d'):format(i, i)
        end
        -- only the first rows are sampled, the rows in view are added later
        render(lines, { csv = { sample_rows = 2 } })
        settle()
        vim.cmd('normal! G')
        vim.api.nvim_exec_autocmds('WinScrolled', {})
        vim.wait(0)
        local buf = vim.api.nvim_get_current_buf()
        assert.same(10, require('renderer.render.csv.widths').get(buf)[1])
        local screen = util.actual_screen()
        assert.is_true(vim.tbl_contains(screen, '       100│100'))
    end)
end)
