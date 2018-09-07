GuidanceSteering = {}

local baseDirectory = g_currentModDirectory

source(Utils.getFilename("src/GuidanceLine.lua", baseDirectory))
source(Utils.getFilename("src/GuidanceUtil.lua", baseDirectory))
source(Utils.getFilename("src/strategies/StraightABStrategy.lua", baseDirectory))

-- Modes:
-- AB lines
-- Curves
-- Circles

GuidanceSteering.DEFAULT_WIDTH = 9.144 -- autotrack default (~30ft)
GuidanceSteering.DIRECTION_LEFT = -1
GuidanceSteering.DIRECTION_RIGHT = 1

function GuidanceSteering.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Steerable, specializations)
end

function GuidanceSteering:preLoad(savegame)
end

function GuidanceSteering:load(savegame)
    Drivable.updateVehiclePhysics = Utils.overwrittenFunction(Drivable.updateVehiclePhysics, GuidanceSteering.updateVehiclePhysics)

    local rootNode = self.steeringCenterNode
    if rootNode == nil then
        print(("Warning: GuidanceSteering can't be loaded for %s, because the setup for Ackermann Steering is missing!"):format(tostring(self.configFileName)))
    end

    local componentIndex = getXMLString(self.xmlFile, "vehicle.guidanceSteering#index")

    if componentIndex ~= nil then
        rootNode = Utils.indexToObject(self.components, componentIndex)
    end

    self.guidanceABNodes = {}
    self.guidanceNode = createTransformGroup("guidance_node")
    link(rootNode, self.guidanceNode)
    setTranslation(self.guidanceNode, 0, 0, 0)

    self.guidanceLine = GuidanceLine:new({ 0, .8, 0 })

    self.lineStrategy = StraightABStrategy:new() -- todo: make dynamic

    self.guidanceIsActive = false
    self.guidanceSteeringIsActive = false
    self.guidanceTerrainAngleIsActive = false
    self.guidanceSteeringOffset = 0
    self.abDistanceCounter = 0
    self.abClickCounter = 0

    self.guidanceData = {
        width = GuidanceSteering.DEFAULT_WIDTH,
        offsetWidth = 0,
        movingDirection = 1,
        snapDirectionMultiplier = 1,
        alphaRad = 0,
        snapDirection = { 0, 0, 0, 0 },
        driveTarget = { 0, 0, 0, 0, 0 }
    }

    -- Headlands detection
    self.lastIsNotOnField = false
    self.lastValidGroundPos = { 0, 0, 0 }
    self.distanceToEnd = 0

    self.debug = true
    self.showGuidanceLines = self.debug

    -- Turning
    self.turningDirection = 1.0
    self.snapDirectionMultiplier = nil
    self.turningActive = false
end

function GuidanceSteering:postLoad(savegame)
end

function GuidanceSteering:delete()
end

function GuidanceSteering:mouseEvent(...)
end

function GuidanceSteering:keyEvent(...)
end

-- Todo: move to overwrite just once
function GuidanceSteering:updateVehiclePhysics(superFunc, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt)
    local offset = self.guidanceSteeringOffset
    if offset ~= nil and offset ~= 0 then
        axisSide = axisSide + offset
    end

    superFunc(self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt)
end

