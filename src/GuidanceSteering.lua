GuidanceSteering = {}

local baseDirectory = g_currentModDirectory

source(Utils.getFilename("src/GuidanceLine.lua", baseDirectory))
source(Utils.getFilename("src/GuidanceUtil.lua", baseDirectory))
--source(Utils.getFilename("src/strategies/StraightABStrategy.lua", baseDirectory))

-- Modes:
-- AB lines
-- Curves
-- Circles

GuidanceSteering.DEFAULT_WIDTH = 6

function GuidanceSteering.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Steerable, specializations)
end

function GuidanceSteering:preLoad(savegame)
end

function GuidanceSteering:load(savegame)
    Drivable.updateVehiclePhysics = Utils.overwrittenFunction(Drivable.updateVehiclePhysics, GuidanceSteering.updateVehiclePhysics)

    local rootNode = self.steeringCenterNode
    if rootNode == nil then
        print("Warning: GuidanceSteering can't be loaded for " .. tostring(self.configFileName) .. ", because the setup for Ackermann Steering is missing!")
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

    --    self.lineStrategy = StraightABStrategy:new() -- todo: make dynamic

    self.guidanceIsActive = false
    self.guidanceSteeringIsActive = false
    self.guidanceTerrainAngleIsActive = false
    self.guidanceSteeringOffset = 0
    self.abDistanceCounter = 0
    self.abClickCounter = 0

    self.guidanceInfo = {
        width = GuidanceSteering.DEFAULT_WIDTH,
        offsetWidth = 0,
        movingDirection = 1,
        snapDirectionFactor = 1,
        alphaRad = 0,
        snapDirection = { 0, 0, 0, 0 },
        driveTarget = { 0, 0, 0, 0, 0 }
    }

    -- Headlands detection
    self.lastIsNotOnField = false
    self.lastValidGroundPos = { 0, 0, 0 }
    self.distanceToEnd = 0
end

function GuidanceSteering:postLoad(savegame)
end

function GuidanceSteering:delete()
end

function GuidanceSteering:mouseEvent(...)
end

function GuidanceSteering:keyEvent(...)
end


function GuidanceSteering:updateVehiclePhysics(superFunc, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt)
    local offset = self.guidanceSteeringOffset

    if offset ~= 0 then
        axisSide = axisSide + offset
    end

    superFunc(self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt)
end

