---@class StateEngine
StateEngine = {}

local StateEngine_mt = Class(StateEngine)

---Creates a new instance of the StateEngine.
---@return StateEngine
function StateEngine:new()
    local self = setmetatable({}, StateEngine_mt)

    self.states = {}

    return self
end

---Adds a state to the engine.
---@param stateId number
---@param state AbstractState
function StateEngine:add(stateId, state)
    if self.states[stateId] ~= nil then
        Logger.error("State " .. stateId .. " already exists!")
        return
    end

    self.states[stateId] = state
end

---Adds an entry action to the given state.
---@param stateId number
---@param action function
function StateEngine:addEntryAction(stateId, action)
    local state = self.states[stateId]
    if state ~= nil then
        state:addEntryAction(action)
    end
end

---Adds an exit action to the given state.
---@param stateId number
---@param action function
function StateEngine:addExitAction(stateId, action)
    local state = self.states[stateId]
    if state ~= nil then
        state:addExitAction(action)
    end
end

---Adds an update action to the given state.
---@param stateId number
---@param action function
function StateEngine:addUpdateAction(stateId, action)
    local state = self.states[stateId]
    if state ~= nil then
        state:addUpdateAction(action)
    end
end

--- Create an instance of a FSM that uses this state engine.
--- The initial state of the FSM will be the initialState specified here.
---@param initialStateId number
---@return FSM
function StateEngine:createFSM(initialStateId)
    if #self.states == 0 then
        Logger.error("Please add states first!")
        return nil
    end

    local fsm = FSM:new(self.states[initialStateId])

    fsm:setStates(self.states)

    return fsm
end
