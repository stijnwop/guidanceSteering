---
-- FollowLineState
--
-- Main state for guiding along a line.
--
-- Copyright (c) Wopster, 2019

FollowLineState = {}

local FollowLineState_mt = Class(FollowLineState)

function FollowLineState:new(object, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or FollowLineState_mt)

    instance.object = object

    return instance
end

function FollowLineState:onEntry()
    -- On entry transition
    Logger.info("onEntry")
end

function FollowLineState:onExit()
    -- On exit transition
    Logger.info("onExit")
end

function FollowLineState:update(dt)
    local object = self.object
    local spec = object:guidanceSteering_getSpecTable("globalPositioningSystem")

    GlobalPositioningSystem.guideSteering(object, dt)
    spec.headlandProcessor:handle(dt)

    -- Todo: check if on headland then trigger next state.

    Logger.info("Follow line")
end
