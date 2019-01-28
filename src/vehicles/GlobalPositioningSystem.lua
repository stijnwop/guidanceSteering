GlobalPositioningSystem = {}

-- Modes:
-- AB lines
-- Curves
-- Circles

GlobalPositioningSystem.CONFIG_NAME = "buyableGPS"
GlobalPositioningSystem.DEFAULT_WIDTH = 9.144 -- autotrack default (~30ft)
GlobalPositioningSystem.DIRECTION_LEFT = -1
GlobalPositioningSystem.DIRECTION_RIGHT = 1
GlobalPositioningSystem.AB_DROP_DISTANCE = 15
GlobalPositioningSystem.MAX_TRACKS = 2 ^ 6

function GlobalPositioningSystem.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function GlobalPositioningSystem.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getGuidanceStrategy", GlobalPositioningSystem.getGuidanceStrategy)
    SpecializationUtil.registerFunction(vehicleType, "setGuidanceStrategy", GlobalPositioningSystem.setGuidanceStrategy)
    SpecializationUtil.registerFunction(vehicleType, "setGuidanceData", GlobalPositioningSystem.setGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "updateGuidanceData", GlobalPositioningSystem.updateGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "pushABPoint", GlobalPositioningSystem.pushABPoint)
    SpecializationUtil.registerFunction(vehicleType, "registerMultiPurposeActionEvents", GlobalPositioningSystem.registerMultiPurposeActionEvents)
end

function GlobalPositioningSystem.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", GlobalPositioningSystem.inj_getIsVehicleControlledByPlayer)
end

function GlobalPositioningSystem.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", GlobalPositioningSystem)
end

