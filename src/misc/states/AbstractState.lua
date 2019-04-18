---
-- AbstractState
--
-- Abstract state for the state machine.
--
-- Copyright (c) Wopster, 2019

---@class AbstractState
---@field public id number
AbstractState = {}

local AbstractState_mt = Class(AbstractState)

---Creates a new abstract state.
---@param id number
---@param object table
---@param custom_mt table
---@return AbstractState
function AbstractState:new(id, object, custom_mt)
    local self = setmetatable({}, custom_mt or AbstractState_mt)

    self.id = id
    self.object = object

    return self
end

---Gets the current state id.
---@return number
function AbstractState:getId()
    return self.id
end

---Called on entry state.
function AbstractState:onEntry()
end

---Called on exit state.
function AbstractState:onExit()
end

---Called each update frame.
---@param dt number delta time.
---@return number
function AbstractState:update(dt)
    return FSM.ANY_STATE
end
