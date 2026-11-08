local log = require('renderer.core.log')

---@class (exact) renderer.job.Request
---@field cmd string[]
---@field stdin? string
---@field timeout? integer milliseconds, defaults to 5000
---@field key? string extra text mixed into the cache key
---@field disk? boolean also keep a successful result on disk, across sessions

---@class (exact) renderer.job.Result
---@field ok boolean
---@field stdout string
---@field stderr string

---@class (exact) renderer.job.Queued
---@field key string
---@field request renderer.job.Request

---The only place that starts a process. Runs it in the background, caches the
---result by input, and never makes a render wait
---@class renderer.Job
local M = {}

---Processes allowed to run at the same time
---@type integer
M.limit = 4

---Milliseconds before a job that timed out may run again. It is not retried
---at once, because the refresh after a failure would start it again forever
---@type integer
M.retry = 30000

---Where results of requests with `disk` are kept, one file per key
---@type string
M.dir = vim.fs.joinpath(vim.fn.stdpath('cache'), 'renderer')

---@private
---@type table<string, renderer.job.Result>
M.cache = {}

---When each cached timeout may run again, from vim.uv.now
---@private
---@type table<string, integer>
M.expires = {}

---Bumped by reset, so jobs started before it are ignored when they finish
---@private
---@type integer
M.generation = 0

---Callbacks waiting on a key that is queued or running
---@private
---@type table<string, fun(result: renderer.job.Result)[]>
M.waiting = {}

---@private
---@type renderer.job.Queued[]
M.queue = {}

---@private
---@type integer
M.running = 0

---Returns the cached result when there is one. Otherwise starts the job, or
---joins the one already started for the same input, and returns nil. The
---callback then runs once, on the main loop, when the job is done
---@param request renderer.job.Request
---@param callback fun(result: renderer.job.Result)
---@return renderer.job.Result?
function M.run(request, callback)
    local key = M.key(request)
    local expires = M.expires[key]
    if expires and vim.uv.now() >= expires then
        M.cache[key] = nil
        M.expires[key] = nil
    end
    local result = M.cache[key] or (request.disk and M.load(key))
    if result then
        M.cache[key] = result
        return result
    end
    local waiting = M.waiting[key]
    if waiting then
        waiting[#waiting + 1] = callback
        return nil
    end
    M.waiting[key] = { callback }
    M.queue[#M.queue + 1] = { key = key, request = request }
    M.next()
    return nil
end

---Forget every cached result, jobs in flight still finish
function M.clear()
    M.cache = {}
    M.expires = {}
end

---Forget everything, including queued and running jobs, whose callbacks are
---then never called. Meant for tests
function M.reset()
    M.clear()
    M.waiting = {}
    M.queue = {}
    M.running = 0
    M.generation = M.generation + 1
end

---@private
---@param request renderer.job.Request
---@return string
function M.key(request)
    -- unit and record separators do not appear in commands or diagrams
    local parts = {
        table.concat(request.cmd, '\31'),
        request.stdin or '',
        request.key or '',
    }
    return vim.fn.sha256(table.concat(parts, '\30'))
end

---@private
function M.next()
    while M.running < M.limit and #M.queue > 0 do
        local item = table.remove(M.queue, 1)
        M.running = M.running + 1
        M.start(item.key, item.request)
    end
end

---@private
---@param key string
---@return renderer.job.Result?
function M.load(key)
    local file = io.open(vim.fs.joinpath(M.dir, key), 'rb')
    if not file then
        return nil
    end
    local stdout = file:read('*a')
    file:close()
    return { ok = true, stdout = stdout, stderr = '' }
end

---Failures are not saved, they are kept in memory only like any other. The
---text is often a private document, so only the user can read it
---@private
---@param key string
---@param result renderer.job.Result
function M.save(key, result)
    if not result.ok then
        return
    end
    local path = vim.fs.joinpath(M.dir, key)
    -- write then rename, so another neovim never reads half a file
    local temp = path .. '.' .. vim.uv.os_getpid()
    local ok, err = pcall(function()
        vim.fn.mkdir(M.dir, 'p', tonumber('700', 8))
        local fd = assert(vim.uv.fs_open(temp, 'w', tonumber('600', 8)))
        local written, write_err = vim.uv.fs_write(fd, result.stdout)
        local closed, close_err = vim.uv.fs_close(fd)
        -- a full disk writes part of the text, which must not be kept
        assert(written == #result.stdout, write_err or 'short write')
        assert(closed, close_err)
        assert(vim.uv.fs_rename(temp, path))
    end)
    if not ok then
        os.remove(temp)
        log.add('error', 'JobSave', err)
    end
end

---@private
---@param key string
---@param request renderer.job.Request
function M.start(key, request)
    local generation = M.generation
    local function finish(result, timeout)
        if generation == M.generation then
            if request.disk then
                M.save(key, result)
            end
            M.finish(key, result, timeout)
        end
    end
    local ok, err = pcall(vim.system, request.cmd, {
        stdin = request.stdin,
        text = true,
        timeout = request.timeout or 5000,
    }, function(out)
        vim.schedule(function()
            -- vim.system kills a job that times out, with exit code 124
            local timeout = out.code == 124 and out.signal ~= 0
            finish({
                ok = out.code == 0,
                stdout = out.stdout or '',
                stderr = out.stderr or '',
            }, timeout)
        end)
    end)
    if not ok then
        -- finish later, callers expect nil from run and the callback after
        vim.schedule(function()
            finish({ ok = false, stdout = '', stderr = tostring(err) }, false)
        end)
    end
end

---@private
---@param key string
---@param result renderer.job.Result
---@param timeout boolean
function M.finish(key, result, timeout)
    M.cache[key] = result
    if timeout then
        M.expires[key] = vim.uv.now() + M.retry
    end
    M.running = M.running - 1
    local callbacks = M.waiting[key] or {}
    M.waiting[key] = nil
    for _, callback in ipairs(callbacks) do
        local ok, err = pcall(callback, result)
        if not ok then
            log.add('error', 'JobCallback', err)
        end
    end
    M.next()
end

return M
