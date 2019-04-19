---
-- FollowLineState
--
-- Main state for guiding along a line.
--
-- Copyright (c) Wopster, 2019

---@class FollowLineState
FollowLineState = {}

local FollowLineState_mt = Class(FollowLineState, AbstractState)

---Creates a new follow line state.
---@param id number
---@param object table
---@param custom_mt table
---@return FollowLineState
function FollowLineState:new(id, object, custom_mt)
    local self = AbstractState:new(id, object, custom_mt or FollowLineState_mt)

    self.initialDetectedHeadland = false
    self.lastIsNotOnField = false
    self.distanceToEnd = 0
    self.actDistance = 9 -- Todo: make configurable
    self.lastValidGroundPos = { 0, 0, 0 }

    return self
end

---@see AbstractState#onEntry
function FollowLineState:onEntry()
    FollowLineState:superClass().onEntry(self)

    -- On entry transition
    Logger.info("FollowLineState: onEntry")

    self.initialDetectedHeadland = self:detectedHeadland(0)
    self.lastIsNotOnField = false
    self.distanceToEnd = 0
    self.lastValidGroundPos = { 0, 0, 0 }

    -- Reset some vehicle spec data for sounds.
    local spec = self.object:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.playHeadLandWarning = false
end

---@see AbstractState#onExit
function FollowLineState:onExit()
    FollowLineState:superClass().onExit(self)

    -- On exit transition
    Logger.info("FollowLineState: onExit")
end

---@see AbstractState#update
function FollowLineState:update(dt)
    FollowLineState:superClass().update(self, dt)

    local object = self.object
    local isOnField = object:getIsOnField()

    DriveUtil.guideSteering(object, dt)

    if isOnField then
        local detectedHeadland = self:detectedHeadland(object:getLastSpeed())
        -- We start the guidance when facing to the field edge
        if self.initialDetectedHeadland then
            if not detectedHeadland then
                self.initialDetectedHeadland = false
            end
            -- We return until we got back on the field again.
            return FSM.ANY_STATE
        end

        if detectedHeadland then
            return FSMContext.STATES.ON_HEADLAND_STATE
        end
    end

    return FSM.ANY_STATE
end

---Returns true when it detected headland, false otherwise.
---@param lastSpeed number
---@return boolean true when distance to headland equals or is smaller than the distance to act, false otherwise.
function FollowLineState:detectedHeadland(lastSpeed)
    local data = self.object:getGuidanceData()
    local x, y, z = unpack(data.driveTarget)

    local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
    local distanceToAct = self.actDistance * speedMultiplier
    local lookAheadStepDistance = distanceToAct + 5 -- m
    local distanceToHeadLand, isDistanceOnField = HeadlandUtil.getDistanceToHeadLand(self, self.object, x, y, z, lookAheadStepDistance)

    if distanceToHeadLand <= distanceToAct + (lookAheadStepDistance * 0.5) and not isDistanceOnField then
        local spec = self.object:guidanceSteering_getSpecTable("globalPositioningSystem")
        spec.playHeadLandWarning = true
    end

    return distanceToHeadLand <= distanceToAct
end
