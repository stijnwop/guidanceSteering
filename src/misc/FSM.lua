---
-- FSM
--
-- Finite-state machine implementation
--
-- Copyright (c) Wopster, 2019

---@class FSM
---@field public state AbstractState
---@field public states AbstractState[]
FSM = {}

---@type number The any state.
FSM.ANY_STATE = -1

local FSM_mt = Class(FSM)

---Creates a new finite state machine instance
---@param initialState AbstractState
---@param states AbstractState[]
---@param custom_mt table
---@return FSM
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

---Calls all action functions.
---@param actions table
---@param state AbstractState
local function _callActions(actions, state)
    for _, action in ipairs(actions) do
        action(state)
    end
end

---Calls the onExit function from the current state
---@param state AbstractState
local function _callOnExit(state)
    state:onExit()

    if state.exitActions ~= nil then
        _callActions(state.exitActions, state)
    end
end

---Calls the onEntry function for the next state
---@param state AbstractState
local function _callOnEntry(state)
    state:onEntry()

    if state.entryActions ~= nil then
        _callActions(state.entryActions, state)
    end
end

---Transitions to new state
---@param toState AbstractState the state we transition to.
function FSM:transition(toState)
    local fromState = self.state

    -- We exit the previous state
    _callOnExit(fromState)

    self:setCurrentState(toState)

    -- We enter the new state
    _callOnEntry(toState)
end

---Current state needs update.
function FSM:requestStateUpdate()
    local state = self:getCurrentState()

    -- We call the state update actions.
    if state.updateActions ~= nil then
        _callActions(state.updateActions, state)
    end
end

---Sets the current state
---@param state AbstractState
function FSM:setCurrentState(state)
    self.state = state
end

---Returns the current active state
function FSM:getCurrentState()
    return self.state
end

---Returns true when the state equals, false otherwise
function FSM:isInState(state)
    return state.id == self.state.id
end

---Returns the initial state of the state machine
---@return AbstractState
function FSM:getInitialState()
    return self.initialState
end

---Resets the state machine to the initial state
function FSM:reset()
    local state = self:getInitialState()
    self:transition(state)
end

---Sets the possible states
---@param states AbstractState[]
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
