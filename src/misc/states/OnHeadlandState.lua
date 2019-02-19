---
-- OnHeadlandState
--
-- Main state for entering the headland.
--
-- Copyright (c) Wopster, 2019

OnHeadlandState = {}

local OnHeadlandState_mt = Class(OnHeadlandState)

function OnHeadlandState:new(object, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or OnHeadlandState_mt)

    instance.object = object

    return instance
end

function OnHeadlandState:onEntry()
    -- On entry transition
    Logger.info("OnHeadlandState: onEntry")
    -- Todo: look up current mode
end

function OnHeadlandState:onExit()
    -- On exit transition
    Logger.info("OnHeadlandState: onExit")
end

function OnHeadlandState:update(dt)
    return FSMContext.STATES.STATE_EMPTY
end
