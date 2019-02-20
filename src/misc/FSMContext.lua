FSMContext = {}

FSMContext.STATES = {
    FOLLOW_LINE_STATE = 0,
    ON_HEADLAND_STATE = 1,
    STOPPED_STATE = 2,
    TURNING_STATE = 3,
    END_TURNING_STATE = 4
}

function FSMContext.createStateMachine(initialState)
    local fsm = FSM:new(initialState)

    return fsm
end

function FSMContext.createGuidanceStateMachine(object)
    local context = FSMContext.STATES
    local initialState = FollowLineState:new(context.FOLLOW_LINE_STATE, object)
    local fsm = FSMContext.createStateMachine(initialState)

    local states = {
        [context.FOLLOW_LINE_STATE] = initialState,
        [context.ON_HEADLAND_STATE] = OnHeadlandState:new(context.ON_HEADLAND_STATE, object),
        [context.STOPPED_STATE] = StoppedState:new(context.STOPPED_STATE, object)
    }

    fsm:setStates(states)

    return fsm
end