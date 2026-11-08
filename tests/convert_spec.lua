---@module 'luassert'

local job = require('renderer.lib.job')
local log = require('renderer.core.log')
local manager = require('renderer.core.manager')
local spy = require('luassert.spy')
local state = require('renderer.state')
local ui = require('renderer.core.ui')
local util = require('tests.util')

---@param converter? renderer.converter.UserConfig
---@param opts? renderer.UserConfig
---@return renderer.UserConfig
local function config(converter, opts)
    ---@type renderer.UserConfig
    local result = {
        file_types = { 'markdown', 'docx' },
        convert = {
            docx = {
                converters = {
                    converter
                        or { cmd = { 'cat', '{file}' }, output = 'markdown' },
                },
            },
        },
    }
    return vim.tbl_deep_extend('force', result, opts or {})
end

---@param lines string[]
---@return string
local function fixture(lines)
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, 'p')
    local path = vim.fs.joinpath(dir, 'file.docx')
    vim.fn.writefile(lines, path)
    return path
end

---@param path string
---@param opts? renderer.UserConfig
local function open(path, opts)
    util.setup.file(path, opts)
end

---@param first string
local function wait(first)
    assert.is_true(vim.wait(2000, function()
        return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == first
    end))
    -- the render after the filetype is set
    vim.wait(50)
end

---@return string[]
local function lines()
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function source_zip()
    -- it loads once unless this is cleared
    vim.g.loaded_zipPlugin = nil
    vim.cmd.source(vim.env.VIMRUNTIME .. '/plugin/zipPlugin.vim')
end

---@return integer
local function zip()
    local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
        group = 'zip',
        event = 'BufReadCmd',
        pattern = '*.docx',
    })
    return ok and #autocmds or 0
end

