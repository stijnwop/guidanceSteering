---
-- StoppedState
--
-- Main state for stopping on the headland.
--
-- Copyright (c) Wopster, 2019

StoppedState = {}

local StoppedState_mt = Class(StoppedState)

function StoppedState:new(object, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or StoppedState_mt)

    instance.object = object

    return instance
end

function StoppedState:onEntry()
    -- On entry transition
    Logger.info("StoppedState: onEntry")

    -- We turn off the cruiseControl
    local spec = self.object:guidanceSteering_getSpecTable("drivable")
    if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
        self.object:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
    end
end

function StoppedState:onExit()
    -- On exit transition
    Logger.info("StoppedState: onExit")
end

function StoppedState:update(dt)
    -- Force zero accelerating because the steering still can be active.
    DriveUtil.accelerateInDirection(self.object, 0, dt)
    return FSMContext.STATES.STATE_EMPTY
end
