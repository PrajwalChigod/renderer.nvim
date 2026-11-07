---@module 'luassert'

local stub = require('luassert.stub')

---@class renderer.test.Task: vim.SystemObj
---@field private stdout? string
local Task = {}
Task.__index = Task

---@param stdout? string nil for a failure
---@return renderer.test.Task
function Task.new(stdout)
    local self = setmetatable({}, Task)
    self.stdout = stdout
    return self
end

---@return vim.SystemCompleted
function Task:wait()
    if not self.stdout then
        ---@type vim.SystemCompleted
        return { code = 1, signal = 0, stdout = '', stderr = 'failed\n' }
    end
    ---@type vim.SystemCompleted
    return { code = 0, signal = 0, stdout = self.stdout, stderr = '' }
end

---@class renderer.test.system.Opts
---@field hold? boolean keep asynchronous results until release is called

---@class renderer.test.System
local M = {}

---@private
---@type fun()[]
M.held = {}

---@private
---@type renderer.test.system.Opts
M.opts = {}

---@private
---@type luassert.stub[]
M.stubs = {}

---Outputs map stdin to the lines printed, false makes the command fail.
---A call with an exit callback finishes on the main loop, as vim.system does
---@param command string
---@param outputs table<string, string[]|false>
---@param opts? renderer.test.system.Opts
function M.mock(command, outputs, opts)
    M.revert()
    M.held = {}
    M.opts = opts or {}
    M.stubs[#M.stubs + 1] = stub.new(vim.fn, 'executable', function(expr)
        return expr == command and 1 or 0
    end)
    M.stubs[#M.stubs + 1] = stub.new(
        vim,
        'system',
        function(cmd, system_opts, on_exit)
            assert.same({ command }, cmd)
            local output = outputs[system_opts.stdin]
            assert.not_nil(
                output,
                ('missing output: %s'):format(system_opts.stdin)
            )
            local stdout = output and table.concat(output, '\n') .. '\n' or nil
            local task = Task.new(stdout)
            if on_exit then
                local function finish()
                    on_exit(task:wait())
                end
                if M.opts.hold then
                    M.held[#M.held + 1] = finish
                else
                    vim.schedule(finish)
                end
            end
            return task
        end
    )
end

---Undo the stubs of the last mock
function M.revert()
    for _, value in ipairs(M.stubs) do
        value:revert()
    end
    M.stubs = {}
end

---Finish every held call
function M.release()
    local held = M.held
    M.held = {}
    for _, finish in ipairs(held) do
        vim.schedule(finish)
    end
end

return M