function GuidanceSteering:update(dt)
    if not self.isClient then -- todo: make server sided
        return
    end

    if not self:getIsActive() or not self.isControlled then
        return
    end

    if self:getIsActiveForInput(false) then
        if InputBinding.hasEvent(InputBinding.GS_ACTIVATE) then
            self.guidanceIsActive = not self.guidanceIsActive

            if not self.guidanceIsActive then
                self.lineStrategy:delete()
                self.lastIsNotOnField = false
            end
        end

        if InputBinding.hasEvent(InputBinding.GS_SETPOINT) then
            local reset = self.abClickCounter < 1
            local generateA = self.abClickCounter > 0 and self.abClickCounter < 2
            local generateB = self.abClickCounter > 1 and self.abClickCounter < 3
            local generate = self.abClickCounter > 2 and self.abClickCounter < 4

            if generateB and self.abDistanceCounter < 10 then
                g_currentMission:showBlinkingWarning("Drive 10m in other to set point B. Current traveled distance: " .. tostring(self.abDistanceCounter), 4000)
            else
                if reset then
                    self.abDistanceCounter = 0
                    self.guidanceData.snapDirection = { 0, 0, 0, 0 }
                    self.lineStrategy:delete()
                    print("reset AB Line")
                elseif generateA or generateB then
                    self.lineStrategy:handleABPoints(self.guidanceNode, self.guidanceData)
                end

                self.abClickCounter = self.abClickCounter + 1

                if generate then
                    self.abClickCounter = 0
                    GuidanceSteering.setGuidanceData(self, true)
                end
            end
        end

        if self.guidanceIsActive then
            GuidanceSteering.activatedSettingsEventListeners(self, dt)
        end
    end

    if self.guidanceIsActive then
        local distance = self.lastMovedDistance
        self.abDistanceCounter = self.abDistanceCounter + distance

        self.lineStrategy:update(dt)

        GuidanceSteering.setGuidanceData(self, false)

        local data = self.guidanceData
        local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)
        local x, _, z, driveDirX, driveDirZ = unpack(data.driveTarget)
        local alpha = GuidanceUtil.getAProjectOnLineParameter(z, x, lineZ, lineX, lineDirX, lineDirZ) / data.width

        data.alphaRad = alpha - math.floor(alpha + 0.5)

        local dirX, _, dirZ = localDirectionToWorld(self.guidanceNode, worldDirectionToLocal(self.guidanceNode, lineDirX, 0, lineDirZ))
        local dot = Utils.clamp(driveDirX * dirX + driveDirZ * dirZ, GuidanceSteering.DIRECTION_LEFT, GuidanceSteering.DIRECTION_RIGHT)
        local angle = math.acos(dot) -- dot towards point

        local snapDirectionMultiplier = 1
        if angle > 1.5708 then -- 90 deg
            snapDirectionMultiplier = -snapDirectionMultiplier
        end

        local lastSpeed = self:getLastSpeed(true)
        local movingDirection = 1
        if not self.isReverseDriving and self.movingDirection < 0 and lastSpeed > 2 then
            movingDirection = -movingDirection
        end

        if self.isReverseDriving then
            movingDirection = -movingDirection

            if self.movingDirection > 0 then
                movingDirection = math.abs(movingDirection)
            end
        end

        data.snapDirectionMultiplier = snapDirectionMultiplier
        data.movingDirection = movingDirection

        if self.guidanceSteeringIsActive then
            GuidanceSteering.guideSteering(self)
        else
            self.guidanceSteeringOffset = 0
        end

        local isOnField = self:getIsOnField() -- if vehicle is on field (relative to component node)

        if isOnField then
            local x, y, z = unpack(data.driveTarget)

            -- Offset to search infront of vehicle because distance is relative to the guidanceNode
            local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
            local distanceToTurn = 9 * speedMultiplier -- Todo: make configurable
            local lookAheadStepDistance = 11 * speedMultiplier -- m
            local distance, isDistancenOnField = GuidanceUtil.getDistanceToHeadLand(self, x, y, z, lookAheadStepDistance)
            --            print(("lookAheadStepDistance: %.1f (owned: %s)"):format(lookAheadStepDistance, tostring(isDistancenOnField)))
            --            print(("End of field distance: %.1f (owned: %s)"):format(distance, tostring(isDistancenOnField)))

            if distance <= distanceToTurn then
                if self.guidanceSteeringIsActive then
