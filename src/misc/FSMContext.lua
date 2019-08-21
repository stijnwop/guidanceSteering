---
-- FSMContext
--
-- Context utility for the Guidance Steering state machines.
--
-- Copyright (c) Wopster, 2019

---@class FSMContext
FSMContext = {}

FSMContext.STATES = {
    FOLLOW_LINE_STATE = 0,
    ON_HEADLAND_STATE = 1,
    STOPPED_STATE = 2,
    TURNING_STATE = 3,
    END_TURNING_STATE = 4
}

---Creates the guidance state machine for the given object.
---@param object table
---@return FSM
function FSMContext.createGuidanceStateMachine(object)
    local engine = StateEngine:new()

    engine:add(FSMContext.STATES.FOLLOW_LINE_STATE, FollowLineState:new(FSMContext.STATES.FOLLOW_LINE_STATE, object))
    engine:addUpdateAction(FSMContext.STATES.FOLLOW_LINE_STATE, function(state)
        local spec = state.object.spec_globalPositioningSystem
        state.actDistance = spec.headlandActDistance
    end)

    engine:add(FSMContext.STATES.ON_HEADLAND_STATE, OnHeadlandState:new(FSMContext.STATES.ON_HEADLAND_STATE, object))
    engine:add(FSMContext.STATES.STOPPED_STATE, StoppedState:new(FSMContext.STATES.STOPPED_STATE, object))
    engine:add(FSMContext.STATES.TURNING_STATE, TurningState:new(FSMContext.STATES.TURNING_STATE, object))

    return engine:createFSM(FSMContext.STATES.FOLLOW_LINE_STATE)
end
