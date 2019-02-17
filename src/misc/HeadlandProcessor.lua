HeadlandProcessor = {}

local HeadlandProcessor_mt = Class(HeadlandProcessor)

HeadlandProcessor.MODES = {
    OFF = 0,
    STOP = 1,
    TURN_LEFT = 2,
    TURN_RIGHT = 3,
}

function HeadlandProcessor:new(object, customMt)
    local instance = {}

    instance.mode = HeadlandProcessor.MODES.STOP

    -- Headland calculations
    instance.lastIsNotOnField = false
    instance.distanceToEnd = 0
    instance.lastValidGroundPos = { 0, 0, 0 }

    instance.object = object
    instance.raiseWarningEventAllowed = false
    instance.warningSoundPlaying = false

    setmetatable(instance, customMt or HeadlandProcessor_mt)

    return instance
end

function HeadlandProcessor:getMode()
    return self.mode
end

function HeadlandProcessor:setMode(mode)
    self.mode = mode
end

function HeadlandProcessor:handle(dt)
    local mode = self:getMode()

    if mode == HeadlandProcessor.MODES.OFF then
        return
    end

    local object = self.object
    local isOnField = object:getIsOnField()

    if self.raiseWarningEventAllowed then
        if not self.warningSoundPlaying then
            SpecializationUtil.raiseEvent(self.object, "onHeadlandStart")
        end
        self.raiseWarningEventAllowed = false
        self.warningSoundPlaying = true
    else
        if self.warningSoundPlaying then
            SpecializationUtil.raiseEvent(self.object, "onHeadlandEnd")
            self.warningSoundPlaying = false
        end
    end

    if isOnField then
        local lastSpeed = object:getLastSpeed()

        if mode == HeadlandProcessor.MODES.STOP then
            self:handleAutoStop(isOnField, lastSpeed)
        end
    end
end

function HeadlandProcessor:handleAutoStop(isOnField, lastSpeed)
    local data = self.object:getGuidanceData()
    local x, y, z = unpack(data.driveTarget)

    local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
    local distanceToTurn = 9 * speedMultiplier -- Todo: make configurable
    local lookAheadStepDistance = distanceToTurn + 5 -- m
    local distanceToHeadLand, isDistanceOnField = HeadlandUtil.getDistanceToHeadLand(self, self.object, x, y, z, lookAheadStepDistance)

    --Logger.info(("lookAheadStepDistance: %.1f (owned: %s)"):format(lookAheadStepDistance, tostring(isDistanceOnField)))
    --Logger.info(("End of field distance: %.1f (owned: %s)"):format(distanceToHeadLand, tostring(isDistanceOnField)))

    if distanceToHeadLand <= distanceToTurn + (lookAheadStepDistance * 0.5) and not isDistanceOnField then
        self.raiseWarningEventAllowed = true
    end

    if distanceToHeadLand <= distanceToTurn then
        local drivable_spec = self.object:guidanceSteering_getSpecTable("drivable")
        -- if stop mode
        if drivable_spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
            self.object:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
        end

        if self.lastIsNotOnField and self.lastIsNotOnField ~= not isOnField then
            self.lastIsNotOnField = false
        end
    end
end

function HeadlandProcessor:handleTurn()
end