--                    self.turningActive = true
--                    self.snapDirectionMultiplier = -data.snapDirectionMultiplier

                    -- if stop mode
                    if self.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
                        self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
                    end

                    if self.lastIsNotOnField and self.lastIsNotOnField ~= not isOnField then
                        self.lastIsNotOnField = false
                    end
                end
            end

            if self.showGuidanceLines then
                self.lineStrategy:draw(data)
            end
        end
    end
end

function GuidanceSteering:updateTick(dt)
    if not self.isClient then
        return
    end

    if not self:getIsActive() or not self.isControlled then
        return
    end

    -- Lookup if player wants to steer themselves
    if self.guidanceSteeringIsActive then
        local stopSteering = self.isHired
        if not stopSteering then
            local steeringInputAxis = InputBinding.getDigitalInputAxis(InputBinding.AXIS_MOVE_SIDE_VEHICLE)
            stopSteering = not InputBinding.isAxisZero(steeringInputAxis)

            if not stopSteering then
                steeringInputAxis = InputBinding.getAnalogInputAxis(InputBinding.AXIS_MOVE_SIDE_VEHICLE)
                stopSteering = not InputBinding.isAxisZero(steeringInputAxis)
            end
        end

        if stopSteering then
            self.guidanceSteeringIsActive = false
            print("Auto stop steering: " .. tostring(self.guidanceSteeringIsActive))
        end
    end
end

function GuidanceSteering:draw()
end

function GuidanceSteering.activatedSettingsEventListeners(self, dt)
    if InputBinding.hasEvent(InputBinding.GS_AUTO_WIDTH) then
        self.guidanceData.offsetWidth = 0
        self.guidanceData.width = GuidanceSteering.getAssumedWorkWidth(self)

        print("Calculated width: " .. self.guidanceData.width)
    end

    if InputBinding.hasEvent(InputBinding.GS_ENABLE_STEERING) then
        self.guidanceSteeringIsActive = not self.guidanceSteeringIsActive
        print("Enable steering: " .. tostring(self.guidanceSteeringIsActive))
    end

    if InputBinding.hasEvent(InputBinding.GS_TOGGLE_TERRAIN_ANGLE_SNAP) then
        self.guidanceTerrainAngleIsActive = not self.guidanceTerrainAngleIsActive
        print("Enable terrain angle snapping: " .. tostring(self.guidanceTerrainAngleIsActive))
    end

    if InputBinding.hasEvent(InputBinding.GS_OFFSET_WIDTH_RESET) then
        self.guidanceData.offsetWidth = 0
    end

    if InputBinding.isPressed(InputBinding.GS_OFFSET_WIDTH_LEFT) then
        GuidanceSteering.shiftParallel(self, dt, GuidanceSteering.DIRECTION_LEFT)
    end

    if InputBinding.isPressed(InputBinding.GS_OFFSET_WIDTH_RIGHT) then
        GuidanceSteering.shiftParallel(self, dt, GuidanceSteering.DIRECTION_RIGHT)
    end
end

function GuidanceSteering.getAssumedWorkWidth(self)
    local width = GuidanceUtil.getMaxWorkAreaWidth(self.guidanceNode, self)

    for _, implement in pairs(self.attachedImplements) do
        if implement.object ~= nil then
            width = math.max(width, GuidanceUtil.getMaxWorkAreaWidth(self.guidanceNode, implement.object))
        end
    end

    return width
end

