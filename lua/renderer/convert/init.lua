local job = require('renderer.lib.job')
local log = require('renderer.core.log')
local state = require('renderer.state')

---@class (exact) renderer.convert.Info
---@field format string name of the format the buffer was converted from
---@field size number size of the converted text in MB
---@field id integer the read that filled the buffer

---Opens a file that is not text as a read only buffer holding the output of a
---converter, which the rest of the plugin then renders like any other buffer.
---The buffer keeps the path of the file and cannot be written to it
---@class renderer.Convert
local M = {}

---@private
M.group = vim.api.nvim_create_augroup('RendererConvert', {})

---Each read gets a new id, so a slow conversion that finishes after the
---buffer was read again does not overwrite it
---@private
---@type integer
M.id = 0

---called from state on setup
function M.setup()
    vim.api.nvim_clear_autocmds({ group = M.group })
    local takeovers = {} ---@type fun()[]
    for _, format in ipairs(require('renderer.format').all()) do
        local source = format.source
        local config = source and state.convert[source.config]
        local enabled = vim.tbl_contains(state.file_types, format.name)
        local converter = enabled and config and M.converter(config)
        if source and config and converter then
            if source.takeover then
                takeovers[#takeovers + 1] = source.takeover
            end
            vim.api.nvim_create_autocmd('BufReadCmd', {
                group = M.group,
                pattern = source.patterns,
                callback = function(args)
                    M.read(args.buf, format, config, converter)
                end,
            })
            -- nowrite stops :w, but not :w! to another name after :saveas,
            -- and converted text written over a docx destroys it
            vim.api.nvim_create_autocmd(
                { 'BufWritePre', 'FileWritePre', 'FileAppendPre' },
                {
                    group = M.group,
                    pattern = source.patterns,
                    command = M.guard,
                }
            )
        end
    end
    if #takeovers == 0 then
        return
    end
    local function takeover()
        for _, fn in ipairs(takeovers) do
            fn()
        end
    end
    takeover()
    -- plugins that load after this one, such as the zip plugin, add theirs
    vim.api.nvim_create_autocmd('SourcePost', {
        group = M.group,
        pattern = '*/plugin/*',
        callback = takeover,
    })
end

---@param config renderer.convert.format.Config
---@return renderer.converter.Config?
function M.converter(config)
    for _, converter in ipairs(config.converters) do
        local cmd = converter.cmd[1]
        if cmd and vim.fn.executable(cmd) == 1 then
            return converter
        end
    end
    return nil
end

---@param buf integer
---@return renderer.convert.Info?
function M.get(buf)
    return vim.b[buf].renderer_convert
end

---Aborts a write of a converted buffer. Only a Vimscript throw does: an
---error from a Lua callback is reported, and a typed :w! still writes
---@private
---@type string
M.guard = table.concat({
    "if exists('b:renderer_convert')",
    "throw 'renderer.nvim: converted text would destroy '"
        .. " .. expand('<afile>') .. ', write it to a .md file instead'",
    'endif',
}, ' | ')

---@private
---@param buf integer
---@param format renderer.Format
---@param config renderer.convert.format.Config
---@param converter renderer.converter.Config
function M.read(buf, format, config, converter)
    local path = vim.api.nvim_buf_get_name(buf)
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= 'file' then
        local info = M.get(buf)
        if info then
            -- read again after the file was moved or deleted, a conversion
            -- still running must not fill the buffer
            M.id = M.id + 1
            info.id = M.id
            vim.b[buf].renderer_convert = info
            M.set(
                buf,
                { ('Cannot read %s, it was moved or deleted.'):format(path) }
            )
            M.refresh(buf)
        end
        -- a new file has nothing to convert
        return
    end

    -- set first: the buffer must never be writable while it holds converted
    -- text, and the per buffer config reads buftype when it is attached
    vim.bo[buf].buftype = 'nowrite'
    vim.bo[buf].swapfile = false

    M.id = M.id + 1
    ---@type renderer.convert.Info
    local info = { format = format.name, size = 0, id = M.id }
    vim.b[buf].renderer_convert = info

    ---@type renderer.job.Request
    local request = {
        cmd = M.cmd(converter.cmd, path),
        timeout = config.timeout,
        -- converted again when the file changes
        key = ('%d.%d:%d'):format(stat.mtime.sec, stat.mtime.nsec, stat.size),
        disk = true,
    }
    local result = job.run(request, function(out)
        -- setting lines on an unloaded buffer loads it, which reads it again
        local loaded = vim.api.nvim_buf_is_loaded(buf)
        local current = loaded and M.get(buf)
        if current and current.id == info.id then
            M.show(buf, info, config, converter, request, out)
        end
    end)
    if result then
        M.show(buf, info, config, converter, request, result)
    else
        local name = vim.fs.basename(path)
        M.set(
            buf,
            { ('Converting %s with %s…'):format(name, request.cmd[1]) }
        )
    end
end

---@private
---@param cmd string[]
---@param path string
---@return string[]
function M.cmd(cmd, path)
    return vim.tbl_map(function(arg)
        -- a function keeps % in the path from being read as a pattern
        return (
            arg:gsub('{file}', function()
                return path
            end)
        )
    end, cmd)
end

---@private
---@param buf integer
---@param info renderer.convert.Info
---@param config renderer.convert.format.Config
---@param converter renderer.converter.Config
---@param request renderer.job.Request
---@param result renderer.job.Result
function M.show(buf, info, config, converter, request, result)
    local lines ---@type string[]
    if result.ok then
        lines = M.lines(result.stdout)
    else
        log.add('error', 'Convert', request.cmd, result.stderr)
        lines = {
            'Could not convert this file, the command failed:',
            '',
            '    ' .. table.concat(request.cmd, ' '),
            '',
        }
        local stderr = M.lines(result.stderr)
        if #stderr == 1 and stderr[1] == '' then
            local text =
                'It printed no error, it may have run longer than %d ms.'
            stderr = { text:format(config.timeout) }
        end
        vim.list_extend(lines, stderr)
    end
    M.set(buf, lines)

    -- the size check on attach reads this, so it is set before the filetype
    info.size = #result.stdout / (1024 * 1024)
    vim.b[buf].renderer_convert = info

    -- read again: FileType does not attach twice, so the update is forced
    local attached = require('renderer.core.manager').attached(buf)
    if result.ok then
        -- starts the normal pipeline through FileType
        vim.bo[buf].filetype = converter.output
    end
    if attached then
        M.refresh(buf)
    end
end

---@private
---@param buf integer
function M.refresh(buf)
    if require('renderer.core.manager').attached(buf) then
        local env = require('renderer.lib.env')
        require('renderer.core.ui').update(buf, env.buf.win(buf), 'Job', true)
    end
end

---@private
---@param text string
---@return string[]
function M.lines(text)
    text = text:gsub('\r', '')
    if vim.endswith(text, '\n') then
        text = text:sub(1, -2)
    end
    return vim.split(text, '\n', { plain = true })
end

---@private
---@param buf integer
---@param lines string[]
function M.set(buf, lines)
    local bo = vim.bo[buf]
    local levels = bo.undolevels
    bo.modifiable = true
    -- nothing to undo back to, the text is not the user's
    bo.undolevels = -1
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    bo.undolevels = levels
    bo.modifiable = false
    bo.modified = false
end

return M
