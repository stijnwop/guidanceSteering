---
-- FSM
--
-- Finite-state machine implementation
--
-- Copyright (c) Wopster, 2019

FSM = {}

FSM.STATE_EMPTY = -1

local FSM_mt = Class(FSM)

---Creates a new finite state machine instance
---@param states table
---@param custom_mt table
function FSM:new(states, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or FSM_mt)

    -- This includes all the states
    -- Each state has an identifier which can be called by getId()
    instance.states = states or {}
    instance.activeState = FSM.STATE_EMPTY

    return instance
end

---Sets the current states
---@param states table
function FSM:setStates(states)
    self.states = states
end

---Resets the activate state
function FSM:reset()
    self.activeState = FSM.STATE_EMPTY
end

---Sets the active state
---@param state number
function FSM:setState(state)
    self.activeState = self.states[state]
end

---Gets the current active state
function FSM:getState()
    return self.activeState
end

---Updates the active state
---@param dt number
function FSM:update(dt)
    if self.activeState == FSM.STATE_EMPTY then
        return
    end

    self.activeState:update(dt)
end
