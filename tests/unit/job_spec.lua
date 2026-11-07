---@module 'luassert'

local job = require('renderer.lib.job')
local spy = require('luassert.spy')

---@param request renderer.job.Request
---@return renderer.job.Result
local function wait(request)
    local result = nil ---@type renderer.job.Result?
    local cached = job.run(request, function(out)
        result = out
    end)
    assert.is_nil(cached)
    assert.is_true(vim.wait(2000, function()
        return result ~= nil
    end))
    return assert(result, 'job did not finish')
end

describe('lib.job', function()
    before_each(function()
        job.reset()
        job.limit = 4
        job.retry = 30000
    end)

    it('runs once then returns the cached result', function()
        local request = { cmd = { 'cat' }, stdin = 'x' }
        local result = wait(request)
        assert.same({ ok = true, stdout = 'x', stderr = '' }, result)

        local system = spy.on(vim, 'system')
        local callback = spy.new(function() end)
        assert.same(result, job.run(request, callback))
        assert.same(0, #system.calls)
        assert.same(0, #callback.calls)
        system:revert()
    end)

    it('shares a job that is in flight', function()
        local system = spy.on(vim, 'system')
        local request = { cmd = { 'sh', '-c', 'sleep 0.1; echo y' } }
        local results = {} ---@type renderer.job.Result[]
        for _ = 1, 2 do
            assert.is_nil(job.run(request, function(result)
                results[#results + 1] = result
            end))
        end
        assert.is_true(vim.wait(2000, function()
            return #results == 2
        end))
        system:revert()
        assert.same(1, #system.calls)
        assert.same(results[1], results[2])
        assert.same('y\n', results[1].stdout)
    end)

    it('caches a failure', function()
        local request = { cmd = { 'sh', '-c', 'echo bad >&2; exit 1' } }
        local result = wait(request)
        assert.same({ ok = false, stdout = '', stderr = 'bad\n' }, result)
        assert.same(result, job.run(request, function() end))
    end)

    it('fails on timeout', function()
        local result = wait({ cmd = { 'sleep', '5' }, timeout = 50 })
        assert.is_false(result.ok)
    end)

    it('retries a timeout after a while', function()
        job.retry = 100
        local request = { cmd = { 'sleep', '5' }, timeout = 50 }
        assert.is_false(wait(request).ok)
        assert.is_false(job.run(request, function() end).ok)
        vim.wait(150)
        local system = spy.on(vim, 'system')
        assert.is_nil(job.run(request, function() end))
        system:revert()
        assert.same(1, #system.calls)
    end)

    it('caches other failures for good', function()
        job.retry = 0
        local request = { cmd = { 'sh', '-c', 'exit 124' } }
        assert.is_false(wait(request).ok)
        vim.wait(10)
        assert.not_nil(job.run(request, function() end))
    end)

    it('reset drops jobs in flight', function()
        local called = false
        job.run({ cmd = { 'sleep', '0.05' } }, function()
            called = true
        end)
        job.reset()
        vim.wait(200)
        assert.is_false(called)
        ---@diagnostic disable-next-line: invisible
        assert.same(0, job.running)
    end)

    it('fails when the command is missing', function()
        local result = wait({ cmd = { 'renderer-nvim-missing-command' } })
        assert.is_false(result.ok)
        assert.is_true(#result.stderr > 0)
    end)

    it('limits how many jobs run at once', function()
        job.limit = 1
        local most = 0
        local done = 0
        for i = 1, 3 do
            job.run({ cmd = { 'sleep', '0.05' }, key = tostring(i) }, function()
                done = done + 1
            end)
            ---@diagnostic disable-next-line: invisible
            most = math.max(most, job.running)
        end
        assert.is_true(vim.wait(2000, function()
            ---@diagnostic disable-next-line: invisible
            most = math.max(most, job.running)
            return done == 3
        end, 5))
        assert.same(1, most)
    end)

    it('mixes the key into the cache', function()
        local first = wait({ cmd = { 'sh', '-c', 'echo $$' }, key = 'a' })
        local second = wait({ cmd = { 'sh', '-c', 'echo $$' }, key = 'b' })
        assert.is_true(first.ok and second.ok)
        assert.is_false(vim.deep_equal(first.stdout, second.stdout))
    end)
end)
