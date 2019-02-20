---
-- FSM
--
-- Finite-state machine implementation
--
-- Copyright (c) Wopster, 2019

FSM = {}

FSM.ANY_STATE = -1

local FSM_mt = Class(FSM)

---Creates a new finite state machine instance
---@param initialState table
---@param states table
---@param custom_mt table
function FSM:new(initialState, states, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or FSM_mt)

    instance.initialState = initialState
    instance.state = initialState
    -- This includes all the states
    -- Each state has an identifier which can be called by getId()
    instance.states = states or {}

    return instance
end

---_callListeners
---@param listeners table
---@param functionName string
local function _callListeners(listeners, functionName)
    for _, listener in ipairs(listeners) do
        listener[functionName]()
    end
end

---Calls the onExit function from the current state
---@param state table
local function _callOnExit(state)
    state:onExit()

    if state.listeners ~= nil then
        _callListeners(state.listeners, "onExit")
    end
end

---Calls the onEntry function for the next state
---@param state table
local function _callOnEntry(state)
    state:onEntry()

    if state.listeners ~= nil then
        _callListeners(state.listeners, "onEntry")
    end
end

---Transitions to new state
---@param toState table the state we transition to.
function FSM:transition(toState)
    local fromState = self.state

    -- We exit the previous state
    _callOnExit(fromState)

    self:setCurrentState(toState)

    -- We enter the new state
    _callOnEntry(toState)
end

---Sets the current state
---@param state table
function FSM:setCurrentState(state)
    self.state = state
end

---Returns the current active state
function FSM:getCurrentState()
    return self.state
end

---Returns the initial state of the state machine
function FSM:getInitialState()
    return self.initialState
end

---Resets the state machine to the initial state
function FSM:reset()
    local state = self:getInitialState()
    self:transition(state)
end

---Sets the possible states
---@param states table
function FSM:setStates(states)
    self.states = states
end

---Updates the current state
---@param dt number
function FSM:update(dt)
    local stateContext = self.state:update(dt)

    if stateContext ~= FSM.ANY_STATE then
        local state = self.states[stateContext]
        self:transition(state)
    end
end
