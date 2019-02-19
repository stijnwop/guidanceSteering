---
-- OnHeadlandState
--
-- Main state for entering the headland.
--
-- Copyright (c) Wopster, 2019

OnHeadlandState = {}

OnHeadlandState.MODES = {
    OFF = 0,
    STOP = 1,
    TURN_LEFT = 2,
    TURN_RIGHT = 3,
}

local OnHeadlandState_mt = Class(OnHeadlandState)

function OnHeadlandState:new(object, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or OnHeadlandState_mt)

    instance.object = object
    instance.mode = OnHeadlandState.MODES.OFF

    return instance
end

function OnHeadlandState:onEntry()
    -- On entry transition
    Logger.info("OnHeadlandState: onEntry")
    -- Todo: look up current mode
    self.mode = OnHeadlandState.MODES.STOP
end

function OnHeadlandState:onExit()
    -- On exit transition
    Logger.info("OnHeadlandState: onExit")
end

function OnHeadlandState:update(dt)
    local mode = self.mode
    if mode ~= HeadlandProcessor.MODES.OFF then
        if mode == OnHeadlandState.MODES.STOP then
            return FSMContext.STATES.STOPPED_STATE
        end
    end

    return FSMContext.STATES.STATE_EMPTY
end
