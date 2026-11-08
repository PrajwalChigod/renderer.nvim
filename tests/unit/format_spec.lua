---@module 'luassert'

local manager = require('renderer.core.manager')
local registry = require('renderer.format')
local state = require('renderer.state')
local util = require('tests.util')

describe('format', function()
    local names = vim.deepcopy(registry.names)

    ---@param format renderer.Format
    local function register(format)
        registry.names[#registry.names + 1] = format.name
        registry.loaded[format.name] = format
        vim.treesitter.language.register(format.root, format.name)
    end

    after_each(function()
        for _, name in ipairs(registry.names) do
            if not vim.tbl_contains(names, name) then
                registry.loaded[name] = nil
            end
        end
        registry.names = vim.deepcopy(names)
    end)

    ---@param filetype string
    ---@param opts? renderer.UserConfig
    ---@return renderer.Format?
    local function get(filetype, opts)
        opts = opts or {}
        opts.file_types = { 'markdown', filetype }
        util.setup.text({ 'text' }, opts, filetype)
        return registry.get(0)
    end

    it('markdown', function()
        assert.same('markdown', assert(get('markdown')).name)
    end)

    it('html', function()
        assert.same('html', assert(get('html')).name)
    end)

    it('filetype registered onto markdown parser', function()
        vim.treesitter.language.register('markdown', 'rmd')
        assert.same('markdown', assert(get('rmd')).name)
    end)

    it('filetype with no format', function()
        assert.is_nil(get('text'))
        assert.is_true(manager.attached(vim.api.nvim_get_current_buf()))
    end)

    it('root', function()
        assert.same('markdown', assert(registry.root('markdown')).name)
        assert.same('html', assert(registry.root('html')).name)
        assert.same('docx', assert(registry.root('docx')).name)
        assert.is_nil(registry.root('markdown_inline'))
        assert.is_nil(registry.root(nil))
    end)

    it('handler', function()
        assert.same('renderer.handler.html', registry.handler('html'))
        assert.same('renderer.handler.yaml', registry.handler('yaml'))
        assert.is_nil(registry.handler('lua'))
    end)

    it('handler conflict', function()
        register({
            name = 'conflict',
            root = 'conflict',
            languages = { conflict = true },
            handlers = { html = 'renderer.handler.other' },
        })
        assert.has_error(function()
            registry.handler('html')
        end)
    end)

    it('defaults', function()
        register({
            name = 'custom',
            root = 'custom',
            languages = { custom = true },
            handlers = {},
            defaults = { dash = { width = 10 } },
        })

        assert.same('custom', assert(get('custom')).name)
        assert.same(10, state.get(0).dash.width)

        get('custom', {
            overrides = { filetype = { custom = { dash = { width = 20 } } } },
        })
        assert.same(20, state.get(0).dash.width)

        get('markdown')
        assert.same('full', state.get(0).dash.width)
    end)
end)
