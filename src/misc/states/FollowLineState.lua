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
    instance.lastValidGroundPos = { 0, 0, 0 }

    return instance
end

function FollowLineState:getId()
    return self.id
end

function FollowLineState:onEntry()
    -- On entry transition
    Logger.info("FollowLineState: onEntry")
    self.initialDetectedHeadland = self:detectedHeadland(self.object:getIsOnField(), 0)
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
    if self.initialDetectedHeadland then
        -- We return until we got back on the field again.
    end

    if isOnField then
        local lastSpeed = object:getLastSpeed()

        if self:detectedHeadland(isOnField, lastSpeed) then
            return FSMContext.STATES.ON_HEADLAND_STATE
        end
    end

    return FSM.ANY_STATE
end

function FollowLineState:detectedHeadland(isOnField, lastSpeed)
    local data = self.object:getGuidanceData()
    local x, y, z = unpack(data.driveTarget)

    local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
    local distanceToTurn = 9 * speedMultiplier -- Todo: make configurable
    local lookAheadStepDistance = distanceToTurn + 5 -- m
    local distanceToHeadLand, isDistanceOnField = HeadlandUtil.getDistanceToHeadLand(self, self.object, x, y, z, lookAheadStepDistance)

    --Logger.info(("lookAheadStepDistance: %.1f (owned: %s)"):format(lookAheadStepDistance, tostring(isDistanceOnField)))
    --Logger.info(("End of field distance: %.1f (owned: %s)"):format(distanceToHeadLand, tostring(isDistanceOnField)))

    if distanceToHeadLand <= distanceToTurn + (lookAheadStepDistance * 0.5) and not isDistanceOnField then
        --self.raiseWarningEventAllowed = true
    end

    if distanceToHeadLand <= distanceToTurn then
        -- Todo: not needed anymore
        if self.lastIsNotOnField and self.lastIsNotOnField ~= not isOnField then
            self.lastIsNotOnField = false
        end
        return true
    end

    return false
end