describe('convert', function()
    local dir = job.dir

    before_each(function()
        job.reset()
        job.dir = vim.fn.tempname()
    end)

    after_each(function()
        vim.fn.delete(job.dir, 'rf')
        job.dir = dir
        -- the zip plugin is sourced by some specs, drop it again
        pcall(vim.api.nvim_del_augroup_by_name, 'zip')
    end)

    it('renders the converted text as markdown', function()
        open(fixture({ '# Title', '', 'text' }), config())
        wait('# Title')

        local marks = util.marks()
        marks:add(0, 0, util.heading.sign(1))
        marks:add({ 0, 0 }, { 0, 1 }, util.heading.icon(1))
        marks:add({ 0, 1 }, { 0, 0 }, util.heading.bg(1))
        util.assert_view(marks, { '󰫎 󰲡 Title', '', '  text' })
        assert.same('markdown', vim.bo.filetype)
        assert.is_true(manager.attached(vim.api.nvim_get_current_buf()))
    end)

    it('never writes the file', function()
        local path = fixture({ 'source' })
        local before = vim.fn.readfile(path, 'b')
        open(
            path,
            config({ cmd = { 'echo', 'converted' }, output = 'markdown' })
        )
        wait('converted')

        local name = vim.api.nvim_buf_get_name(0)
        assert.same(vim.uv.fs_realpath(path), vim.uv.fs_realpath(name))
        assert.same('nowrite', vim.bo.buftype)
        assert.is_false(vim.bo.modifiable)
        assert.is_false(vim.bo.swapfile)
        assert.is_false(vim.bo.modified)
        assert.has_error(function()
            vim.cmd.write()
        end)
        assert.has_error(function()
            vim.cmd('write!')
        end)
        assert.same(before, vim.fn.readfile(path, 'b'))
    end)

    it('shows a placeholder until the converter is done', function()
        local cmd = { 'sh', '-c', 'sleep 0.2; cat "$0"', '{file}' }
        open(fixture({ 'done' }), config({ cmd = cmd, output = 'markdown' }))
        assert.same({ 'Converting file.docx with sh…' }, lines())
        assert.same('', vim.bo.filetype)
        wait('done')
        assert.same({ 'done' }, lines())
        assert.same('markdown', vim.bo.filetype)
    end)

    it('shows the command and error when it fails', function()
        local cmd = { 'sh', '-c', 'echo broken >&2; exit 1' }
        open(fixture({ 'x' }), config({ cmd = cmd, output = 'markdown' }))
        wait('Could not convert this file, the command failed:')
        assert.same({
            'Could not convert this file, the command failed:',
            '',
            '    sh -c echo broken >&2; exit 1',
            '',
            'broken',
        }, lines())
        assert.same('nowrite', vim.bo.buftype)
        assert.is_false(vim.bo.modifiable)
        assert.is_false(manager.attached(vim.api.nvim_get_current_buf()))
    end)

    it('uses the output of the converter as filetype', function()
        open(
            fixture({ '# x' }),
            config({ cmd = { 'cat', '{file}' }, output = 'text' })
        )
        wait('# x')
        assert.same('text', vim.bo.filetype)
        assert.is_false(manager.attached(vim.api.nvim_get_current_buf()))
    end)

    it('converts again only when the file changes', function()
        local path = fixture({ 'one' })
        local cmd = { 'sh', '-c', 'echo run >> "$0.runs"; cat "$0"', '{file}' }
        local opts = config({ cmd = cmd, output = 'markdown' })
        open(path, opts)
        wait('one')
        vim.cmd.edit()
        wait('one')
        assert.same(1, #vim.fn.readfile(path .. '.runs'))

        vim.fn.writefile({ 'two' }, path)
        vim.uv.fs_utime(path, os.time() + 10, os.time() + 10)
        vim.cmd.edit()
        wait('two')
        assert.same(2, #vim.fn.readfile(path .. '.runs'))
        assert.same('markdown', vim.bo.filetype)
    end)

    it('refuses to write converted text over a docx', function()
        -- run in a child neovim: a typed command runs outside any Lua pcall,
        -- where an error that a spec would see as one does not stop a write
        local dir = vim.fs.dirname(fixture({ 'source' }))
        local path = vim.fs.joinpath(dir, 'file.docx')
        local before = vim.fn.readfile(path, 'b')
        local copy = vim.fs.joinpath(dir, 'copy.md')
        local other = vim.fs.joinpath(dir, 'other.md')
        local opts = vim.inspect(config({ cmd = { 'echo', 'converted' } }))
        local result = vim.system({
            vim.v.progpath,
            '--clean',
            '--headless',
            '--cmd',
            'set rtp^=' .. vim.fn.fnameescape(vim.fn.getcwd()),
            '--cmd',
            'lua vim.g.renderer_config = ' .. opts:gsub('\n', ' '),
            '-c',
            "lua vim.wait(2000, function() return vim.bo.filetype ~= '' end)",
            -- nowrite does not stop writing to a new name
            '-c',
            'saveas ' .. vim.fn.fnameescape(copy),
            '-c',
            'write! ' .. vim.fn.fnameescape(path),
            '-c',
            '1write! ' .. vim.fn.fnameescape(path),
            '-c',
            'write >> ' .. vim.fn.fnameescape(path),
            '-c',
            'write ' .. vim.fn.fnameescape(other),
            '-c',
            'qa!',
            path,
        }, { env = { XDG_CACHE_HOME = dir } }):wait(10000)
        assert.same(0, result.code, result.stderr)
        assert.same(before, vim.fn.readfile(path, 'b'))
        -- other files still take the converted text
        assert.same({ 'converted' }, vim.fn.readfile(copy))
        assert.same({ 'converted' }, vim.fn.readfile(other))
    end)

    it('applies the convert override to converted buffers only', function()
        local default = { 'n', 'c', 't' }
        util.setup.text({ '# x' }, config())
        vim.bo.buftype = 'nowrite'
        -- buffers of other plugins, such as diffview, are nowrite too
        assert.same(default, state.get(0).render_modes)

        open(fixture({ '# x' }), config())
        wait('# x')
        assert.is_true(state.get(0).render_modes)
    end)

    it('renders once when a conversion finishes', function()
        local update = spy.on(ui, 'update')
        local cmd = { 'sh', '-c', 'sleep 0.1; cat "$0"', '{file}' }
        open(fixture({ 'one' }), config({ cmd = cmd, output = 'markdown' }))
        wait('one')
        local events = {} ---@type string[]
        for _, call in ipairs(update.calls) do
            events[#events + 1] = call.refs[3]
        end
        update:revert()
        assert.is_true(vim.tbl_contains(events, 'Initial'))
        assert.is_false(vim.tbl_contains(events, 'Job'))
    end)

    it('drops a conversion finished after the file was read again', function()
        local path = fixture({ 'one' })
        -- the first run is slow, so it finishes after the second
        local script = 'runs=$(cat "$0.runs" 2>/dev/null | wc -l); '
            .. 'echo run >> "$0.runs"; '
            .. 'if [ "$runs" -eq 0 ]; then sleep 0.3; echo first; '
            .. 'else echo second; fi'
        local cmd = { 'sh', '-c', script, '{file}' }
        open(path, config({ cmd = cmd, output = 'markdown' }))
        assert.is_true(vim.wait(2000, function()
            return vim.uv.fs_stat(path .. '.runs') ~= nil
        end))
        vim.fn.writefile({ 'two' }, path)
        vim.uv.fs_utime(path, os.time() + 10, os.time() + 10)
        vim.cmd.edit()
        wait('second')
        vim.wait(500)
        assert.same({ 'second' }, lines())
    end)

    it(
        'logs nothing when the buffer is unloaded during a conversion',
        function()
            local add = spy.on(log, 'add')
            local cmd = { 'sh', '-c', 'sleep 0.1; cat "$0"', '{file}' }
            open(fixture({ 'one' }), config({ cmd = cmd, output = 'markdown' }))
            local buf = vim.api.nvim_get_current_buf()
            vim.cmd.enew()
            vim.cmd.bunload(buf)
            vim.wait(300)
            local errors = vim.tbl_filter(function(call)
                return call.refs[1] == 'error'
            end, add.calls)
            add:revert()
            assert.same(0, #errors)
            assert.is_false(vim.api.nvim_buf_is_loaded(buf))
        end
    )

    it('says so when the file is gone', function()
        local path = fixture({ 'one' })
        open(path, config())
        wait('one')
        vim.fn.delete(path)
        vim.cmd.edit()
        local name = vim.api.nvim_buf_get_name(0)
        assert.same({
            ('Cannot read %s, it was moved or deleted.'):format(name),
        }, lines())
        assert.same('nowrite', vim.bo.buftype)
        assert.is_false(vim.bo.modifiable)
    end)

    it('measures the converted text for max_file_size', function()
        local path = fixture({ ('x'):rep(4000) })
        local cmd = { 'echo', 'small' }
        open(
            path,
            config({ cmd = cmd, output = 'markdown' }, {
                max_file_size = 0.001,
            })
        )
        wait('small')
        assert.is_true(manager.attached(vim.api.nvim_get_current_buf()))
    end)

    it('leaves a new file alone', function()
        local path = vim.fs.joinpath(vim.fn.tempname(), 'new.docx')
        open(path, config())
        assert.same('', vim.bo.buftype)
        assert.is_true(vim.bo.modifiable)
    end)

    it('takes docx over from the zip plugin', function()
        util.setup.init(config())
        -- the zip plugin is sourced after this plugin at startup
        source_zip()
        assert.same(0, zip())
        -- every other archive stays with it
        local xlsx = vim.api.nvim_get_autocmds({
            group = 'zip',
            event = 'BufReadCmd',
            pattern = '*.xlsx',
        })
        assert.same(1, #xlsx)
    end)

    it('does nothing unless docx is in file_types', function()
        util.setup.init({ file_types = { 'markdown' } })
        source_zip()
        assert.same(1, zip())
        local autocmds = vim.api.nvim_get_autocmds({
            group = 'RendererConvert',
        })
        assert.same({}, autocmds)
    end)

    it('does nothing when no converter is installed', function()
        util.setup.init(
            config({ cmd = { 'renderer-missing' }, output = 'text' })
        )
        source_zip()
        assert.same(1, zip())
    end)

    -- the one real converter, skipped when it is not installed
    if vim.fn.executable('pandoc') == 1 then
        it('pandoc', function()
            local folder = vim.fn.tempname()
            vim.fn.mkdir(folder, 'p')
            local source = vim.fs.joinpath(folder, 'source.md')
            local path = vim.fs.joinpath(folder, 'file.docx')
            vim.fn.writefile({ '# Title', '', 'Some **bold** text.' }, source)
            vim.system({ 'pandoc', source, '-o', path }):wait()

            open(path, { file_types = { 'markdown', 'docx' } })
            wait('# Title')
            assert.same({ '# Title', '', 'Some **bold** text.' }, lines())
            assert.same('markdown', vim.bo.filetype)
            assert.same('nowrite', vim.bo.buftype)
        end)
    end
end)
