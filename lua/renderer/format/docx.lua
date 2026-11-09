---A docx file is converted to markdown in a read only buffer, which is then
---rendered by the markdown format. The root is the name of the format, never
---the language of a buffer, so that `file_types` and health can find it
---@type renderer.Format
return {
    name = 'docx',
    root = 'docx',
    languages = {
        markdown = true,
        markdown_inline = true,
        html = false,
        latex = false,
    },
    handlers = {},
    source = {
        patterns = { '*.docx' },
        config = 'docx',
        takeover = function()
            -- the zip plugin opens docx files as archives
            pcall(vim.api.nvim_clear_autocmds, {
                group = 'zip',
                event = 'BufReadCmd',
                pattern = '*.docx',
            })
        end,
    },
}
