GlobalPositioningSystem = {}

-- Modes:
-- AB lines
-- Curves
-- Circles

GlobalPositioningSystem.CONFIG_NAME = "buyableGPS"
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
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "leaveVehicle", GlobalPositioningSystem.inj_leaveVehicle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", GlobalPositioningSystem.inj_getIsVehicleControlledByPlayer)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setReverserDirection", GlobalPositioningSystem.inj_setReverserDirection)
end

function GlobalPositioningSystem:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient and isActiveForInputIgnoreSelection then
        local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
        local _, actionEventIdSetPoint = self:addActionEvent(spec.actionEvents, InputAction.GS_SETPOINT, self, GlobalPositioningSystem.actionEventSetABPoint, false, true, false, true, nil, nil, true)
        local _, actionEventIdAutoWidth = self:addActionEvent(spec.actionEvents, InputAction.GS_SET_AUTO_WIDTH, self, GlobalPositioningSystem.actionEventSetAutoWidth, false, true, false, true, nil, nil, true)
        local _, actionEventIdMinusWidth = self:addActionEvent(spec.actionEvents, InputAction.GS_MINUS_WIDTH, self, GlobalPositioningSystem.actionEventMinusWidth, false, true, false, true, nil, nil, true)
        local _, actionEventIdPlusWidth = self:addActionEvent(spec.actionEvents, InputAction.GS_PLUS_WIDTH, self, GlobalPositioningSystem.actionEventPlusWidth, false, true, false, true, nil, nil, true)
        local _, actionEventIdEnableSteering = self:addActionEvent(spec.actionEvents, InputAction.GS_ENABLE_STEERING, self, GlobalPositioningSystem.actionEventEnableSteering, false, true, false, true, nil, nil, true)

        g_inputBinding:setActionEventTextVisibility(actionEventIdSetPoint, false)
        g_inputBinding:setActionEventTextVisibility(actionEventIdAutoWidth, false)
        g_inputBinding:setActionEventTextVisibility(actionEventIdMinusWidth, false)
        g_inputBinding:setActionEventTextVisibility(actionEventIdPlusWidth, false)
        g_inputBinding:setActionEventTextVisibility(actionEventIdEnableSteering, false)
    end
end

function GlobalPositioningSystem.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", GlobalPositioningSystem)
end

