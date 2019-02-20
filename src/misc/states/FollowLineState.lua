---
-- FollowLineState
--
-- Main state for guiding along a line.
--
-- Copyright (c) Wopster, 2019

FollowLineState = {}

local FollowLineState_mt = Class(FollowLineState)

function FollowLineState:new(id, object, custom_mt)
    local instance = {}

    setmetatable(instance, custom_mt or FollowLineState_mt)

    instance.id = id
    instance.object = object
    instance.initialDetectedHeadland = false
    instance.lastIsNotOnField = false
    instance.distanceToEnd = 0
    instance.actDistance = 9 -- Todo: make configurable
    instance.lastValidGroundPos = { 0, 0, 0 }

    return instance
end

function FollowLineState:getId()
    return self.id
end

function FollowLineState:onEntry()
    -- On entry transition
    Logger.info("FollowLineState: onEntry")
    self.initialDetectedHeadland = self:detectedHeadland(0)
    self.lastIsNotOnField = false
    self.distanceToEnd = 0
    self.lastValidGroundPos = { 0, 0, 0 }
end

function FollowLineState:onExit()
    -- On exit transition
    Logger.info("FollowLineState: onExit")
end

function FollowLineState:update(dt)
    local object = self.object

    GlobalPositioningSystem.guideSteering(object, dt)

    local isOnField = object:getIsOnField()

    -- We start the guidance when facing to the field edge
    if isOnField and self.initialDetectedHeadland then
        -- We return until we got back on the field again.
        if not self:detectedHeadland(object:getLastSpeed()) then
            self.initialDetectedHeadland = false
        end

        return FSM.ANY_STATE
    end

    if isOnField then
        if self:detectedHeadland(object:getLastSpeed()) then
            return FSMContext.STATES.ON_HEADLAND_STATE
        end
    end

    return FSM.ANY_STATE
end

---Returns true when it detected headland, false otherwise.
---@param lastSpeed number
function FollowLineState:detectedHeadland(lastSpeed)
    local data = self.object:getGuidanceData()
    local x, y, z = unpack(data.driveTarget)

    local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
    local distanceToAct = self.actDistance * speedMultiplier
    local lookAheadStepDistance = distanceToAct + 5 -- m
    local distanceToHeadLand, isDistanceOnField = HeadlandUtil.getDistanceToHeadLand(self, self.object, x, y, z, lookAheadStepDistance)

    if distanceToHeadLand <= distanceToAct + (lookAheadStepDistance * 0.5) and not isDistanceOnField then
        --self.raiseWarningEventAllowed = true
    end

    return distanceToHeadLand <= distanceToAct
end