function GuidanceSteering:update(dt)
    if not self.isClient then
        return
    end

    if self:getIsActive()
            and self:getIsActiveForInput(false) then
        if InputBinding.hasEvent(InputBinding.GS_ACTIVATE) then
            self.guidanceIsActive = not self.guidanceIsActive

            if not self.guidanceIsActive then
                -- Todo: do full reset
                --                self.lineStrategy:delete()
                GuidanceSteering.deleteABPoints(self)
                self.lastIsNotOnField = false
            end
        end

        if InputBinding.hasEvent(InputBinding.GS_SETPOINT) then
            local reset = self.abClickCounter < 1
            local generateA = self.abClickCounter > 0 and self.abClickCounter < 2
            local generateB = self.abClickCounter > 1 and self.abClickCounter < 3
            local generate = self.abClickCounter > 2 and self.abClickCounter < 4

            if generateB and self.abDistanceCounter < 25 then
                g_currentMission:showBlinkingWarning("Drive 25m in other to set point B. Current traveled distance: " .. tostring(self.abDistanceCounter), 4000)
            else
                if reset then
                    self.abDistanceCounter = 0
                    GuidanceSteering.deleteABPoints(self)
                    print("reset AB Line")
                elseif generateA or generateB then
                    GuidanceSteering.createABPoint(self, generateB)
                    --                    GuidanceSteering.setSnapDirection(self, true)
                end

                self.abClickCounter = self.abClickCounter + 1

                if generate then
                    self.abClickCounter = 0
                    GuidanceSteering.setSnapDirection(self, true)
                end
            end
        end

        if self.guidanceIsActive then
            GuidanceSteering.activatedSettingsEventListeners(self, dt)
        end
    end

    if self.guidanceIsActive then
        --        if self.abDistanceCounter > 0.01 and self.guidanceABNodes.a == nil then
        --            GuidanceSteering.createABPoint(self, false)
        --        end
        --
        --
        --        if self.abDistanceCounter > 25 and self.guidanceABNodes.b == nil then
        --            g_currentMission:showBlinkingWarning("Set AB point B")
        --            GuidanceSteering.createABPoint(self, true)
        --        end
        --

        local distance = self.lastMovedDistance
        self.abDistanceCounter = self.abDistanceCounter + distance

        for key, node in pairs(self.guidanceABNodes) do
            DebugUtil.drawDebugNode(node, key)
        end

        GuidanceSteering.setSnapDirection(self, false)

        local info = self.guidanceInfo
        local dx, dz, xSq, zSq = unpack(info.snapDirection)
        local tx, _, tz, dlx, dlz = unpack(info.driveTarget)
        local dot = Utils.clamp(dlx * dx + dlz * dz, -1, 1)
        local angle = math.acos(dot) -- dot towards point

        local alpha = GuidanceUtil.getAProjectOnLineParameter(tz, tx, zSq, xSq, dx, dz) / info.width

        info.alphaRad = alpha - math.floor(alpha + 0.5)

        local snapDirectionFactor = 1
        if angle > 1.5708 then -- 90 deg
            snapDirectionFactor = -snapDirectionFactor
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

        info.snapDirectionFactor = snapDirectionFactor
        info.movingDirection = movingDirection

        if self.guidanceSteeringIsActive then
            --        local wx, wy, wz = getWorldTranslation(self.guidanceNode)
            --        local pX, pZ = Utils.projectOnLine(wx, wz, info.driveTarget[1], info.driveTarget[2], info.snapDirection[1], info.snapDirection[2])
            --        local maxTurningRadius = 0
            --
            --        local tX = pX + info.snapDirection[1] * maxTurningRadius
            --        local tZ = pZ + info.snapDirection[2] * maxTurningRadius
            --
            --        local pX, pY, pZ = worldToLocal(self.guidanceNode, tX, wy, tZ)
            --        local acceleration = 1.0
            --        AIVehicleUtil.driveToPoint(self, dt, acceleration, true, info.movingDirection > 0, pX, pZ, 25, false)

            local arcAngle = math.deg(math.asin(dlx * dz - dlz * dx))

            GuidanceSteering.guideSteering(self, arcAngle, lastSpeed)
        else
            self.guidanceSteeringOffset = 0
        end

        local isOnField = self:getIsOnField() -- if vehicle is on field (relative to component node)

        if isOnField then
            DebugUtil.drawDebugNode(self.guidanceNode, "GuidanceNode")

            local lx, lz = unpack(info.snapDirection)
            local x, y, z = unpack(info.driveTarget)

            -- Offset to search infront of vehicle because distance is relative to the guidanceNode
            local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
            local distanceToTurn = 9 * speedMultiplier -- Todo: make configurable
            local lookAheadStepDistance = 11 * speedMultiplier -- m
            local distance, isDistancenOnField = GuidanceUtil.getDistanceToHeadLand(self, x, y, z, lookAheadStepDistance)
            print(("lookAheadStepDistance: %.1f (owned: %s)"):format(lookAheadStepDistance, tostring(isDistancenOnField)))
--            print(("End of field distance: %.1f (owned: %s)"):format(distance, tostring(isDistancenOnField)))

            if distance <= distanceToTurn then
                if self.guidanceSteeringIsActive then
                    -- if stop mode
                    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
                end
            end

            self.guidanceLine:drawABLine(x, z, lx, lz, info.width, info.movingDirection, info.alphaRad, info.snapDirectionFactor)
        end
    end
end

function GuidanceSteering:updateTick(dt)
    if not self.isClient then
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
        self.guidanceInfo.offsetWidth = 0
        self.guidanceInfo.width = GuidanceSteering.getAssumedWorkWidth(self)

        print("Calculated width: " .. self.guidanceInfo.width)
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
        self.guidanceInfo.offsetWidth = 0
    end

    if InputBinding.isPressed(InputBinding.GS_OFFSET_WIDTH_LEFT) then
        --        self.guidanceInfo.offsetWidth = self.guidanceInfo.offsetWidth - 0.0002 * dt
        GuidanceSteering.shiftParallel(self, dt, -1)
    end

    if InputBinding.isPressed(InputBinding.GS_OFFSET_WIDTH_RIGHT) then
        --        self.guidanceInfo.offsetWidth = self.guidanceInfo.offsetWidth + 0.0002 * dt
        GuidanceSteering.shiftParallel(self, dt, 1)
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

function GuidanceSteering.createABPoint(self, isB)
    local key = tostring(isB)

    if self.guidanceABNodes[key] ~= nil then
        return
    end

    local p = createTransformGroup("AB_point_" .. key)
    local x, _, z = unpack(self.guidanceInfo.driveTarget)
    local dx, dy, dz = localDirectionToWorld(self.guidanceNode, 0, 0, 1)
    local upX, upY, upZ = worldDirectionToLocal(self.guidanceNode, 0, 1, 0)
    local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

    link(getRootNode(), p)

    setTranslation(p, x, y, z)
    setDirection(p, dx, dy, dz, upX, upY, upZ)

    table.insert(self.guidanceABNodes, p)
    --    self.guidanceABNodes[key] = p