function GlobalPositioningSystem.initSpecialization()
    g_configurationManager:addConfigurationType(GlobalPositioningSystem.CONFIG_NAME, g_i18n:getText("configuration_buyableGPS"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function GlobalPositioningSystem:onLoad(savegame)
    local hasGuidanceSystem = false
    local guidanceConfigId = self.configurations[GlobalPositioningSystem.CONFIG_NAME]

    if guidanceConfigId ~= nil then
        -- TODO: get actual store item
        --        local item = StoreItemUtil.storeItemsByXMLFilename[self.configFileName:lower()];
        --        local storeItem = self.storeItem
        --        local storeConfigurations = storeItem.configurations[GlobalPositioningSystem.CONFIG_NAME]
        --
        --        if storeConfigurations ~= nil then
        --            local config = storeConfigurations[guidanceConfigId]
        --            hasGuidanceSystem = config.enabled
        hasGuidanceSystem = guidanceConfigId ~= 1
        ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.buyableGPSConfigurations.buyableGPSConfiguration", guidanceConfigId, self.components, self)

        Logger.info("hasGuidanceSystem", hasGuidanceSystem)
        --        end
    end

    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    spec.hasGuidanceSystem = hasGuidanceSystem

    if not spec.hasGuidanceSystem then
        return
    end

    spec.axisAccelerate = 0
    spec.axisBrake = 0

    local rootNode = self.components[1].node
    local componentIndex = getXMLString(self.xmlFile, "vehicle.guidanceSteering#index")

    if componentIndex ~= nil then
        rootNode = I3DUtil.indexToObject(self.components, componentIndex)
    end

    spec.guidanceNode = createTransformGroup("guidance_node")
    spec.guidanceReverseNode = createTransformGroup("guidance_reverse_node")
    link(rootNode, spec.guidanceNode)
    link(rootNode, spec.guidanceReverseNode)
    setTranslation(spec.guidanceNode, 0, 0, 0)
    setTranslation(spec.guidanceReverseNode, 0, 0, 0)
    setRotation(spec.guidanceReverseNode, 0, math.rad(180), 0)

    spec.lineStrategy = StraightABStrategy:new(self)

    --    Logger.info("hello from spec")

    spec.guidanceIsActive = true -- todo: make toggle
    spec.showGuidanceLines = true -- todo: make toggle
    spec.guidanceSteeringIsActive = false
    spec.guidanceSteeringDirection = 0
    spec.guidanceTerrainAngleIsActive = false
    spec.guidanceSteeringOffset = 0
    spec.abDistanceCounter = 0
    spec.abClickCounter = 0

    spec.guidanceData = {
        width = GlobalPositioningSystem.DEFAULT_WIDTH,
        offsetWidth = 0,
        movingDirection = 1,
        isReverseDriving = false,
        movingFowards = false,
        snapDirectionMultiplier = 1,
        alphaRad = 0,
        currentLane = 0,
        startLane = 0,
        snapDirection = { 0, 0, 0, 0 },
        driveTarget = { 0, 0, 0, 0, 0 },
        snapDirectionForwards = true
    }

    spec.ui = g_guidanceSteering.ui
    spec.uiActive = false
end

function GlobalPositioningSystem:onLoadFinished(savegame)
end

function GlobalPositioningSystem:onDelete()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.ui:delete()
end

function GlobalPositioningSystem:onUpdate(dt)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    if not spec.hasGuidanceSystem then
        return
    end

    if not self.isServer then
        return
    end

    --    if not self:getIsActive() or not self.isControlled then
    --        return
    --    end

    DebugUtil.drawDebugNode(spec.guidanceNode)
    DebugUtil.drawDebugNode(spec.guidanceReverseNode)

    if spec.guidanceIsActive then
        local lastSpeed = self:getLastSpeed()
        local distance = self.lastMovedDistance
        local guidanceNode = spec.guidanceNode
        local data = spec.guidanceData

        data.movingFowards = self:getIsDrivingForward()

        spec.abDistanceCounter = spec.abDistanceCounter + distance
        spec.lineStrategy:update(dt, data, guidanceNode, lastSpeed)

        GlobalPositioningSystem.setGuidanceData(self, false, false)

        local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)
        local x, _, z, driveDirX, driveDirZ = unpack(data.driveTarget)
        local lineAlpha = GuidanceUtil.getAProjectOnLineParameter(z, x, lineZ, lineX, lineDirX, lineDirZ) / data.width

        data.currentLane = GuidanceUtil.mathRound(lineAlpha)
        data.alphaRad = lineAlpha - data.currentLane

        -- Todo: straight needs this?
        local dirX, _, dirZ = localDirectionToWorld(guidanceNode, worldDirectionToLocal(guidanceNode, lineDirX, 0, lineDirZ))
        --                local dirX, dirZ = lineDirX, lineDirZ

        local dot = MathUtil.clamp(driveDirX * dirX + driveDirZ * dirZ, GlobalPositioningSystem.DIRECTION_LEFT, GlobalPositioningSystem.DIRECTION_RIGHT)
        local angle = math.acos(dot) -- dot towards point

        local snapDirectionMultiplier = 1
        if angle < 1.5708 then -- 90 deg
            snapDirectionMultiplier = -snapDirectionMultiplier
        end

        local drivingDirection = self:getDrivingDirection()
        if drivingDirection ~= 0 then
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

            if spec.showGuidanceLines then
                spec.lineStrategy:draw(data)
            end
        end

        if spec.guidanceSteeringIsActive then
            GlobalPositioningSystem.guideSteering(self, dt)
        end
    end
end

function GlobalPositioningSystem:onDraw()
end

function GlobalPositioningSystem.inj_getIsVehicleControlledByPlayer(vehicle, superFunc)
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.guidanceSteeringIsActive then
        return false
    end

    return superFunc(vehicle)
end

function GlobalPositioningSystem.inj_leaveVehicle(vehicle, superFunc)
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.hasGuidanceSystem and spec.uiActive then
        spec.ui:setVehicle(nil)
    end

    return superFunc(vehicle)
end

function GlobalPositioningSystem.inj_setReverserDirection(vehicle, superFunc, reverserDirection)
    if reverserDirection ~= 0 then
        Logger.info("Reverse direction", reverserDirection)
    end
    return superFunc(vehicle, reverserDirection)
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

function GlobalPositioningSystem:setGuidanceStrategy()
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.lineStrategy = StraightABStrategy:new(self)
end

function GlobalPositioningSystem.setGuidanceData(self, updateDirection, updateReverser)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local data = spec.guidanceData

    local guidanceNode = spec.guidanceNode
    if not data.movingFowards then
        guidanceNode = spec.guidanceReverseNode
    end

    local transX, transY, transZ
    local dirX, dirZ

    if spec.lineStrategy:getHasABDependentDirection()
            and spec.lineStrategy:getIsABDirectionPossible() then
        local strategyData = spec.lineStrategy:getGuidanceData(guidanceNode, data)

        transX, transY, transZ = strategyData.tx, strategyData.ty, strategyData.tz
        dirX, dirZ = strategyData.dirX, strategyData.dirZ
    else
        local dx, _, dz = localDirectionToWorld(guidanceNode, 0, 0, 1)
        transX, transY, transZ = getWorldTranslation(guidanceNode)
        dirX, dirZ = dx, dz
    end

    local driveDirX, driveDirZ = GuidanceUtil.getDriveDirection(dirX, dirZ)
    if not data.snapDirectionForwards then
        driveDirX, driveDirZ = -driveDirX, -driveDirZ
    end

    -- Includes: drive data
    -- Guidance node xyz translation and xz direction
    data.driveTarget = { transX, transY, transZ, driveDirX, driveDirZ }

    if updateDirection then
        -- Take angle snapping from AI code
        local snapAngle = math.max(self:getDirectionSnapAngle(), math.pi / (g_currentMission.terrainDetailAngleMaxValue + 1))
        --        local angleRad = MathUtil.getYRotationFromDirection(dirX, dirZ) -- Todo: whats the new function
        local angleRad = math.atan2(dirX, dirZ)

        if spec.guidanceTerrainAngleIsActive then
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
        data.snapDirectionForwards = data.movingFowards
    end
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
    local dX, dY, dZ, driveDirX, driveDirZ = unpack(data.driveTarget)
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

    local driveable = vehicle:guidanceSteering_getSpecTable("drivable")
    --Drivable.actionEventAccelerate(self, actionName, inputValue, callbackState, isAnalog)
    local axisForward = MathUtil.clamp((spec.axisAccelerate - spec.axisBrake), -1, 1)
    driveable.axisForward = axisForward

    spec.axisAccelerate = 0
    spec.axisBrake = 0

    if driveable.axisForward ~= driveable.axisForwardSend then
        driveable.axisForwardSend = driveable.axisForward
        vehicle:raiseDirtyFlags(driveable.dirtyFlag)
    end

    DriveUtil.accelerateInDirection(vehicle, axisForward, dt)
end

function GlobalPositioningSystem.updateUI(self)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.uiActive = not spec.uiActive

    local vehicle
    if spec.uiActive then
        vehicle = self
    end

    if spec.ui:getVehicle() ~= vehicle then
        spec.ui:setVehicle(vehicle)
    end

    Logger.info("Calculated width", spec.guidanceData.width)

    spec.ui:dataChanged(spec.guidanceData)
end

--- Action events
function GlobalPositioningSystem.actionEventSetAutoWidth(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceData.offsetWidth = 0
    spec.guidanceData.width = GlobalPositioningSystem.getActualWorkWidth(spec.guidanceNode, self)
    GlobalPositioningSystem.updateUI(self)
end

function GlobalPositioningSystem.actionEventMinusWidth(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceData.width = spec.guidanceData.width + 0.05
    GlobalPositioningSystem.updateUI(self)
end

function GlobalPositioningSystem.actionEventPlusWidth(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceData.width = math.max(0, spec.guidanceData.width - 0.05)
    GlobalPositioningSystem.updateUI(self)
end

function GlobalPositioningSystem.actionEventSetABPoint(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    -- Todo: Cleanup mess
    local reset = spec.abClickCounter < 1
    local generateA = spec.abClickCounter > 0 and spec.abClickCounter < 2
    local generateB = spec.abClickCounter > 1 and spec.abClickCounter < 3
    local generate = spec.abClickCounter > 2 and spec.abClickCounter < 4

    if generateB and spec.abDistanceCounter < 10 then
        g_currentMission:showBlinkingWarning("Drive 10m in other to set point B. Current traveled distance: " .. tostring(spec.abDistanceCounter), 4000)
    else
        if reset then
            spec.abDistanceCounter = 0
            spec.guidanceData.snapDirection = { 0, 0, 0, 0 }
            spec.guidanceData.snapDirectionForwards = true
            spec.lineStrategy:delete()
            Logger.info("Reset AB Line")
        elseif generateA or generateB then
            spec.lineStrategy:pushABPoint(spec.guidanceData)
        end

        spec.abClickCounter = spec.abClickCounter + 1

        if generate then
            spec.abClickCounter = 0
            Logger.info("Generate AB Line")
            GlobalPositioningSystem.setGuidanceData(self, true, false)
        end
    end
end

function GlobalPositioningSystem.actionEventEnableSteering(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceSteeringIsActive = not spec.guidanceSteeringIsActive
    self.spec_drivable.allowPlayerControl = self.guidanceSteeringIsActive

    Logger.info("guidanceSteeringIsActive", spec.guidanceSteeringIsActive)
end
