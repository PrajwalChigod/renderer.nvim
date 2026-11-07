---The three grammars share one definition and differ only in the separator,
---so each gets its own format with its own root language.
---@param name string
---@return renderer.Format
local function build(name)
    ---@type renderer.Format
    return {
        name = name,
        root = name,
        languages = { [name] = true },
        handlers = { [name] = 'renderer.handler.csv' },
        scroll = true,
        defaults = {
            win_options = {
                wrap = { default = vim.o.wrap, rendered = false },
            },
        },
    }
end

---@type renderer.Format[]
return { build('csv'), build('tsv'), build('psv') }
