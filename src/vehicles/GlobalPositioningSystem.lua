GlobalPositioningSystem = {}

-- Modes:
-- AB lines
-- Curves
-- Circles

GlobalPositioningSystem.DEFAULT_WIDTH = 9.144 -- autotrack default (~30ft)
GlobalPositioningSystem.DIRECTION_LEFT = -1
GlobalPositioningSystem.DIRECTION_RIGHT = 1

function GlobalPositioningSystem.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function GlobalPositioningSystem.registerEvents(vehicleType)
    --    SpecializationUtil.registerEvent(vehicleType, "onRegisterActionEvents", GlobalPositioningSystem)
end

function GlobalPositioningSystem.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setGuidanceStrategy", GlobalPositioningSystem.setGuidanceStrategy)
end

function GlobalPositioningSystem.registerOverwrittenFunctions(vehicleType)
end

function GlobalPositioningSystem:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient and isActiveForInputIgnoreSelection then
        local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
        local _, actionEventIdSetPoint = self:addActionEvent(spec.actionEvents, InputAction.GS_SETPOINT, self, GlobalPositioningSystem.actionEventSetABPoint, false, true, false, true, nil, nil, true)
        local _, actionEventIdAutoWidth = self:addActionEvent(spec.actionEvents, InputAction.GS_SET_AUTO_WIDTH, self, GlobalPositioningSystem.actionEventSetAutoWidth, false, true, false, true, nil, nil, true)

        g_inputBinding:setActionEventTextVisibility(actionEventIdSetPoint, false)
        g_inputBinding:setActionEventTextVisibility(actionEventIdAutoWidth, false)
    end
end

function GlobalPositioningSystem.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", GlobalPositioningSystem)
end

function GlobalPositioningSystem.initSpecialization()
end

function GlobalPositioningSystem:onLoad(savegame)
    local rootNode = self.components[1].node
    local componentIndex = getXMLString(self.xmlFile, "vehicle.guidanceSteering#index")

    if componentIndex ~= nil then
        rootNode = I3DUtil.indexToObject(self.components, componentIndex)
    end

    self.guidanceABNodes = {}
    self.guidanceNode = createTransformGroup("guidance_node")
    link(rootNode, self.guidanceNode)
    setTranslation(self.guidanceNode, 0, 0, 0)

    self.lineStrategy = StraightABStrategy:new(self)

    --    Logger.info("hello from spec")

    self.guidanceIsActive = true -- todo: make toggle
    self.guidanceSteeringIsActive = false
    self.guidanceSteeringDirection = 0
    self.guidanceTerrainAngleIsActive = false
    self.guidanceSteeringOffset = 0
    self.abDistanceCounter = 0
    self.abClickCounter = 0

    self.guidanceData = {
        width = GlobalPositioningSystem.DEFAULT_WIDTH,
        offsetWidth = 0,
        movingDirection = 1,
        snapDirectionMultiplier = 1,
        alphaRad = 0,
        currentLane = 0,
        startLane = 0,
        snapDirection = { 0, 0, 0, 0 },
        driveTarget = { 0, 0, 0, 0, 0 }
    }
end

function GlobalPositioningSystem:onLoadFinished(savegame)
end

function GlobalPositioningSystem:onUpdate(dt)
    if not self.isServer then
        return
    end

    --    if not self:getIsActive() or not self.isControlled then
    --        return
    --    end

    DebugUtil.drawDebugNode(self.guidanceNode)

    if self.guidanceIsActive then
        local lastSpeed = self:getLastSpeed(true)
        local distance = self.lastMovedDistance
        local data = self.guidanceData

        self.abDistanceCounter = self.abDistanceCounter + distance

        self.lineStrategy:update(dt, data, self.guidanceNode, lastSpeed)

        GlobalPositioningSystem.setGuidanceData(self, false)

        local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)
        local x, _, z, driveDirX, driveDirZ = unpack(data.driveTarget)
        --        local x, y, z = getWorldTranslation(self.guidanceNode)
        local lineAlpha = GuidanceUtil.getAProjectOnLineParameter(z, x, lineZ, lineX, lineDirX, lineDirZ) / data.width

        data.currentLane = GuidanceUtil.mathRound(lineAlpha)
        data.alphaRad = lineAlpha - data.currentLane

        -- Todo: straight needs this?
        local dirX, _, dirZ = localDirectionToWorld(self.guidanceNode, worldDirectionToLocal(self.guidanceNode, lineDirX, 0, lineDirZ))
        --                local dirX, dirZ = lineDirX, lineDirZ

        local dot = MathUtil.clamp(driveDirX * dirX + driveDirZ * dirZ, GlobalPositioningSystem.DIRECTION_LEFT, GlobalPositioningSystem.DIRECTION_RIGHT)
        local angle = math.acos(dot) -- dot towards point

        local snapDirectionMultiplier = 1
        if angle < 1.5708 then -- 90 deg
            snapDirectionMultiplier = -snapDirectionMultiplier
        end

        --        print("angle: " .. angle)
        --        print("snap: " .. snapDirectionMultiplier)

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

        --        if self.showGuidanceLines then
        self.lineStrategy:draw(data)
        --        end
    end
