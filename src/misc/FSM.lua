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
---@param initialState table
---@param custom_mt table
function FSM:new(initialState, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or FSM_mt)

    -- This includes all the states
    -- Each state has an identifier which can be called by getId()
    instance.states = {}
    instance.initialState = initialState
    instance.state = initialState
    instance.activeState = FSM.STATE_EMPTY

    return instance
end

function FSM:transition(state)
    --local oldState = self.state

    self.state = state
end

function FSM:getCurrentState()
    return self.state
end

function FSM:getInitialState()
    return self.initialState
end

---Resets the initial state
function FSM:reset()
    self.state = self:getInitialState()
end

---Sets the current states
---@param states table
function FSM:setStates(states)
    self.states = states
end

---Updates the active state
---@param dt number
function FSM:update(dt)
    if self.activeState == FSM.STATE_EMPTY then
        return
    end

    self.activeState:update(dt)
end
