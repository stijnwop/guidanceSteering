FSMContext = {}

FSMContext.STATES = {
    STATE_EMPTY = 0,
    FOLLOW_LINE_STATE = 1,
    ON_HEADLAND_STATE = 2,
    STOPPED_STATE = 3,
    TURNING_STATE = 4,
    END_TURNING_STATE = 5
}

function FSMContext.createStateMachine(initialState)
    local fsm = FSM:new(initialState)

    return fsm
end

function FSMContext:new(object)
    local initialState = FollowLineState:new(object)
    local fsm = FSMContext.createStateMachine(initialState)

    local states = {
        [FSMContext.STATES.FOLLOW_LINE_STATE] = initialState,
        [FSMContext.STATES.ON_HEADLAND_STATE] = OnHeadlandState:new(object)
    }

    fsm:setStates(states)

    return fsm
end