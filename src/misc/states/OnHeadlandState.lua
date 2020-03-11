---
-- OnHeadlandState
--
-- Main state for entering the headland.
--
-- Copyright (c) Wopster, 2019

---@class OnHeadlandState
OnHeadlandState = {}

---@type number<string, number> The headland states.
OnHeadlandState.MODES = {
    OFF = 1,
    STOP = 2,
    --TURN_LEFT = 3,
    --TURN_RIGHT = 4,
}

OnHeadlandState.DEFAULT_ACT_DISTANCE = 9 -- m
OnHeadlandState.MAX_ACT_DISTANCE = 100 -- m

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

    local spec = self.object.spec_globalPositioningSystem
    self.mode = spec.headlandMode
end

---@see AbstractState#onExit
function OnHeadlandState:onExit()
    OnHeadlandState:superClass().onExit(self)
end

---@see AbstractState#update
function OnHeadlandState:update(dt)
    OnHeadlandState:superClass().update(self, dt)

    local mode = self.mode
    if mode ~= OnHeadlandState.MODES.OFF then
        if mode == OnHeadlandState.MODES.STOP then
            return FSMContext.STATES.STOPPED_STATE
        end
    else
        -- Enable control when there's no headland mode.
        DriveUtil.guideSteering(self.object, dt)
    end

    return FSM.ANY_STATE
end
