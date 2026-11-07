local Extmark = require('renderer.lib.extmark')
local replacements = require('renderer.lib.replacements')

---@class renderer.Decorator
---@field private buf integer
---@field private timer uv.uv_timer_t
---@field private running boolean
---@field private marks renderer.Extmark[]
---@field private reveals renderer.Extmark[]
---@field private generated renderer.Extmark[]
---@field private tick integer?
---@field n integer
local Decorator = {}
Decorator.__index = Decorator

---@param buf integer
---@return renderer.Decorator
function Decorator.new(buf)
    local self = setmetatable({}, Decorator)
    self.buf = buf
    self.timer = assert(vim.uv.new_timer())
    self.running = false
    self.marks = {}
    self.reveals = {}
    self.generated = {}
    self.tick = nil
    self.n = 0
    return self
end

---@return boolean
function Decorator:initial()
    return self.tick == nil
end

---@return boolean
function Decorator:changed()
    return self.tick ~= self:get_tick()
end

---@return renderer.Extmark[]
function Decorator:get()
    local result = {} ---@type renderer.Extmark[]
    vim.list_extend(result, self.marks)
    vim.list_extend(result, self.generated)
    return result
end

---Marks revealed by rows they do not cover, see renderer.mark.Reveal
---@return renderer.Extmark[]
function Decorator:revealed()
    return self.reveals
end

---@param marks renderer.Extmark[]
function Decorator:set(marks)
    self.marks = marks
    self.reveals = vim.tbl_filter(function(extmark)
        return extmark:get().reveal ~= nil
    end, marks)
    self.tick = self:get_tick()
    self.n = self.n + 1
end

---@param ns integer
function Decorator:clear(ns)
    for _, extmark in ipairs(self:get()) do
        extmark:hide(ns, self.buf)
    end
    self.generated = {}
end

---@param ns integer
---@param hide fun(extmark: renderer.Extmark): boolean
function Decorator:display(ns, hide)
    local visible = {} ---@type renderer.Mark[]
    for _, extmark in ipairs(self.marks) do
        if hide(extmark) then
            extmark:hide(ns, self.buf)
        else
            extmark:show(ns, self.buf)
            visible[#visible + 1] = extmark:get()
        end
    end

    local line_count = vim.api.nvim_buf_line_count(self.buf)
    local generated = replacements.resolve(visible, line_count)
    local current = {} ---@type renderer.Mark[]
    for _, extmark in ipairs(self.generated) do
        current[#current + 1] = extmark:get()
    end
    if vim.deep_equal(current, generated) then
        return
    end
    for _, extmark in ipairs(self.generated) do
        extmark:hide(ns, self.buf)
    end
    self.generated = {}
    for _, mark in ipairs(generated) do
        local extmark = Extmark.new(mark)
        extmark:show(ns, self.buf)
        self.generated[#self.generated + 1] = extmark
    end
end

---@param debounce boolean
---@param ms integer
---@param callback fun()
function Decorator:schedule(debounce, ms, callback)
    if debounce and ms > 0 then
        self.timer:start(ms, 0, function()
            self.running = false
        end)
        if not self.running then
            self.running = true
            vim.schedule(callback)
        end
    else
        vim.schedule(callback)
    end
end

---@private
---@return integer
function Decorator:get_tick()
    return vim.api.nvim_buf_get_changedtick(self.buf)
end

return Decorator
