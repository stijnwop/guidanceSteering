---
-- TurningState
--
-- Main state for turning on the headland.
--
-- Copyright (c) Wopster, 2019

TurningState = {}

local TurningState_mt = Class(TurningState)

function TurningState:new(id, object, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or TurningState_mt)

    instance.id = id
    instance.object = object
    instance.turnLeft = true
    instance.turnSegments = {}

    return instance
end

function TurningState:getId()
    return self.id
end

function TurningState:onEntry()
    -- On entry transition
    Logger.info("TurningState: onEntry")

    self.turnSegments = {}
    -- Get starting point and build
end

function TurningState:onExit()
    -- On exit transition
    Logger.info("TurningState: onExit")
end

function TurningState:update(dt)
    return FSM.ANY_STATE
end