end

function GuidanceSteering.deleteABPoints(self)
    for key, _ in pairs(self.guidanceABNodes) do
        delete(self.guidanceABNodes[key])
    end

    self.guidanceABNodes = {}
end

function GuidanceSteering.setSnapDirection(self, forceUpdateSnapDirection)
    local refNode = self.guidanceNode

    local numOfABNode = #self.guidanceABNodes
    local dx, dy, dz

    if numOfABNode > 0 then
        local ldx, ldy, ldz -- Todo: cleanup this mess
        if numOfABNode < 2 then
            ldx, ldy, ldz = localDirectionToLocal(self.guidanceNode, self.guidanceABNodes[1], 0, 0, 1)
        else
            ldx, ldy, ldz = localDirectionToLocal(self.guidanceABNodes[1], self.guidanceABNodes[2], 0, 0, 1)
        end

        dx, dy, dz = localDirectionToWorld(refNode, ldx, ldy, ldz)
    else
        dx, dy, dz = localDirectionToWorld(self.guidanceNode, 0, 0, 1)
    end

    local x, y, z = getWorldTranslation(refNode)
    local directionX, directionZ = GuidanceUtil.getDriveDirection(dx, dz)

    self.guidanceInfo.driveTarget = { x, y, z, directionX, directionZ }

    if forceUpdateSnapDirection then
        local snapAngle = math.max(self:getDirectionSnapAngle(), math.pi / (g_currentMission.terrainDetailAngleMaxValue + 1))
        local angleRad = Utils.getYRotationFromDirection(dx, dz)

        -- Todo: make snapping optional
        if self.guidanceTerrainAngleIsActive then
            angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
        end
        print(angleRad)

        dx, dz = Utils.getDirectionFromYRotation(angleRad)

        local offsetFactor = 1.0 -- offset?
        local snapFactor = Utils.getNoNil(self.guidanceInfo.snapDirectionFactor, 1.0)
        local xSq = x + offsetFactor * snapFactor * self.guidanceInfo.offsetWidth * dz
        local zSq = z - offsetFactor * snapFactor * self.guidanceInfo.offsetWidth * dx

        self.guidanceInfo.snapDirection = { dx, dz, xSq, zSq }
    end
end

function GuidanceSteering.shiftParallel(self, dt, direction)
    local info = self.guidanceInfo
    local snapFactor = Utils.getNoNil(info.snapDirectionFactor, 1.0)
    local dx, dz, xSq, zSq = unpack(info.snapDirection)

    -- Todo: take self.guidanceInfo.offsetWidth in account?
    xSq = xSq + (snapFactor * dt / 1000 * dz) * direction
    zSq = zSq + (snapFactor * dt / 1000 * dx) * direction

    -- Todo: store what we offset?
    self.guidanceInfo.snapDirection = { dx, dz, xSq, zSq }
end

function GuidanceSteering.guideSteering(self, arcAngle, lastSpeed)
    --if lastSpeed < 0.1 then
    local info = self.guidanceInfo
    local angleLimit = 90 -- todo: >.<
    local refangle = arcAngle * info.snapDirectionFactor * self.movingDirection

    local offsetFactor = 1.0
    --    if self.GPSturnOffset then
    --        offsetFactor = lhDirectionPlusMinus
    --    end

    local _iA = 15
    local _iB = .025
    local angleDecre = _iA * (info.alphaRad - info.snapDirectionFactor * offsetFactor * (info.offsetWidth) / info.width) * info.width * info.snapDirectionFactor
    print(angleDecre)
    angleDecre = Utils.clamp(angleDecre, -angleLimit, angleLimit)

    local steer = _iB * (refangle - angleDecre)
    if self.isReverseDriving then
        steer = -steer
    end

    if self.articulatedAxis ~= nil or self.steeringMode ~= nil then
        if self.lastSpeedReal * 3600 < 0.1 then
            steer = self.guidanceSteeringOffset
        end
    end

    self.guidanceSteeringOffset = steer

    if self.steeringEnabled then
        --        if if analog controller? then
        --            self.axisSide = Utils.getNoNil(self.guidanceSteeringOffset,0)
        --        else
        self.axisSide = self.axisSide + Utils.getNoNil(self.guidanceSteeringOffset, 0)
        --        end

        if self.guidanceSteeringIsActive then
            self.axisSideIsAnalog = true
        end
    end
    -- end
end