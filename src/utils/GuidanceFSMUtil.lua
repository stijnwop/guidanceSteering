GuidanceFSMUtil = {}

GuidanceFSMUtil.FOLLOW_LINE_STATE = 0
GuidanceFSMUtil.ON_HEADLAND_STATE = 1
GuidanceFSMUtil.STOPPED_STATE = 2
GuidanceFSMUtil.TURNING_STATE = 3
GuidanceFSMUtil.END_TURNING_STATE = 4

function GuidanceFSMUtil.createStateMachine()
    local fsm = FSM:new()

    return fsm
end

function GuidanceFSMUtil.createStateMachineForObject(object)
    local fsm = GuidanceFSMUtil.createStateMachine()

    local states = {
        [GuidanceFSMUtil.FOLLOW_LINE_STATE] = FollowLineState:new(object)
    }

    fsm:setStates(states)

    return fsm
end