function GlobalPositioningSystem:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient and isActiveForInputIgnoreSelection then
        local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

        if not self:getIsAIActive() and spec.hasGuidanceSystem then
            local nonDrawnActionEvents = {}
            local function insert(_, actionEventId)
                table.insert(nonDrawnActionEvents, actionEventId)
            end

            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_SETPOINT, self, GlobalPositioningSystem.actionEventSetABPoint, false, true, false, true, nil, nil, true))
            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_SET_AUTO_WIDTH, self, GlobalPositioningSystem.actionEventSetAutoWidth, false, true, false, true, nil, nil, true))
            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_MINUS_WIDTH, self, GlobalPositioningSystem.actionEventMinusWidth, false, true, false, true, nil, nil, true))
            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_PLUS_WIDTH, self, GlobalPositioningSystem.actionEventPlusWidth, false, true, false, true, nil, nil, true))
            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_ENABLE_STEERING, self, GlobalPositioningSystem.actionEventEnableSteering, false, true, false, true, nil, nil, true))
            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_SHIFT_LEFT, self, GlobalPositioningSystem.actionEventShiftLeft, false, true, false, true, nil, nil, true))
            insert(self:addActionEvent(spec.actionEvents, InputAction.GS_SHIFT_RIGHT, self, GlobalPositioningSystem.actionEventShiftRight, false, true, false, true, nil, nil, true))

            for _, actionEventId in ipairs(nonDrawnActionEvents) do
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end

            local _, actionEventIdToggleUI = self:addActionEvent(spec.actionEvents, InputAction.GS_SHOW_UI, self, GlobalPositioningSystem.actionEventOnToggleUI, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(actionEventIdToggleUI, true)
            g_inputBinding:setActionEventTextPriority(actionEventIdToggleUI, GS_PRIO_LOW)
        end
    end
end

function GlobalPositioningSystem.initSpecialization()
    g_configurationManager:addConfigurationType(GlobalPositioningSystem.CONFIG_NAME, g_i18n:getText("configuration_buyableGPS"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function GlobalPositioningSystem:onLoad(savegame)
    local hasGuidanceSystem = false
    local configId = self.configurations[GlobalPositioningSystem.CONFIG_NAME]

    if configId ~= nil then
        local item = g_storeManager:getItemByXMLFilename(self.configFileName)
        local config = item.configurations[GlobalPositioningSystem.CONFIG_NAME][configId]

        if config ~= nil then
            hasGuidanceSystem = config.enabled
            ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.buyableGPSConfigurations.buyableGPSConfiguration", configId, self.components, self)
        end
    end

    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    spec.hasGuidanceSystem = hasGuidanceSystem

    if not spec.hasGuidanceSystem then
        return
    end

    spec.savedTracks = {}
    spec.axisAccelerate = 0
    spec.axisBrake = 0

    local rootNode = self.components[1].node
    local componentIndex = getXMLString(self.xmlFile, "vehicle.guidanceSteering#index")

    if componentIndex ~= nil then
        rootNode = I3DUtil.indexToObject(self.components, componentIndex)
    end

    spec.guidanceNode = createTransformGroup("guidance_node")
    spec.guidanceTargetNode = createTransformGroup("guidance_reverse_node")
    link(rootNode, spec.guidanceNode)
    link(rootNode, spec.guidanceTargetNode)
    setTranslation(spec.guidanceNode, 0, 0, 0)
    setTranslation(spec.guidanceTargetNode, 0, 0, 0)
    setRotation(spec.guidanceTargetNode, 0, math.rad(180), 0)

    spec.lineStrategy = StraightABStrategy:new(self)
    spec.guidanceIsActive = true -- todo: make toggle
    spec.showGuidanceLines = true
    spec.guidanceSteeringIsActive = false
    spec.guidanceTerrainAngleIsActive = false

    spec.shiftParallel = false
    spec.shiftParallelDirection = GlobalPositioningSystem.DIRECTION_RIGHT

    spec.guidanceSteeringOffset = 0
    spec.abDistanceCounter = 0
    spec.abClickCounter = 0

    -- Headland calculations
    spec.lastIsNotOnField = false
    spec.distanceToEnd = 0
    spec.lastValidGroundPos = { 0, 0, 0 }

    spec.lastInputValues = {}
    spec.lastInputValues.guidanceIsActive = true -- todo: make toggle
    spec.lastInputValues.showGuidanceLines = true
    spec.lastInputValues.guidanceSteeringIsActive = false
    spec.lastInputValues.guidanceTerrainAngleIsActive = false
    spec.lastInputValues.shiftParallel = false
    spec.lastInputValues.shiftParallelDirection = GlobalPositioningSystem.DIRECTION_RIGHT

    spec.guidanceSteeringIsActiveSend = false
    spec.showGuidanceLinesSend = false
    spec.guidanceIsActiveSend = false
    spec.shiftParallelSend = false
    spec.shiftParallelDirectionSend = false

    spec.guidanceData = {}
    spec.guidanceData.width = GlobalPositioningSystem.DEFAULT_WIDTH
    spec.guidanceData.offsetWidth = 0
    spec.guidanceData.movingDirection = 1
    spec.guidanceData.isReverseDriving = false
    spec.guidanceData.movingForwards = false
    spec.guidanceData.snapDirectionMultiplier = 1
    spec.guidanceData.alphaRad = 0
    spec.guidanceData.currentLane = 0
    spec.guidanceData.startLane = 0
    spec.guidanceData.snapDirection = { 0, 0, 0, 0 }
    spec.guidanceData.driveTarget = { 0, 0, 0, 0, 0 }
    spec.guidanceData.snapDirectionForwards = true

    spec.ui = g_guidanceSteering.ui
    spec.dirtyFlag = self:getNextDirtyFlag()

    self:registerMultiPurposeActionEvents()

    spec.isCreated = false
end

function GlobalPositioningSystem:onPostLoad(savegame)
end

function GlobalPositioningSystem:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

        if spec.hasGuidanceSystem then
            local data = GuidanceUtil.readGuidanceDataObject(streamId)

            -- sync guidance data
            self:updateGuidanceData(false, data, true)

            -- sync settings
            spec.showGuidanceLines = streamReadBool(streamId)
            spec.guidanceIsActive = streamReadBool(streamId)
            spec.guidanceSteeringIsActive = streamReadBool(streamId)
            spec.guidanceTerrainAngleIsActive = streamReadBool(streamId)
        end
    end
end

function GlobalPositioningSystem:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

        if spec.hasGuidanceSystem then
            local data = spec.guidanceData

            -- sync guidance data
            GuidanceUtil.writeGuidanceDataObject(streamId, data)

            -- sync settings
            streamWriteBool(streamId, spec.showGuidanceLines)
            streamWriteBool(streamId, spec.guidanceIsActive)
            streamWriteBool(streamId, spec.guidanceSteeringIsActive)
            streamWriteBool(streamId, spec.guidanceTerrainAngleIsActive)
        end
    end
end

function GlobalPositioningSystem:onReadUpdateStream(streamId, timestamp, connection)
    --if connection:getIsServer() then
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    if spec.hasGuidanceSystem then
        if streamReadBool(streamId) then
            spec.showGuidanceLines = streamReadBool(streamId)
            spec.guidanceIsActive = streamReadBool(streamId)
            spec.guidanceSteeringIsActive = streamReadBool(streamId)
            spec.guidanceTerrainAngleIsActive = streamReadBool(streamId)
            spec.shiftParallel = streamReadBool(streamId)
            spec.shiftParallelDirection = streamReadInt8(streamId)
        end
    end
    -- end
end

function GlobalPositioningSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
    --if not connection:getIsServer() then
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    if spec.hasGuidanceSystem then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.showGuidanceLines)
            streamWriteBool(streamId, spec.guidanceIsActive)
            streamWriteBool(streamId, spec.guidanceSteeringIsActive)
            streamWriteBool(streamId, spec.guidanceTerrainAngleIsActive)

            streamWriteBool(streamId, spec.shiftParallel)
            streamWriteInt8(streamId, spec.shiftParallelDirection)
        end
    end
    --end
end

function GlobalPositioningSystem:saveToXMLFile(xmlFile, key, usedModNames)
end

function GlobalPositioningSystem:onDelete()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    -- Cleanup current strategy
    spec.lineStrategy:delete()

    -- Delete guidance nodes
    delete(spec.guidanceNode)
    delete(spec.guidanceTargetNode)

    -- Remove sounds
end

function GlobalPositioningSystem.updateNetWorkInputs(self)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    spec.showGuidanceLines = spec.lastInputValues.showGuidanceLines
    spec.guidanceIsActive = spec.lastInputValues.guidanceIsActive
    spec.guidanceSteeringIsActive = spec.lastInputValues.guidanceSteeringIsActive
    spec.guidanceTerrainAngleIsActive = spec.lastInputValues.guidanceTerrainAngleIsActive
    spec.shiftParallel = spec.lastInputValues.shiftParallel
    spec.shiftParallelDirection = spec.lastInputValues.shiftParallelDirection

    -- Reset
    spec.lastInputValues.shiftParallel = false

    if spec.guidanceSteeringIsActive ~= spec.guidanceSteeringIsActiveSend
            or spec.showGuidanceLines ~= spec.showGuidanceLinesSend
            or spec.guidanceIsActive ~= spec.guidanceIsActiveSend
            or spec.guidanceTerrainAngleIsActive ~= spec.guidanceTerrainAngleIsActiveSend
            or spec.shiftParallel ~= spec.shiftParallelSend
            or spec.shiftParallelDirection ~= spec.shiftParallelDirectionSend
    then
        spec.guidanceSteeringIsActiveSend = spec.guidanceSteeringIsActive
        spec.showGuidanceLinesSend = spec.showGuidanceLines
        spec.guidanceIsActiveSend = spec.guidanceIsActive
        spec.guidanceTerrainAngleIsActiveSend = spec.guidanceTerrainAngleIsActive
        spec.shiftParallelSend = spec.shiftParallel
        spec.shiftParallelDirectionSend = spec.shiftParallelDirection

        self:raiseDirtyFlags(spec.dirtyFlag)
    end
end

function GlobalPositioningSystem:onUpdate(dt)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

    -- We don't update when no player is in the vehicle
    if not spec.hasGuidanceSystem or not isControlled then
        return
    end

    if self.isClient then
        if self.getIsEntered ~= nil and self:getIsEntered() then
            local guidanceSteeringIsActive = spec.lastInputValues.guidanceSteeringIsActive

            if guidanceSteeringIsActive then
                if self:getIsActiveForInput(true, true) then
                    local drivable_spec = self:guidanceSteering_getSpecTable("drivable")
                    local axisForward = MathUtil.clamp((spec.axisAccelerate - spec.axisBrake), -1, 1)

                    drivable_spec.axisForward = axisForward
                    spec.axisAccelerate = 0
                    spec.axisBrake = 0

                    -- Do network update
                    if drivable_spec.axisForward ~= drivable_spec.axisForwardSend then
                        drivable_spec.axisForwardSend = drivable_spec.axisForward
                        self:raiseDirtyFlags(drivable_spec.dirtyFlag)
                    end
                end
            end

            GlobalPositioningSystem.updateNetWorkInputs(self)
        end
    end

    if not spec.guidanceIsActive then
        return
    end

    if spec.shiftParallel then
        GlobalPositioningSystem.shiftParallel(data, dt, spec.shiftParallelDirection)
    end

    local drivingDirection = self:getDrivingDirection()
    -- Only compute when the vehicle is moving
    if drivingDirection == 0 then
        return
    end

    local guidanceSteeringIsActive = spec.guidanceSteeringIsActive
    local distance = self.lastMovedDistance

    spec.abDistanceCounter = spec.abDistanceCounter + distance

    local lastSpeed = self:getLastSpeed()
    local guidanceNode = spec.guidanceNode
    local data = spec.guidanceData

    data.movingForwards = self:getIsDrivingForward()

    spec.lineStrategy:update(dt, data, guidanceNode, lastSpeed)

    GlobalPositioningSystem.computeGuidanceTarget(self)

    local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)
    local x, y, z, driveDirX, driveDirZ = unpack(data.driveTarget)
    local lineAlpha = GuidanceUtil.getAProjectOnLineParameter(z, x, lineZ, lineX, lineDirX, lineDirZ) / data.width

    data.currentLane = MathUtil.round(lineAlpha)
    data.alphaRad = lineAlpha - data.currentLane

    -- Todo: straight strategy prob needs this?
    local dirX, _, dirZ = localDirectionToWorld(guidanceNode, worldDirectionToLocal(guidanceNode, lineDirX, 0, lineDirZ))
    --                local dirX, dirZ = lineDirX, lineDirZ

    local angle = math.acos(driveDirX * dirX + driveDirZ * dirZ) -- dot towards point

    local snapDirectionMultiplier = 1
    -- 90 deg
    if angle < 1.5708 then
        snapDirectionMultiplier = -snapDirectionMultiplier
    end

    local spec_reverseDriving = self.spec_reverseDriving

    data.snapDirectionMultiplier = snapDirectionMultiplier
    data.isReverseDriving = spec_reverseDriving ~= nil and spec_reverseDriving.isReverseDriving

    local movingDirection = 1
    if not data.isReverseDriving and self.movingDirection < 0 and lastSpeed > 2 then
        movingDirection = -movingDirection
    end

    if data.isReverseDriving then
        movingDirection = -movingDirection

        if self.movingDirection > 0 then
            movingDirection = math.abs(movingDirection)
        end
    end

    data.movingDirection = movingDirection

    if not self.isServer then
        return
    end

    if guidanceSteeringIsActive then
        GlobalPositioningSystem.guideSteering(self, dt)

        local isOnField = self:getIsOnField()

        if isOnField then
            local speedMultiplier = 1 + lastSpeed / 100 -- increase break distance
            local distanceToTurn = 9 * speedMultiplier -- Todo: make configurable
            local lookAheadStepDistance = 11 * speedMultiplier -- m
            local distanceToHeadLand, isDistanceOnField = GuidanceUtil.getDistanceToHeadLand(self, x, y, z, lookAheadStepDistance)

            --Logger.info(("lookAheadStepDistance: %.1f (owned: %s)"):format(lookAheadStepDistance, tostring(isDistanceOnField)))
            --Logger.info(("End of field distance: %.1f (owned: %s)"):format(distanceToHeadLand, tostring(isDistanceOnField)))

        end
    end
end

function GlobalPositioningSystem:onDraw()
    if not self.isClient then
        return
    end

    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    if not spec.hasGuidanceSystem then
        return
    end

    if spec.guidanceIsActive then
        if spec.showGuidanceLines then
            spec.lineStrategy:draw(spec.guidanceData)
        end
    end
end

function GlobalPositioningSystem.inj_getIsVehicleControlledByPlayer(vehicle, superFunc)
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.guidanceSteeringIsActive then
        return false
    end

    return superFunc(vehicle)
end

function GlobalPositioningSystem:onLeaveVehicle()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    if spec.hasGuidanceSystem then
        spec.ui:setVehicle(nil)
    end
end

function GlobalPositioningSystem:onEnterVehicle()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    if spec.hasGuidanceSystem then
        if spec.ui:getVehicle() ~= self then
            spec.ui:setVehicle(self)
        end
    end
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

function GlobalPositioningSystem:setGuidanceStrategy(method)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    if method == ABStrategy.AB then
        spec.lineStrategy = StraightABStrategy:new(self)
    elseif method == ABStrategy.A_AUTO_B then

    elseif method == ABStrategy.A_PLUS_HEADING then
        spec.lineStrategy = CardinalStrategy:new(self)
    end
end

function GlobalPositioningSystem:getGuidanceStrategy()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    return spec.lineStrategy
end

function GlobalPositioningSystem:setGuidanceData(guidanceData)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceData = guidanceData
end

function GlobalPositioningSystem:pushABPoint(noEventSend)
    ABPointPushedEvent.sendEvent(self, noEventSend)

    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.lineStrategy:pushABPoint(spec.guidanceData)
end

function GlobalPositioningSystem:updateGuidanceData(doReset, guidanceData, noEventSend)
    GuidanceDataChangedEvent.sendEvent(self, doReset, guidanceData, noEventSend)

    Logger.info("[updateGuidanceData]: resetting = ", doReset)

    if doReset then
        GlobalPositioningSystem.resetGuidanceData(self)
    else
        Logger.info("[updateGuidanceData]: guidanceData = ", guidanceData)

        if guidanceData ~= nil then
            local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
            local data = spec.guidanceData

            data.width = guidanceData.width
            data.snapDirectionMultiplier = guidanceData.snapDirectionMultiplier
            data.snapDirectionForwards = guidanceData.snapDirectionForwards
            data.snapDirection = guidanceData.snapDirection
            data.alphaRad = guidanceData.alphaRad
        end
    end
end

function GlobalPositioningSystem.computeGuidanceTarget(self)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local data = spec.guidanceData

    local guidanceNode = spec.guidanceTargetNode
    local transX, transY, transZ
    local dirX, dirZ

    if spec.lineStrategy:getHasABDependentDirection()
            and spec.lineStrategy:getIsABDirectionPossible() then
        if not data.movingForwards then
            guidanceNode = spec.guidanceNode -- inverse line
        end

        local strategyData = spec.lineStrategy:getGuidanceData(guidanceNode, data)
        transX, transY, transZ, dirX, dirZ = unpack(strategyData)
    else
        dirX, _, dirZ = localDirectionToWorld(guidanceNode, 0, 0, 1)
        transX, transY, transZ = getWorldTranslation(guidanceNode)
    end

    local driveDirX, driveDirZ = GuidanceUtil.getDriveDirection(dirX, dirZ)
    if not data.movingForwards then
        driveDirX, driveDirZ = -driveDirX, -driveDirZ
    end

    --Logger.info("snapDirectionForwards", data.movingForwards)
    --Logger.info("dir", { driveDirX, driveDirZ })

    -- Guidance driveTarget
    data.driveTarget = {
        transX, -- x translation of target
        transY, -- y translation of target
        transZ, -- z translation of target
        driveDirX, -- x direction of target
        driveDirZ -- z direction of target
    }
end

function GlobalPositioningSystem.computeGuidanceDirection(self)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local data = spec.guidanceData

    local guidanceNode = spec.guidanceTargetNode
    if spec.lineStrategy:getHasABDependentDirection()
            and spec.lineStrategy:getIsABDirectionPossible()
            and not data.movingForwards then
        guidanceNode = spec.guidanceNode -- inverse line
    end

    local dirX, _, dirZ = localDirectionToWorld(guidanceNode, 0, 0, 1)
    local transX, _, transZ = unpack(data.driveTarget)

    local angleRad = MathUtil.getYRotationFromDirection(dirX, dirZ)
    -- Snap to terrain when settings is active
    if spec.guidanceTerrainAngleIsActive then
        local snapAngle = math.max(self:getDirectionSnapAngle(), math.pi / (g_currentMission.terrainDetailAngleMaxValue + 1))
        angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
    end

    dirX, dirZ = math.sin(angleRad), math.cos(angleRad)

    local offsetFactor = 1.0 -- Todo: offset
    local x = transX + offsetFactor * data.snapDirectionMultiplier * data.offsetWidth * dirZ
    local z = transZ - offsetFactor * data.snapDirectionMultiplier * data.offsetWidth * dirX

    data.snapDirectionForwards = data.movingForwards
    -- Line direction and translation xz axis
    data.snapDirection = {
        dirX,
        dirZ,
        x,
        z
    }

    -- Update clients
    self:updateGuidanceData(false, data)
    spec.lineStrategy:delete()
    data.isCreated = true -- Todo: current placeholder
    Logger.info("Calculated snapdirection with data:", data)
end

function GlobalPositioningSystem.resetGuidanceData(self)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.abDistanceCounter = 0
    spec.lineStrategy:delete()

    local data = spec.guidanceData
    data.isCreated = false
    data.snapDirection = { 0, 0, 0, 0 }
    data.snapDirectionForwards = not data.isReverseDriving -- Todo: we might want to save this
end

function GlobalPositioningSystem.guideSteering(vehicle, dt)
    if vehicle.isHired then
        -- Disallow when AI is active
        return
    end

    local function drawDebugCircle(x, y, z, radius, steps, r, g, b)
        for i = 1, steps do
            local a1 = ((i - 1) / steps) * 2 * math.pi
            local a2 = ((i) / steps) * 2 * math.pi

            local c = math.cos(a1) * radius
            local s = math.sin(a1) * radius
            local x1, y1, z1 = x + c, y, z + s

            local c = math.cos(a2) * radius
            local s = math.sin(a2) * radius
            local x2, y2, z2 = x + c, y, z + s

            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b);
        end
    end

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    -- data
    local data = spec.guidanceData
    local guidanceNode = spec.guidanceNode
    local snapDirX, snapDirZ, snapX, snapZ = unpack(data.snapDirection)
    local dX, dY, dZ = unpack(data.driveTarget)
    local lineXDir = data.snapDirectionMultiplier * snapDirX --* data.movingDirection
    local lineZDir = data.snapDirectionMultiplier * snapDirZ --* data.movingDirection
    -- Calculate target points
    local x1 = dX + data.width * snapDirZ * data.alphaRad
    local z1 = dZ - data.width * snapDirX * data.alphaRad
    local step = 5 -- m
    local tX = x1 + step * lineXDir
    local tZ = z1 + step * lineZDir

    drawDebugCircle(snapX, dY, snapZ, .5, 10, 1, 0, 0)
    drawDebugCircle(tX, dY + .2, tZ, .5, 10, 0, 1, 0)

    local pX, _, pZ = worldToLocal(guidanceNode, tX, dY, tZ)

    DriveUtil.driveToPoint(vehicle, dt, pX, pZ)

    local drivable_spec = vehicle:guidanceSteering_getSpecTable("drivable")
    -- lock max speed to working tool
    local speed, _ = vehicle:getSpeedLimit(true)
    if drivable_spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
        speed = math.min(speed, drivable_spec.cruiseControl.speed)
    end

    vehicle:getMotor():setSpeedLimit(speed)

    DriveUtil.accelerateInDirection(vehicle, drivable_spec.axisForward, dt)