function GuidanceSteering.setGuidanceData(self, updateDirection)
    local data = self.guidanceData
    local direction = {}

    if self.lineStrategy:getRequiresABDirection()
            and self.lineStrategy:getIsABDirectionPossible() then
        direction = self.lineStrategy:getGuidanceDirection(self.guidanceNode)
    else
        direction = { localDirectionToWorld(self.guidanceNode, 0, 0, 1) }
    end

    local translation = { getWorldTranslation(self.guidanceNode) }
    local driveDirectionX, driveDirectionZ = GuidanceUtil.getDriveDirection(direction[1], direction[3])

    -- Includes: drive data
    -- Guidance node xyz translation and xz direction
    data.driveTarget = { translation[1], translation[2], translation[3], driveDirectionX, driveDirectionZ }

    if updateDirection then
        local snapAngle = math.max(self:getDirectionSnapAngle(), math.pi / (g_currentMission.terrainDetailAngleMaxValue + 1))
        local angleRad = Utils.getYRotationFromDirection(direction[1], direction[3])

        if self.guidanceTerrainAngleIsActive then
            angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
        end

        direction[1], direction[3] = Utils.getDirectionFromYRotation(angleRad)

        local offsetFactor = 1.0 -- offset?
        local snapFactor = Utils.getNoNil(data.snapDirectionMultiplier, 1.0)
        local x = translation[1] + offsetFactor * snapFactor * data.offsetWidth * direction[3]
        local z = translation[3] - offsetFactor * snapFactor * data.offsetWidth * direction[1]

        -- Includes: line data
        -- Line direction and translation xz axis
        data.snapDirection = { direction[1], direction[3], x, z }
    end
end

function GuidanceSteering.shiftParallel(self, dt, direction)
    local data = self.guidanceData
    local snapFactor = Utils.getNoNil(data.snapDirectionMultiplier, 1.0)
    local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)

    -- Todo: take self.guidanceData.offsetWidth in account?
    lineX = lineX + (snapFactor * dt / 1000 * lineDirZ) * direction
    lineZ = lineZ + (snapFactor * dt / 1000 * lineDirX) * direction

    -- Todo: store what we offset?
    data.snapDirection = { lineDirX, lineDirZ, lineX, lineZ }
end

function GuidanceSteering.guideSteering(self)
    if not self.steeringEnabled or self.isHired then
        -- Disallow when AI is active
        return
    end

    local data = self.guidanceData
    local offsetFactor = 1.0

    --    if turn offset? then
    --        offsetFactor = lhDirectionPlusMinus
    --    end

    local dirX, dirZ = unpack(data.snapDirection)
    local tx, ty, tz = unpack(data.driveTarget)
    local steeringAngleLimit = 30

    local targetX = tx + data.width * dirZ
    local targetZ = tz - data.width * dirX

    local projTargetX, projTargetZ = Utils.projectOnLine(tx, tz, targetX, targetZ, dirX, dirZ)

    if self.debug then
        DebugUtil.drawDebugCircle(projTargetX, ty + .2, projTargetZ, .5, 10)
    end

    local _, dot = AIVehicleUtil.getDriveDirection(self.guidanceNode, projTargetX, ty, projTargetZ)
    local angle = math.deg(math.asin(dot))

    angle = angle * data.snapDirectionMultiplier * data.movingDirection

    local im = steeringAngleLimit * 0.5 * (data.alphaRad - data.snapDirectionMultiplier * offsetFactor * data.offsetWidth / data.width) * data.width * data.snapDirectionMultiplier
    local axisSide = (angle - Utils.clamp(im, -steeringAngleLimit, steeringAngleLimit)) * (1 / 40)

--    local forceOffset
--    if self.turningActive and self.snapDirectionMultiplier ~= nil then
--        if self.snapDirectionMultiplier == data.snapDirectionMultiplier then
--            self.snapDirectionMultiplier = nil
--            self.turningActive = false
--            self.turningDirection = -self.turningDirection
--        else
--            axisSide = .4 * self.turningDirection
--        end
--    end
--
--    if forceOffset ~= nil then
--        axisSide = forceOffset
--    end
--
--    if self.turningActive then
--        axisSide = Utils.clamp(axisSide, -70, 70)
--    end

    if math.abs(self.lastSpeedReal) > 0.0001 then
        self.guidanceSteeringOffset = axisSide * data.movingDirection
    end

    self.axisSide = self.axisSide + self.guidanceSteeringOffset

    if self.guidanceSteeringIsActive then
        self.axisSideIsAnalog = true
    end
end