---@module 'luassert'

local job = require('renderer.lib.job')
local spy = require('luassert.spy')
local util = require('tests.util')

---Lets the job callback and the update it schedules run
local function settle()
    for _ = 1, 10 do
        vim.wait(10)
    end
end

---@param lines string[]
---@param opts? renderer.UserConfig
local function setup(lines, opts)
    util.setup.text(lines, opts)
    settle()
end

---@param key string
local function press(key)
    vim.cmd.normal({ key, bang = true })
    vim.api.nvim_exec_autocmds('CursorMoved', {})
    settle()
end

---@param col integer
---@param ... string
---@return vim.api.keyset.set_extmark
local function diagram(col, ...)
    local lines = {} ---@type renderer.mark.Line[]
    for _, text in ipairs({ ... }) do
        local line = {} ---@type renderer.mark.Line
        if col > 0 then
            line[#line + 1] = { (' '):rep(col), 'RmPadding' }
        end
        line[#line + 1] = { text, 'RmMermaid' }
        lines[#lines + 1] = line
    end
    ---@type vim.api.keyset.set_extmark
    return {
        virt_lines = lines,
        virt_lines_above = false,
    }
end

describe('mermaid', function()
    local lr = {
        input = 'graph LR\n  Start --> End\n',
        output = {
            '┌───────┐     ┌─────┐',
            '│ Start ├────►│ End │',
            '└───────┘     └─────┘',
        },
    }

    local td = {
        input = 'graph TD\n  A --> B\n',
        output = {
            '┌───┐',
            '│ A │',
            '└─┬─┘',
            '  ▼',
            '┌───┐',
            '│ B │',
            '└───┘',
        },
    }

    local lines = {
        '```mermaid',
        'graph LR',
        '  Start --> End',
        '```',
        '',
        'after',
    }

    ---@type renderer.UserConfig
    local plain = { code = { enabled = false } }

    before_each(function()
        job.reset()
        util.system.mock('mermaid-ascii', {
            [lr.input] = lr.output,
            [td.input] = td.output,
            ['graph LR\n  broken\n'] = false,
            ['graph LR\n  Start --> Stop\n'] = { 'Start -> Stop' },
            ['graph LR\n  Tab --> Cr\n'] = { 'one\r', 'a\tb' },
        })
    end)

    after_each(function()
        util.system.revert()
    end)

    it('default', function()
        setup(lines)
        util.assert_screen({
            '󰫺 󰫺 mermaid' .. ('█'):rep(69),
            '  ┌───────┐     ┌─────┐',
            '  │ Start ├────►│ End │',
            '  └───────┘     └─────┘',
            '',
            '  after',
        })
    end)

    it('marks', function()
        setup(lines, plain)
        local marks = util.marks()
        marks:add({ 1, 3 }, { 0, 3 }, util.conceal_lines())
        marks:add(0, 0, diagram(0, unpack(lr.output)))
        util.assert_view(marks, {
            '```mermaid',
            '┌───────┐     ┌─────┐',
            '│ Start ├────►│ End │',
            '└───────┘     └─────┘',
            '',
            'after',
        })
    end)

    it('pads lines to one width', function()
        setup({ '```mermaid', 'graph TD', '  A --> B', '```' }, plain)
        local marks = util.marks()
        marks:add({ 1, 3 }, { 0, 3 }, util.conceal_lines())
        local padded = vim.deepcopy(td.output)
        padded[4] = '  ▼  '
        marks:add(0, 0, diagram(0, unpack(padded)))
        util.assert_marks(marks:get())
    end)

    it('waits for the converter', function()
        util.system.mock('mermaid-ascii', { [lr.input] = lr.output }, {
            hold = true,
        })
        setup(lines, plain)
        util.assert_view(util.marks(), lines)
        util.system.release()
        settle()
        util.assert_screen({
            '```mermaid',
            '┌───────┐     ┌─────┐',
            '│ Start ├────►│ End │',
            '└───────┘     └─────┘',
            '',
            'after',
        })
    end)

    it('converter fails', function()
        local broken = { '```mermaid', 'graph LR', '  broken', '```' }
        setup(broken, plain)
        util.assert_view(util.marks(), broken)
        local buf, win =
            vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
        require('renderer.core.ui').update(buf, win, 'Test', true)
        settle()
        util.assert_view(util.marks(), broken)
        assert.same(1, #vim.system.calls)
    end)

    it('cleans control characters from the output', function()
        setup({ '```mermaid', 'graph LR', '  Tab --> Cr', '```' }, plain)
        local marks = util.marks()
        marks:add({ 1, 3 }, { 0, 3 }, util.conceal_lines())
        marks:add(0, 0, diagram(0, 'one      ', 'a       b'))
        util.assert_marks(marks:get())
    end)

    it('skips the update when rendering was turned off', function()
        util.system.mock('mermaid-ascii', { [lr.input] = lr.output }, {
            hold = true,
        })
        setup(lines, plain)
        require('renderer').buf_disable()
        settle()
        local ui = require('renderer.core.ui')
        local update = spy.on(ui, 'update')
        util.system.release()
        settle()
        update:revert()
        assert.same(0, #update.calls)
        util.assert_screen(lines)
    end)

    it('converter missing', function()
        util.system.mock('other-tool', {})
        setup(lines, plain)
        util.assert_view(util.marks(), lines)
        assert.same(0, #vim.system.calls)
    end)

    it('disabled', function()
        setup(
            lines,
            { code = { enabled = false }, mermaid = { enabled = false } }
        )
        util.assert_view(util.marks(), lines)
        assert.same(0, #vim.system.calls)
    end)

    it('other language', function()
        local code = { '```lua', 'print(1)', '```' }
        setup(code, plain)
        util.assert_view(util.marks(), code)
        assert.same(0, #vim.system.calls)
    end)

    it('two blocks', function()
        setup({
            '```mermaid',
            'graph LR',
            '  Start --> End',
            '```',
            '',
            '```mermaid',
            'graph TD',
            '  A --> B',
            '```',
        }, plain)
        util.assert_screen({
            '```mermaid',
            '┌───────┐     ┌─────┐',
            '│ Start ├────►│ End │',
            '└───────┘     └─────┘',
            '',
            '```mermaid',
            '┌───┐',
            '│ A │',
            '└─┬─┘',
            '  ▼',
            '┌───┐',
            '│ B │',
            '└───┘',
        })
    end)

    it('list item', function()
        setup({
            '- item',
            '',
            '  ```mermaid',
            '  graph LR',
            '    Start --> End',
            '  ```',
        }, { code = { enabled = false }, bullet = { enabled = false } })
        local marks = util.marks()
        marks:add({ 3, 5 }, { 0, 5 }, util.conceal_lines())
        marks:add(2, 0, diagram(2, unpack(lr.output)))
        util.assert_view(marks, {
            '- item',
            '',
            '  ```mermaid',
            '  ┌───────┐     ┌─────┐',
            '  │ Start ├────►│ End │',
            '  └───────┘     └─────┘',
        })
    end)

    it('block quote', function()
        local quote =
            { '> ```mermaid', '> graph LR', '>   Start --> End', '> ```' }
        setup(
            quote,
            { code = { enabled = false }, quote = { enabled = false } }
        )
        util.assert_view(util.marks(), quote)
        assert.same(0, #vim.system.calls)
    end)

    describe('cursor', function()
        ---@type renderer.UserConfig
        local reveal = {
            code = { enabled = false },
            anti_conceal = { enabled = true },
        }

        local source = {
            '```mermaid',
            'graph LR',
            '  Start --> End',
            '```',
            '',
            'after',
        }

        local rendered = {
            '```mermaid',
            '┌───────┐     ┌─────┐',
            '│ Start ├────►│ End │',
            '└───────┘     └─────┘',
            '',
            'after',
        }

        it('reveals the source anywhere in the block', function()
            setup(lines, reveal)
            util.set_row(6)
            util.assert_screen(rendered)
            util.set_row(1)
            util.assert_screen(source)
            util.set_row(2)
            util.assert_screen(source)
            util.set_row(5)
            util.assert_screen(rendered)
        end)

        it('enters from above and below', function()
            setup({ 'before', unpack(lines) }, reveal)
            util.set_row(1)
            util.assert_screen({ 'before', unpack(rendered) })
            press('j')
            assert.same(2, vim.api.nvim_win_get_cursor(0)[1])
            util.assert_screen({ 'before', unpack(source) })
            util.set_row(6)
            util.assert_screen({ 'before', unpack(rendered) })
            press('k')
            assert.same(5, vim.api.nvim_win_get_cursor(0)[1])
            util.assert_screen({ 'before', unpack(source) })
        end)

        it('stays drawn when anti conceal is off', function()
            setup(lines, plain)
            util.set_row(1)
            util.assert_screen(rendered)
        end)

        it('always_reveal with anti conceal off', function()
            setup({ 'before', unpack(lines) }, {
                code = { enabled = false },
                mermaid = { always_reveal = true },
            })
            util.set_row(1)
            util.assert_screen({ 'before', unpack(rendered) })
            press('j')
            assert.same(2, vim.api.nvim_win_get_cursor(0)[1])
            util.assert_screen({ 'before', unpack(source) })
            util.set_row(3)
            util.assert_screen({ 'before', unpack(source) })
            util.set_row(6)
            util.assert_screen({ 'before', unpack(rendered) })
            press('k')
            assert.same(5, vim.api.nvim_win_get_cursor(0)[1])
            util.assert_screen({ 'before', unpack(source) })
        end)

        describe('always_reveal jumps', function()
            ---@type renderer.UserConfig
            local always = {
                code = { enabled = false },
                mermaid = { always_reveal = true },
            }

            ---@param row integer
            local function jump(row)
                util.set_row(1)
                settle()
                util.set_row(row)
                settle()
            end

            it('stay on the row jumped to', function()
                setup({ 'before', unpack(lines) }, always)
                for _, row in ipairs({ 3, 4, 5 }) do
                    jump(row)
                    assert.same(row, vim.api.nvim_win_get_cursor(0)[1])
                    util.assert_screen({ 'before', unpack(source) })
                end
            end)

            it('reveal before the update is scheduled', function()
                setup({ 'before', unpack(lines) }, always)
                util.set_row(1)
                settle()
                vim.api.nvim_win_set_cursor(0, { 4, 0 })
                vim.api.nvim_exec_autocmds('CursorMoved', {})
                -- nothing scheduled has run, so this is what the next frame shows
                local range = { start_row = 3, end_row = 3 }
                assert.same(1, vim.api.nvim_win_text_height(0, range).all)
                assert.same(4, vim.api.nvim_win_get_cursor(0)[1])
            end)

            it('a jump that scrolls past the parsed rows', function()
                -- the block is drawn, being inside the parse margin below the
                -- window, and the jump scrolls the view past that margin
                local height = vim.o.lines
                local text = {} ---@type string[]
                for i = 1, height + 3 do
                    text[#text + 1] = ('filler %d'):format(i)
                end
                local start = #text + 1
                vim.list_extend(text, lines)
                for i = 1, 2 * height do
                    text[#text + 1] = ('tail %d'):format(i)
                end
                setup(text, always)
                local ui = require('renderer.core.ui')
                local drawn = vim.api.nvim_buf_get_extmarks(
                    0,
                    ui.ns,
                    { start - 1, 0 },
                    { start + 3, 0 },
                    {}
                )
                assert.is_true(#drawn > 0, 'block drawn before the jump')
                vim.fn.search('Start')
                vim.cmd('normal! zz')
                vim.api.nvim_exec_autocmds('CursorMoved', {})
                settle()
                assert.same(start + 2, vim.api.nvim_win_get_cursor(0)[1])
                local range = { start_row = start + 1, end_row = start + 1 }
                assert.same(1, vim.api.nvim_win_text_height(0, range).all)
            end)

            it('search into the block', function()
                setup({ 'before', unpack(lines) }, always)
                util.set_row(1)
                settle()
                vim.fn.search('Start')
                vim.api.nvim_exec_autocmds('CursorMoved', {})
                settle()
                assert.same(4, vim.api.nvim_win_get_cursor(0)[1])
                util.assert_screen({ 'before', unpack(source) })
            end)

            it('closing fence hidden by the code renderer', function()
                setup({ 'before', unpack(lines) }, {
                    code = { border = 'hide', sign = false },
                    mermaid = { always_reveal = true },
                })
                util.set_row(6)
                settle()
                press('k')
                assert.same(4, vim.api.nvim_win_get_cursor(0)[1])
                -- like any hidden line, passed in the direction of travel
                jump(5)
                assert.same(6, vim.api.nvim_win_get_cursor(0)[1])
            end)
        end)
    end)

    it('redraws after an edit', function()
        setup(lines, plain)
        vim.api.nvim_buf_set_lines(0, 2, 3, false, { '  Start --> Stop' })
        vim.api.nvim_exec_autocmds('TextChanged', { buffer = 0 })
        settle()
        util.assert_screen({
            '```mermaid',
            'Start -> Stop',
            '',
            'after',
        })
        assert.same(2, #vim.system.calls)
    end)
end)