end

function GlobalPositioningSystem.shiftParallel(data, dt, direction)
    local snapFactor = Utils.getNoNil(data.snapDirectionMultiplier, 1.0)
    local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)

    -- Todo: take self.guidanceData.offsetWidth in account?
    lineX = lineX + (snapFactor * dt / 1000 * lineDirZ) * direction
    lineZ = lineZ + (snapFactor * dt / 1000 * lineDirX) * direction

    -- Todo: store what we offset?
    data.snapDirection = { lineDirX, lineDirZ, lineX, lineZ }
end

--- Action events
function GlobalPositioningSystem.actionEventOnToggleUI(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.ui:onToggleUI()
end

function GlobalPositioningSystem.actionEventSetAutoWidth(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local data = spec.guidanceData
    data.offsetWidth = 0
    data.width = GlobalPositioningSystem.getActualWorkWidth(spec.guidanceNode, self)
    self:updateGuidanceData(false, data)
end

function GlobalPositioningSystem.actionEventMinusWidth(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceData.width = math.max(0, spec.guidanceData.width - 0.05)
    self:updateGuidanceData(false, spec.guidanceData)
end

function GlobalPositioningSystem.actionEventPlusWidth(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceData.width = spec.guidanceData.width + 0.05
    self:updateGuidanceData(false, spec.guidanceData)
end

function GlobalPositioningSystem.actionEventShiftLeft(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.lastInputValues.shiftParallel = true
    spec.lastInputValues.shiftParallelDirection = GlobalPositioningSystem.DIRECTION_LEFT
end

function GlobalPositioningSystem.actionEventShiftRight(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.lastInputValues.shiftParallel = true
    spec.lastInputValues.shiftParallelDirection = GlobalPositioningSystem.DIRECTION_RIGHT
end

function GlobalPositioningSystem.actionEventSetABPoint(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    spec.multiActionEvent:handle()
end

function GlobalPositioningSystem.actionEventEnableSteering(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    self.spec_drivable.allowPlayerControl = self.guidanceSteeringIsActive

    spec.lastInputValues.guidanceSteeringIsActive = not spec.lastInputValues.guidanceSteeringIsActive

    Logger.info("guidanceSteeringIsActive", spec.lastInputValues.guidanceSteeringIsActive)
end

function GlobalPositioningSystem:registerMultiPurposeActionEvents()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local event = MultiPurposeActionEvent:new(4)

    event:addAction(function()
        self:updateGuidanceData(true)
        Logger.info("Resetting AB line strategy")
        return true
    end)

    event:addAction(function()
        self:pushABPoint()
        return true
    end)

    event:addAction(function()
        if spec.abDistanceCounter < GlobalPositioningSystem.AB_DROP_DISTANCE then
            g_currentMission:showBlinkingWarning("Drive 10m in other to set point B. Current traveled distance: " .. tostring(spec.abDistanceCounter), 4000)
            return false
        end

        self:pushABPoint()

        return true
    end)

    event:addAction(function()
        GlobalPositioningSystem.computeGuidanceDirection(self)
        Logger.info("Generating AB line strategy")
        return true
    end)

    spec.multiActionEvent = event
end
