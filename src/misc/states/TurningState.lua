---
-- TurningState
--
-- Main state for turning on the headland.
--
-- Copyright (c) Wopster, 2019

---@class TurningState
TurningState = {}

local TurningState_mt = Class(TurningState, AbstractState)

---Creates a new turning state.
---@param id number
---@param object table
---@param custom_mt table
---@return TurningState
function TurningState:new(id, object, custom_mt)
    local self = AbstractState:new(id, object, custom_mt or TurningState_mt)

    self.turnLeft = true
    self.turnSegments = {}

    return self
end

---@see AbstractState#onEntry
function TurningState:onEntry()
    TurningState:superClass().onEntry(self)

    -- On entry transition
    Logger.info("TurningState: onEntry")

    self.turnSegments = {}
    -- Get starting point and build
end

---@see AbstractState#onExit
function TurningState:onExit()
    TurningState:superClass().onExit(self)

    -- On exit transition
    Logger.info("TurningState: onExit")
end

---@see AbstractState#update
function TurningState:update(dt)
    TurningState:superClass().update(self, dt)

    return FSM.ANY_STATE
end