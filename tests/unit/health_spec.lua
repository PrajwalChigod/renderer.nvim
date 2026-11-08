---@module 'luassert'

local health = require('renderer.health')

describe('health', function()
    ---@param file_types string[]
    ---@param required string[]
    ---@param optional string[]
    local function validate(file_types, required, optional)
        require('renderer').setup({ file_types = file_types })
        local actual_required, actual_optional = health.languages()
        assert.same(required, actual_required)
        assert.same(optional, actual_optional)
    end

    it('markdown', function()
        validate(
            { 'markdown' },
            { 'markdown', 'markdown_inline' },
            { 'html', 'latex', 'yaml' }
        )
    end)

    it('html', function()
        validate({ 'html' }, { 'html' }, {})
    end)

    it('required wins regardless of order', function()
        local required = { 'html', 'markdown', 'markdown_inline' }
        local optional = { 'latex', 'yaml' }
        validate({ 'markdown', 'html' }, required, optional)
        validate({ 'html', 'markdown' }, required, optional)
    end)

    it('docx', function()
        validate(
            { 'docx' },
            { 'markdown', 'markdown_inline' },
            { 'html', 'latex' }
        )
    end)

    it('no format', function()
        validate({ 'text' }, {}, {})
    end)
end)
