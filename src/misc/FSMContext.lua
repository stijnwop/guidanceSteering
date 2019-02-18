FSMContext = {}

FSMContext.MODES = {
    FOLLOW_LINE_STATE = 0,
    ON_HEADLAND_STATE = 1,
    STOPPED_STATE = 2,
    TURNING_STATE = 3,
    END_TURNING_STATE = 4
}

function FSMContext.createStateMachine()
    local fsm = FSM:new()

    return fsm
end

function FSMContext:new(object)
    local fsm = FSMContext.createStateMachine()
    local initialState = FollowLineState:new(object)

    local states = {
        [FSMContext.MODES.FOLLOW_LINE_STATE] = initialState
    }

    fsm:setStates(states)

    return fsm
end