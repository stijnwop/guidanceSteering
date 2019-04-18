---
-- StoppedState
--
-- Main state for stopping on the headland.
--
-- Copyright (c) Wopster, 2019

---@class StoppedState
StoppedState = {}

local StoppedState_mt = Class(StoppedState, AbstractState)

---Creates a new stopped state.
---@param id number
---@param object table
---@param custom_mt table
---@return StoppedState
function StoppedState:new(id, object, custom_mt)
    local self = AbstractState:new(id, object, custom_mt or StoppedState_mt)

    return self
end

---@see AbstractState#onEntry
function StoppedState:onEntry()
    StoppedState:superClass().onEntry(self)

    -- On entry transition
    Logger.info("StoppedState: onEntry")

    -- We turn off the cruiseControl
    local spec = self.object:guidanceSteering_getSpecTable("drivable")
    if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
        self.object:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
    end

    -- Todo: stop actual guidance steering
end

---@see AbstractState#onExit
function StoppedState:onExit()
    StoppedState:superClass().onExit(self)

    -- On exit transition
    Logger.info("StoppedState: onExit")
end

---@see AbstractState#update
function StoppedState:update(dt)
    StoppedState:superClass().update(self, dt)

    -- Force zero accelerating because the steering still can be active.
    DriveUtil.accelerateInDirection(self.object, 0, dt)

    return FSM.ANY_STATE
end