end

function GlobalPositioningSystem:actionEventSetAutoWidth()
    self.guidanceData.offsetWidth = 0
    self.guidanceData.width = GlobalPositioningSystem.getActualWorkWidth(self.guidanceNode, self)

    Logger.info("Calculated width", self.guidanceData.width)
end

function GlobalPositioningSystem.getActualWorkWidth(guidanceNode, object)
    local width = GuidanceUtil.getMaxWorkAreaWidth(guidanceNode, object)

    for _, implement in pairs(object.spec_attacherJoints.attachedImplements) do
        if implement.object ~= nil then
            width = math.max(width, GlobalPositioningSystem.getActualWorkWidth(guidanceNode, implement.object))
        end
    end

    return width
end

function GlobalPositioningSystem:actionEventSetABPoint()
    -- Cleanup mess
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
            Logger.info("Reset AB Line")
        elseif generateA or generateB then
            self.lineStrategy:pushABPoint(self.guidanceData)
        end

        self.abClickCounter = self.abClickCounter + 1

        if generate then
            self.abClickCounter = 0
            Logger.info("Generate AB Line")
            GlobalPositioningSystem.setGuidanceData(self, true)
        end
    end
end

function GlobalPositioningSystem:setGuidanceStrategy()
    self.lineStrategy = StraightABStrategy:new(self)
end

function GlobalPositioningSystem.setGuidanceData(self, updateDirection)
    local data = self.guidanceData
    local transX, transY, transZ
    local dirX, dirZ

    if self.lineStrategy:getHasABDependentDirection()
            and self.lineStrategy:getIsABDirectionPossible() then
        local strategyData = self.lineStrategy:getGuidanceData(self.guidanceNode, data)

        transX, transY, transZ = strategyData.tx, strategyData.ty, strategyData.tz
        dirX, dirZ = strategyData.dirX, strategyData.dirZ
    else
        local dx, _, dz = localDirectionToWorld(self.guidanceNode, 0, 0, 1)
        transX, transY, transZ = getWorldTranslation(self.guidanceNode)
        dirX, dirZ = dx, dz
    end

    local driveDirX, driveDirZ = GuidanceUtil.getDriveDirection(dirX, dirZ)

    -- Includes: drive data
    -- Guidance node xyz translation and xz direction
    data.driveTarget = { transX, transY, transZ, driveDirX, driveDirZ }

    if updateDirection then
        -- Take angle snapping from AI code
        local snapAngle = math.max(self:getDirectionSnapAngle(), math.pi / (g_currentMission.terrainDetailAngleMaxValue + 1))
        --        local angleRad = MathUtil.getYRotationFromDirection(dirX, dirZ) -- Todo: whats the new function
        local angleRad = math.atan2(dirX, dirZ)

        if self.guidanceTerrainAngleIsActive then
            angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
        end

        dirX, dirZ = math.sin(angleRad), math.cos(angleRad)

        local offsetFactor = 1.0 -- offset?
        local snapFactor = Utils.getNoNil(data.snapDirectionMultiplier, 1.0)
        local x = transX + offsetFactor * snapFactor * data.offsetWidth * dirZ
        local z = transZ - offsetFactor * snapFactor * data.offsetWidth * dirX

        -- Includes: line data
        -- Line direction and translation xz axis
        data.snapDirection = { dirX, dirZ, x, z }
    end
end
