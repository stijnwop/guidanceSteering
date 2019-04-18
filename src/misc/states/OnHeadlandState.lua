---
-- OnHeadlandState
--
-- Main state for entering the headland.
--
-- Copyright (c) Wopster, 2019

---@class OnHeadlandState
OnHeadlandState = {}

---@type number[] The headland states.
OnHeadlandState.MODES = {
    OFF = 0,
    STOP = 1,
    TURN_LEFT = 2,
    TURN_RIGHT = 3,
}

local OnHeadlandState_mt = Class(OnHeadlandState, AbstractState)

---Creates a new on headland state.
---@param id table
---@param object table
---@param custom_mt table
---@return OnHeadlandState
function OnHeadlandState:new(id, object, custom_mt)
    local self = AbstractState:new(id, object, custom_mt or OnHeadlandState_mt)

    self.mode = OnHeadlandState.MODES.OFF

    return self
end

---@see AbstractState#onEntry
function OnHeadlandState:onEntry()
    OnHeadlandState:superClass().onEntry(self)

    -- On entry transition
    Logger.info("OnHeadlandState: onEntry")

    -- Todo: look up current mode
    self.mode = OnHeadlandState.MODES.STOP
end

---@see AbstractState#onExit
function OnHeadlandState:onExit()
    OnHeadlandState:superClass().onExit(self)

    -- On exit transition
    Logger.info("OnHeadlandState: onExit")
end

---@see AbstractState#update
function OnHeadlandState:update(dt)
    OnHeadlandState:superClass().update(self, dt)

    local mode = self.mode
    if mode ~= HeadlandProcessor.MODES.OFF then
        if mode == OnHeadlandState.MODES.STOP then
            return FSMContext.STATES.STOPPED_STATE
        end
    end

    return FSM.ANY_STATE
end
