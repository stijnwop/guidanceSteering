---
-- GlobalPositioningSystem
--
-- Main vehicle specialization for Guidance Steering
--
-- Copyright (c) Wopster, 2019

GlobalPositioningSystem = {}

-- Modes:
-- AB lines
-- Curves
-- Circles

GlobalPositioningSystem.CONFIG_NAME = "globalPositioningSystem"
GlobalPositioningSystem.DEFAULT_WIDTH = 9.144 -- autotrack default (~30ft)
GlobalPositioningSystem.DEFAULT_OFFSET = 0
GlobalPositioningSystem.DIRECTION_LEFT = -1
GlobalPositioningSystem.DIRECTION_RIGHT = 1
GlobalPositioningSystem.AB_DROP_DISTANCE = 15

-- For changing width and shifting the track
GlobalPositioningSystem.MAX_INPUT_MULTIPLIER = 20
GlobalPositioningSystem.INPUT_MULTIPLIER_STEP = 0.005

function GlobalPositioningSystem.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function GlobalPositioningSystem.initSpecialization(vehicleType)
    local schema = Vehicle.xmlSchema

    schema:setXMLSpecializationType("GuidanceSteering")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.guidanceSteering#node", "GuidanceSteering rootNode")
    schema:setXMLSpecializationType()

    g_configurationManager:addConfigurationType(GlobalPositioningSystem.CONFIG_NAME, g_i18n:getText("configuration_buyableGPS"), "globalPositioningSystem", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, ("vehicles.vehicle(?).%s.globalPositioningSystem#guidanceIsActive"):format(g_guidanceSteeringModName), "The guidance system active state")
    schemaSavegame:register(XMLValueType.BOOL, ("vehicles.vehicle(?).%s.globalPositioningSystem#autoInvertOffset"):format(g_guidanceSteeringModName), "The guidance auto invert offset state")
    schemaSavegame:register(XMLValueType.FLOAT, ("vehicles.vehicle(?).%s.globalPositioningSystem#lineDistance"):format(g_guidanceSteeringModName), "The guidance line distance")
end

function GlobalPositioningSystem.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getHasGuidanceSystem", GlobalPositioningSystem.getHasGuidanceSystem)
    SpecializationUtil.registerFunction(vehicleType, "getGuidanceStrategy", GlobalPositioningSystem.getGuidanceStrategy)
    SpecializationUtil.registerFunction(vehicleType, "setGuidanceStrategy", GlobalPositioningSystem.setGuidanceStrategy)
    SpecializationUtil.registerFunction(vehicleType, "getGuidanceData", GlobalPositioningSystem.getGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "updateGuidanceData", GlobalPositioningSystem.updateGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "interactWithGuidanceStrategy", GlobalPositioningSystem.interactWithGuidanceStrategy)
    SpecializationUtil.registerFunction(vehicleType, "onResetGuidanceData", GlobalPositioningSystem.onResetGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "onCreateGuidanceData", GlobalPositioningSystem.onCreateGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "onUpdateGuidanceData", GlobalPositioningSystem.onUpdateGuidanceData)
    SpecializationUtil.registerFunction(vehicleType, "onSteeringStateChanged", GlobalPositioningSystem.onSteeringStateChanged)
    SpecializationUtil.registerFunction(vehicleType, "onHeadlandStateChanged", GlobalPositioningSystem.onHeadlandStateChanged)
    SpecializationUtil.registerFunction(vehicleType, "setIsGuidanceSteeringEnabled", GlobalPositioningSystem.setIsGuidanceSteeringEnabled)
end

function GlobalPositioningSystem.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", GlobalPositioningSystem.inj_getIsVehicleControlledByPlayer)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", GlobalPositioningSystem.inj_getCanStartAIVehicle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowAIToggleActionEvent", GlobalPositioningSystem.inj_getCanStartAIVehicle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "onDynamicallyPartI3DLoaded", GlobalPositioningSystem.inj_onDynamicallyPartI3DLoaded)
end

function GlobalPositioningSystem.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", GlobalPositioningSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", GlobalPositioningSystem)
end

function GlobalPositioningSystem.registerEvents(vehicleType)
end

function GlobalPositioningSystem:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_globalPositioningSystem

        self:clearActionEventsTable(spec.actionEvents)

        if self:getIsActiveForInput(true, true) then
            if not self:getIsAIActive() and spec.hasGuidanceSystem then
                local nonDrawnActionEvents = {}
                local function insert(_, actionEventId)
                    table.insert(nonDrawnActionEvents, actionEventId)
                end

                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_SETPOINT, self, GlobalPositioningSystem.actionEventSetABPoint, false, true, false, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_SET_AUTO_WIDTH, self, GlobalPositioningSystem.actionEventSetAutoWidth, false, true, false, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_AXIS_WIDTH, self, GlobalPositioningSystem.actionEventWidth, false, true, true, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_ENABLE_STEERING, self, GlobalPositioningSystem.actionEventEnableSteering, false, true, false, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_AXIS_SHIFT, self, GlobalPositioningSystem.actionEventShift, false, true, true, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_AXIS_REALIGN, self, GlobalPositioningSystem.actionEventRealign, false, true, false, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_TOGGLE_LINE_DISPLAY, self, GlobalPositioningSystem.actionEventToggleLineDisplay, false, true, false, true, nil, nil, true))
                insert(self:addActionEvent(spec.actionEvents, InputAction.GS_ROTATE_TRACK, self, GlobalPositioningSystem.actionEventRotateTrack, false, true, false, true, nil, nil, true))

                for _, actionEventId in ipairs(nonDrawnActionEvents) do
                    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                end

                local _, actionEventIdToggleGS = self:addActionEvent(spec.actionEvents, InputAction.GS_TOGGLE, self, GlobalPositioningSystem.actionEventToggleGuidanceSteering, false, true, false, true, nil, nil, true)
                local _, actionEventIdToggleUI = self:addActionEvent(spec.actionEvents, InputAction.GS_SHOW_UI, self, GlobalPositioningSystem.actionEventOnToggleUI, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventIdToggleUI, false)
                g_inputBinding:setActionEventTextVisibility(actionEventIdToggleGS, true)
                g_inputBinding:setActionEventTextPriority(actionEventIdToggleUI, GS_PRIO_LOW)
                g_inputBinding:setActionEventTextPriority(actionEventIdToggleGS, GS_PRIO_LOW)
            end
        end
    end
end

function GlobalPositioningSystem:onLoad(savegame)
    local hasGuidanceSystem = true

    local configId = Utils.getNoNil(self.configurations.globalPositioningSystem, 1)
    if configId ~= nil then
        local item = g_storeManager:getItemByXMLFilename(self.configFileName)

        if item.configurations.globalPositioningSystem ~= nil then
            local config = item.configurations.globalPositioningSystem[configId]

            if config ~= nil then
                hasGuidanceSystem = config.enabled
                ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.globalPositioningSystemConfigurations.globalPositioningSystemConfiguration", configId, self.components, self)
            end
        end
    end

    if self.propertyState == Vehicle.PROPERTY_STATE_MISSION then
        hasGuidanceSystem = true
    end

    self.spec_globalPositioningSystem = self:guidanceSteering_getSpecTable("globalPositioningSystem")
    local spec = self.spec_globalPositioningSystem

    spec.hasGuidanceSystem = hasGuidanceSystem

    if not spec.hasGuidanceSystem then
        return
    end

    spec.axisAccelerate = 0
    spec.axisBrake = 0
    spec.axisForward = 0
    spec.axisForwardSent = 0

    -- Index is deprecated.
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.guidanceSteering#index", "vehicle.guidanceSteering#node")

    local rootNode = self.rootNode
    local guideNode = self.xmlFile:getValue("vehicle.guidanceSteering#node", nil, self.components, self.i3dMappings)
    if guideNode ~= nil then
        rootNode = guideNode
    end

    local function createGuideNode(name, isTarget)
        local node = createTransformGroup(name)
        link(rootNode, node)
        setTranslation(node, 0, 0, 0)
        if isTarget then
            setRotation(node, 0, math.rad(180), 0)
        end
        return node
    end

    if self.isClient then
        local xmlFile = loadXMLFile("GuidanceSounds", Utils.getFilename("resources/sounds.xml", g_currentMission.guidanceSteering.modDirectory))
        if xmlFile ~= nil then
            spec.samples = {}
            spec.samples.activate = g_soundManager:loadSampleFromXML(xmlFile, "sounds", "activate", g_currentMission.guidanceSteering.modDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
            spec.samples.deactivate = g_soundManager:loadSampleFromXML(xmlFile, "sounds", "deactivate", g_currentMission.guidanceSteering.modDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
            spec.samples.warning = g_soundManager:loadSampleFromXML(xmlFile, "sounds", "warning", g_currentMission.guidanceSteering.modDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

            spec.playHeadLandWarning = false
            spec.isHeadlandWarningSamplePlaying = false

            delete(xmlFile)
        end
    end

    spec.guidanceNode = createGuideNode("guidance_node", false)
    spec.guidanceTargetNode = createGuideNode("guidance_reverse_node", true)

    spec.lineStrategy = StraightABStrategy:new(self)
    spec.guidanceIsActive = false
    spec.guidanceSteeringIsActive = false
    spec.autoInvertOffset = false
    spec.shiftParallel = false

    spec.headlandMode = OnHeadlandState.MODES.OFF
    spec.headlandActDistance = OnHeadlandState.DEFAULT_ACT_DISTANCE

    spec.abDistanceCounter = 0

    spec.lastInputValues = {}
    spec.lastInputValues.guidanceIsActive = false
    spec.lastInputValues.guidanceSteeringIsActive = false
    spec.lastInputValues.autoInvertOffset = false
    spec.lastInputValues.shiftParallel = false
    spec.lastInputValues.shiftParallelValue = 0
    spec.lastInputValues.widthValue = 0
    spec.lastInputValues.widthIncrement = 0.1 -- no need to sync this.

    -- Shift control
    spec.shiftControl = {}
    spec.shiftControl.changeDelay = 250
    spec.shiftControl.changeCurrentDelay = 0
    spec.shiftControl.changeMultiplier = 1
    spec.shiftControl.forceFinalPush = false
    spec.shiftControl.snapDirectionSent = { 0, 0, 0, 0 }

    -- Width control
    spec.widthControl = {}
    spec.widthControl.changeDelay = 250
    spec.widthControl.changeCurrentDelay = 0
    spec.widthControl.forceFinalPush = false
    spec.widthControl.widthSent = GlobalPositioningSystem.DEFAULT_WIDTH

    spec.guidanceSteeringIsActiveSent = false
    spec.guidanceIsActiveSent = false
    spec.guidanceTerrainAngleIsActiveSent = false
    spec.shiftParallelSent = false
    spec.autoInvertOffsetSent = false

    spec.guidanceData = {}
    spec.guidanceData.width = GlobalPositioningSystem.DEFAULT_WIDTH
    spec.guidanceData.offsetWidth = 0
    spec.guidanceData.isReverseDriving = false
    spec.guidanceData.movingForwards = false
    spec.guidanceData.snapDirectionMultiplier = 1
    spec.guidanceData.alphaRad = 0
    spec.guidanceData.currentLane = 0
    spec.guidanceData.snapDirection = { 0, 0, 0, 0 }
    spec.guidanceData.driveTarget = { 0, 0, 0, 0, 0 }
    spec.guidanceData.isCreated = false

    if self.isClient then
        spec.guidanceData.lineDistance = 0
    end

    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.guidanceDirtyFlag = self:getNextDirtyFlag()

    GlobalPositioningSystem.registerMultiPurposeActionEvents(self)

    spec.stateMachine = FSMContext.createGuidanceStateMachine(self)
end

function GlobalPositioningSystem:onPostLoad(savegame)
    local spec = self.spec_globalPositioningSystem
    if spec.hasGuidanceSystem and savegame ~= nil then
        local key = savegame.key .. "." .. self:guidanceSteering_getModName() .. ".globalPositioningSystem"

        spec.lastInputValues.guidanceIsActive = savegame.xmlFile:getValue(key .. "#guidanceIsActive", spec.guidanceIsActive)
        spec.lastInputValues.autoInvertOffset = savegame.xmlFile:getValue(key .. "#autoInvertOffset", spec.autoInvertOffset)

        local data = spec.guidanceData
        data.lineDistance = savegame.xmlFile:getValue(key .. "#lineDistance", data.lineDistance)
    end
end

function GlobalPositioningSystem:onLoadFinished()
    local spec = self.spec_globalPositioningSystem
    if self.spec_dynamicallyLoadedParts ~= nil then
        for _, part in ipairs(self.spec_dynamicallyLoadedParts.parts) do
            -- linkNode field is set by the GlobalPositioningSystem code.
            if part.gpsLinkNode ~= nil then
                setVisibility(part.gpsLinkNode, spec.hasGuidanceSystem)
            end
        end
    end
end

function GlobalPositioningSystem:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_globalPositioningSystem

    if spec.hasGuidanceSystem then
        xmlFile:setValue(key .. "#guidanceIsActive", spec.guidanceIsActive)
        xmlFile:setValue(key .. "#autoInvertOffset", spec.autoInvertOffset)

        local data = spec.guidanceData
        xmlFile:setValue(key .. "#lineDistance", data.lineDistance)
    end
end

function GlobalPositioningSystem:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_globalPositioningSystem

        if spec.hasGuidanceSystem then
            if streamReadBool(streamId) then
                local data = GuidanceUtil.readGuidanceDataObject(streamId)

                -- sync guidance data
                self:updateGuidanceData(data, false, false, true)
            end

            -- sync settings
            self:setIsGuidanceSteeringEnabled(streamReadBool(streamId))
            spec.guidanceSteeringIsActive = streamReadBool(streamId)
            spec.autoInvertOffset = streamReadBool(streamId)
        end
    end
end

function GlobalPositioningSystem:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_globalPositioningSystem

        if spec.hasGuidanceSystem then
            local data = spec.guidanceData

            streamWriteBool(streamId, data.isCreated)
            if data.isCreated then
                -- sync guidance data
                GuidanceUtil.writeGuidanceDataObject(streamId, data)
            end

            -- sync settings
            streamWriteBool(streamId, spec.guidanceIsActive)
            streamWriteBool(streamId, spec.guidanceSteeringIsActive)
            streamWriteBool(streamId, spec.autoInvertOffset)
        end
    end
end

function GlobalPositioningSystem:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_globalPositioningSystem

    if spec.hasGuidanceSystem then
        if streamReadBool(streamId) then
            local guidanceSteeringIsActive = spec.guidanceSteeringIsActive

            self:setIsGuidanceSteeringEnabled(streamReadBool(streamId))
            spec.guidanceSteeringIsActive = streamReadBool(streamId)
            spec.autoInvertOffset = streamReadBool(streamId)
            spec.shiftParallel = streamReadBool(streamId)

            if guidanceSteeringIsActive ~= spec.guidanceSteeringIsActive then
                self:onSteeringStateChanged(spec.guidanceSteeringIsActive)
            end
        end

        if streamReadBool(streamId) then
            spec.axisForward = streamReadUIntN(streamId, 10) / 1023 * 2 - 1
            if math.abs(spec.axisForward) < 0.00099 then
                spec.axisForward = 0 -- set to 0 to avoid noise caused by compression
            end
        end

        if connection:getIsServer() then
            spec.playHeadLandWarning = streamReadBool(streamId)
        end
    end
end

function GlobalPositioningSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_globalPositioningSystem

    if spec.hasGuidanceSystem then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.guidanceIsActive)
            streamWriteBool(streamId, spec.guidanceSteeringIsActive)
            streamWriteBool(streamId, spec.autoInvertOffset)

            streamWriteBool(streamId, spec.shiftParallel)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.guidanceDirtyFlag) ~= 0) then
            local axisForward = (spec.axisForward + 1) / 2 * 1023
            streamWriteUIntN(streamId, axisForward, 10)
        end

        if not connection:getIsServer() then
            streamWriteBool(streamId, spec.playHeadLandWarning)
        end
    end
end

function GlobalPositioningSystem:onDelete()
    local spec = self.spec_globalPositioningSystem

    -- Cleanup current strategy
    spec.lineStrategy:delete()

    -- Delete guidance nodes
    delete(spec.guidanceNode)
    delete(spec.guidanceTargetNode)

    -- Remove sounds
    if self.isClient then
        g_soundManager:deleteSamples(spec.samples)
    end
end

function GlobalPositioningSystem.updateNetworkInputs(self)
    local spec = self.spec_globalPositioningSystem

    self:setIsGuidanceSteeringEnabled(spec.lastInputValues.guidanceIsActive)
    spec.guidanceSteeringIsActive = spec.lastInputValues.guidanceSteeringIsActive
    spec.autoInvertOffset = spec.lastInputValues.autoInvertOffset
    spec.shiftParallel = spec.lastInputValues.shiftParallel

    -- Reset
    spec.lastInputValues.shiftParallel = false

    local steeringChanged = spec.guidanceSteeringIsActive ~= spec.guidanceSteeringIsActiveSent
    if steeringChanged
        or spec.guidanceIsActive ~= spec.guidanceIsActiveSent
        or spec.autoInvertOffset ~= spec.autoInvertOffsetSent
        or spec.shiftParallel ~= spec.shiftParallelSent
        or spec.shiftParallelDirection ~= spec.shiftParallelDirectionSent
    then
        spec.guidanceSteeringIsActiveSent = spec.guidanceSteeringIsActive
        spec.guidanceIsActiveSent = spec.guidanceIsActive
        spec.autoInvertOffsetSent = spec.autoInvertOffset
        spec.shiftParallelSent = spec.shiftParallel
        spec.shiftParallelDirectionSent = spec.shiftParallelDirection

        if steeringChanged then
            self:onSteeringStateChanged(spec.guidanceSteeringIsActive)
        end

        self:raiseDirtyFlags(spec.dirtyFlag)
    end
end

---Updates the inputs which are triggered always
---@param self table
---@param dt number
function GlobalPositioningSystem.updateDelayedNetworkInputs(self, dt)
    local spec = self.spec_globalPositioningSystem
    local data = spec.guidanceData

    local lastShiftParallelValue = spec.lastInputValues.shiftParallelValue
    spec.lastInputValues.shiftParallelValue = 0

    local function pushUpdate()
        if spec.shiftControl.snapDirectionSent ~= data.snapDirection then
            self:updateGuidanceData(data, false, false)
        end
    end

    if lastShiftParallelValue ~= 0 then
        spec.shiftControl.changeCurrentDelay = spec.shiftControl.changeCurrentDelay - (dt * spec.shiftControl.changeMultiplier)
        spec.shiftControl.changeMultiplier = math.min(spec.shiftControl.changeMultiplier + (dt * GlobalPositioningSystem.INPUT_MULTIPLIER_STEP), GlobalPositioningSystem.MAX_INPUT_MULTIPLIER)

        if spec.shiftControl.changeCurrentDelay < 0 then
            spec.shiftControl.changeCurrentDelay = spec.shiftControl.changeDelay

            local dir = MathUtil.sign(lastShiftParallelValue)
            GlobalPositioningSystem.shiftTrackParallel(data, dt, dir)

            spec.shiftControl.forceFinalPush = true
        end
    else
        spec.shiftControl.changeCurrentDelay = 0
        spec.shiftControl.changeMultiplier = 1

        if spec.shiftControl.forceFinalPush then
            spec.shiftControl.forceFinalPush = false
            pushUpdate()
        end
    end

    local lastWidthValue = spec.lastInputValues.widthValue
    spec.lastInputValues.widthValue = 0

    if lastWidthValue ~= 0 then
        spec.widthControl.changeCurrentDelay = spec.widthControl.changeCurrentDelay - (dt * 1)

        if spec.widthControl.changeCurrentDelay < 0 then
            spec.widthControl.changeCurrentDelay = spec.widthControl.changeDelay

            local dir = MathUtil.sign(lastWidthValue)
            local width = data.width + (spec.lastInputValues.widthIncrement * dir)

            data.width = width

            spec.widthControl.forceFinalPush = true
        end
    else
        spec.widthControl.changeCurrentDelay = 0
        if spec.widthControl.forceFinalPush then
            spec.widthControl.forceFinalPush = false
            pushUpdate()
        end
    end
end

function GlobalPositioningSystem:onUpdate(dt)
    local spec = self.spec_globalPositioningSystem
    local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

    -- We don't update when no player is in the vehicle
    if not spec.hasGuidanceSystem or not isControlled then
        return
    end

    local hasGuidanceSystem = self:getHasGuidanceSystem()
    if self.isClient then
        if self.getIsEntered ~= nil and self:getIsEntered() then
            if hasGuidanceSystem then
                local guidanceSteeringIsActive = spec.lastInputValues.guidanceSteeringIsActive
                if guidanceSteeringIsActive and self:getIsActiveForInput(true, true) then
                    spec.axisForward = MathUtil.clamp((spec.axisAccelerate - spec.axisBrake), -1, 1)
                else
                    spec.axisForward = 0
                end

                spec.axisAccelerate = 0
                spec.axisBrake = 0

                -- Do network update
                if spec.axisForward ~= spec.axisForwardSent then
                    spec.axisForwardSent = spec.axisForward
                    self:raiseDirtyFlags(spec.guidanceDirtyFlag)
                end

                GlobalPositioningSystem.updateDelayedNetworkInputs(self, dt)
            end

            GlobalPositioningSystem.updateNetworkInputs(self)
        end
    end

    if not hasGuidanceSystem then
        return
    end

    local data = spec.guidanceData
    local guidanceNode = spec.guidanceNode
    local lastSpeed = self:getLastSpeed()

    spec.lineStrategy:update(dt, data, guidanceNode, lastSpeed)

    local drivingDirection = self:getDrivingDirection()
    local guidanceSteeringIsActive = spec.guidanceSteeringIsActive
    local x, _, z, driveDirX, driveDirZ = unpack(data.driveTarget)

    -- Only compute when the vehicle is moving
    if drivingDirection ~= 0 or spec.shiftParallel then
        if spec.lineStrategy:getHasABDependentDirection() then
            local distance = self.lastMovedDistance
            spec.abDistanceCounter = spec.abDistanceCounter + distance
        end

        data.movingForwards = self:getIsDrivingForward()

        GlobalPositioningSystem.computeGuidanceTarget(self)

        local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)

        if data.width ~= 0 then
            local lineAlpha = GuidanceUtil.getAProjectOnLineParameter(z, x, lineZ, lineX, lineDirX, lineDirZ) / data.width
            data.currentLane = MathUtil.round(lineAlpha)
            data.alphaRad = lineAlpha - data.currentLane
        end

        -- Todo: straight strategy prob needs this?
        local dirX, _, dirZ = localDirectionToWorld(guidanceNode, worldDirectionToLocal(guidanceNode, lineDirX, 0, lineDirZ))
        --                local dirX, dirZ = lineDirX, lineDirZ

        local dot = MathUtil.clamp(driveDirX * dirX + driveDirZ * dirZ, GlobalPositioningSystem.DIRECTION_LEFT, GlobalPositioningSystem.DIRECTION_RIGHT) -- dot towards point
        local angle = math.acos(dot)

        local snapDirectionMultiplier = 1
        if angle < 1.5708 then
            -- If smaller than 90 deg we swap
            snapDirectionMultiplier = -snapDirectionMultiplier
        end

        local spec_reverseDriving = self.spec_reverseDriving

        data.snapDirectionMultiplier = snapDirectionMultiplier
        data.isReverseDriving = spec_reverseDriving ~= nil and not spec_reverseDriving.isChangingDirection and spec_reverseDriving.isReverseDriving

        if data.isReverseDriving then
            data.snapDirectionMultiplier = -data.snapDirectionMultiplier
        end
    end

    if not self.isServer then
        return
    end

    if guidanceSteeringIsActive then
        spec.stateMachine:update(dt)
    end
end

function GlobalPositioningSystem:onUpdateTick(dt)
    local spec = self.spec_globalPositioningSystem

    if self.isClient then
        GlobalPositioningSystem.updateSounds(self, spec, dt)
    end
end

function GlobalPositioningSystem:onDraw()
    if not self.isClient
        or not self:getHasGuidanceSystem() then
        return
    end

    if g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled() then
        local spec = self.spec_globalPositioningSystem
        spec.lineStrategy:draw(spec.guidanceData, spec.guidanceSteeringIsActive, spec.autoInvertOffset)
    end
end

function GlobalPositioningSystem.inj_getIsVehicleControlledByPlayer(vehicle, superFunc)
    local spec = vehicle.spec_globalPositioningSystem
    if spec ~= nil and spec.guidanceSteeringIsActive then
        return false
    end

    return superFunc(vehicle)
end

function GlobalPositioningSystem.inj_getCanStartAIVehicle(vehicle, superFunc)
    local spec = vehicle.spec_globalPositioningSystem
    if spec.guidanceSteeringIsActive then
        return false
    end

    return superFunc(vehicle)
end

function GlobalPositioningSystem.inj_onDynamicallyPartI3DLoaded(vehicle, superFunc, i3dNode, failedReason, args)
    local xmlFile, partKey, dynamicallyLoadedPart = unpack(args)

    local function isSharedStarFire(path)
        local matches = {
            ["data/shared/assets/starfire.i3d"] = true,
            ["data/shared/assets/gps.i3d"] = true
        }
        return matches[path:lower()] ~= nil
    end

    if isSharedStarFire(dynamicallyLoadedPart.filename) then
        dynamicallyLoadedPart.gpsLinkNode = xmlFile:getValue(partKey .. "#linkNode", "0>", vehicle.components, vehicle.i3dMappings)
    end

    return superFunc(vehicle, i3dNode, failedReason, args)
end

function GlobalPositioningSystem:onPostAttachImplement()
    if self.isClient then
        local spec = self.spec_globalPositioningSystem

        if spec.hasGuidanceSystem then
            local length = self.size.length
            local function toLength(implement)
                local object = implement.object
                return object ~= nil and object.size.length or 0
            end

            local lengths = stream(self:getAttachedImplements()):map(toLength):toList()
            length = stream(lengths):reduce(self.size.length, function(r, e)
                return r + e
            end)

            spec.guidanceData.lineDistance = length
        end
    end
end

function GlobalPositioningSystem.getActualWorkWidth(guidanceNode, object)
    local width, offset = GuidanceUtil.getMaxWorkAreaWidth(object)

    for _, implement in pairs(object:getAttachedImplements()) do
        if implement.object ~= nil then
            local implementWidth, implementOffset = GlobalPositioningSystem.getActualWorkWidth(guidanceNode, implement.object)

            width = math.max(width, implementWidth)
            if implementOffset < 0 then
                offset = math.min(offset, implementOffset)
            else
                offset = math.max(offset, implementOffset)
            end
        end
    end

    return width, offset
end

function GlobalPositioningSystem:getHasGuidanceSystem()
    local spec = self.spec_globalPositioningSystem
    return spec.hasGuidanceSystem and spec.guidanceIsActive
end

function GlobalPositioningSystem:setGuidanceStrategy(method, noEventSend)
    GuidanceStrategyChangedEvent.sendEvent(self, method, noEventSend)

    local spec = self.spec_globalPositioningSystem
    spec.lineStrategy:delete()
    spec.multiActionEvent:reset()

    if method == ABStrategy.AB then
        spec.lineStrategy = StraightABStrategy:new(self)
    elseif method == ABStrategy.A_PLUS_HEADING then
        spec.lineStrategy = CardinalStrategy:new(self)
    end
end

function GlobalPositioningSystem:getGuidanceStrategy()
    local spec = self.spec_globalPositioningSystem
    return spec.lineStrategy
end

function GlobalPositioningSystem:interactWithGuidanceStrategy(noEventSend)
    StrategyInteractEvent.sendEvent(self, noEventSend)

    local spec = self.spec_globalPositioningSystem
    spec.lineStrategy:interact(spec.guidanceData)
end

function GlobalPositioningSystem:getGuidanceData()
    local spec = self.spec_globalPositioningSystem
    return spec.guidanceData
end

---updateGuidanceData
---@param guidanceData table
---@param isCreation boolean
---@param isReset boolean
---@param noEventSend boolean
function GlobalPositioningSystem:updateGuidanceData(guidanceData, isCreation, isReset, noEventSend)
    GuidanceDataChangedEvent.sendEvent(self, guidanceData, isCreation, isReset, noEventSend)

    if isCreation then
        self:onCreateGuidanceData()
        self:onUpdateGuidanceData(guidanceData)
    elseif isReset then
        self:onResetGuidanceData()
    else
        self:onUpdateGuidanceData(guidanceData)
    end
end

function GlobalPositioningSystem.computeGuidanceTarget(self)
    local spec = self.spec_globalPositioningSystem
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


    --local driveDirX, driveDirZ = AIVehicleUtil.getDriveDirection(guidanceNode, dirX, transY, dirZ)
    local driveDirX, driveDirZ = GuidanceUtil.getDriveDirection(dirX, dirZ)
    if not data.movingForwards then
        driveDirX, driveDirZ = -driveDirX, -driveDirZ
    end

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
    local spec = self.spec_globalPositioningSystem
    local data = spec.guidanceData

    local guidanceNode = spec.guidanceTargetNode

    local transX, transY, transZ = unpack(data.driveTarget)
    local dirX, _, dirZ = localDirectionToWorld(guidanceNode, 0, 0, 1)

    if spec.lineStrategy:getHasABDependentDirection()
        and spec.lineStrategy:getIsABDirectionPossible() then
        if not data.movingForwards then
            guidanceNode = spec.guidanceNode -- inverse line
        end

        local strategyData = spec.lineStrategy:getGuidanceData(guidanceNode, data)
        transX, transY, transZ, dirX, dirZ = unpack(strategyData)
    end

    local angleRad = MathUtil.getYRotationFromDirection(dirX, dirZ)
    -- Snap to terrain when settings is active
    if g_currentMission.guidanceSteering:isTerrainAngleSnapEnabled() then
        local snapAngle = math.max(self:getDirectionSnapAngle(), math.pi / (g_currentMission.fieldGroundSystem:getGroundAngleMaxValue() + 1))
        angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
    end

    dirX, dirZ = math.sin(angleRad), math.cos(angleRad)

    local x = transX + data.snapDirectionMultiplier * data.offsetWidth * dirZ
    local z = transZ - data.snapDirectionMultiplier * data.offsetWidth * dirX

    -- Line direction and translation xz axis
    data.snapDirection = {
        dirX,
        dirZ,
        x,
        z
    }

    self:updateGuidanceData(data, true, false)
end

function GlobalPositioningSystem:onCreateGuidanceData()
    local spec = self.spec_globalPositioningSystem

    -- Reset distance counter
    spec.abDistanceCounter = 0
    -- Delete AB points
    spec.lineStrategy:delete()

    local data = spec.guidanceData
    data.isCreated = true
end

function GlobalPositioningSystem:onResetGuidanceData()
    local spec = self.spec_globalPositioningSystem

    -- Reset distance counter
    spec.abDistanceCounter = 0
    -- Delete AB points
    spec.lineStrategy:delete()

    local data = spec.guidanceData
    data.isCreated = false
    data.snapDirection = { 0, 0, 0, 0 }

    if self.isServer then
        spec.stateMachine:reset()
    end

    spec.lastInputValues.guidanceSteeringIsActive = false
end

function GlobalPositioningSystem:onUpdateGuidanceData(guidanceData)
    if guidanceData == nil then
        return
    end

    local spec = self.spec_globalPositioningSystem
    local data = spec.guidanceData
    data.width = Utils.getNoNil(guidanceData.width, GlobalPositioningSystem.DEFAULT_WIDTH)
    data.offsetWidth = Utils.getNoNil(guidanceData.offsetWidth, GlobalPositioningSystem.DEFAULT_OFFSET)
    data.snapDirectionMultiplier = guidanceData.snapDirectionMultiplier
    data.snapDirection = guidanceData.snapDirection
    data.alphaRad = guidanceData.alphaRad

    if self.isServer then
        spec.stateMachine:reset()
    end
end

function GlobalPositioningSystem:onSteeringStateChanged(isActive)
    local spec = self.spec_globalPositioningSystem

    if self.isServer then
        spec.stateMachine:reset()
    end

    if self.isClient then
        local sample = spec.samples.activate
        if not isActive then
            sample = spec.samples.deactivate
        end

        g_soundManager:playSample(sample)
    end
end

---Called when headland mode or acting distance changed.
---@param headlandMode number
---@param headlandActDistance number
function GlobalPositioningSystem:onHeadlandStateChanged(headlandMode, headlandActDistance)
    local spec = self.spec_globalPositioningSystem

    spec.headlandMode = headlandMode
    spec.headlandActDistance = headlandActDistance

    if self.isServer then
        spec.stateMachine:requestStateUpdate()
    end
end

function GlobalPositioningSystem:setIsGuidanceSteeringEnabled(isEnabled)
    local spec = self.spec_globalPositioningSystem
    spec.guidanceIsActive = isEnabled

    if spec.actionEvents ~= nil then
        local actionEvent = spec.actionEvents[InputAction.GS_SHOW_UI]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, isEnabled)
        end
    end
end

---Shifts the created track parallel
---@param data table
---@param dt number
---@param direction number
function GlobalPositioningSystem.shiftTrackParallel(data, dt, direction)
    local snapFactor = Utils.getNoNil(data.snapDirectionMultiplier, 1.0)
    local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)

    local dirX, dirZ = lineDirX, lineDirZ
    if (math.abs(dirX) - math.abs(dirZ)) < 0.00001 then
        dirX = dirX + 1 -- avoid multiply by 0.
    end

    lineX = lineX + ((snapFactor * dt * 0.001 * dirZ) * direction)
    lineZ = lineZ + ((snapFactor * dt * 0.001 * dirX) * direction)

    data.snapDirection = { lineDirX, lineDirZ, lineX, lineZ }
end

---Realigns the created track to the current drive target
---@param self table
---@param data table
function GlobalPositioningSystem.realignTrack(self, data)
    local snapFactor = Utils.getNoNil(data.snapDirectionMultiplier, 1.0)
    local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)
    local transX, _, transZ = unpack(data.driveTarget)

    lineX = transX + snapFactor * data.offsetWidth * lineDirZ
    lineZ = transZ - snapFactor * data.offsetWidth * lineDirX

    data.snapDirection = { lineDirX, lineDirZ, lineX, lineZ }

    self:updateGuidanceData(data, false, false)
end

---Rotates the created track 90 degrees.
---@param self table
---@param data table
function GlobalPositioningSystem.rotateTrack(self, data)
    local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)

    local dirX = -lineDirZ
    local dirZ = lineDirX

    data.snapDirection = { dirX, dirZ, lineX, lineZ }

    self:updateGuidanceData(data, false, false)
end

function GlobalPositioningSystem.updateSounds(self, spec, dt)
    if self == g_currentMission.controlledVehicle then
        if spec.playHeadLandWarning then
            if not spec.isHeadlandWarningSamplePlaying then
                g_soundManager:playSample(spec.samples.warning)
                spec.isHeadlandWarningSamplePlaying = true
            end
        else
            if spec.isHeadlandWarningSamplePlaying then
                g_soundManager:stopSample(spec.samples.warning)
                spec.isHeadlandWarningSamplePlaying = false
            end
        end
    end
end

--- Action events

function GlobalPositioningSystem.actionEventRotateTrack(self, actionName, inputValue, callbackState, isAnalog)
    local data = self:getGuidanceData()
    if not data.isCreated then
        self:setWarningMessage(g_i18n:getText("guidanceSteering_tooltip_trackIsNotCreated"))
        return
    end

    GlobalPositioningSystem.rotateTrack(self, data)
end

function GlobalPositioningSystem.actionEventToggleLineDisplay(self, actionName, inputValue, callbackState, isAnalog)
    if g_currentMission.guidanceSteering ~= nil then
        local isShowGuidanceLinesEnabled = g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled()
        g_currentMission.guidanceSteering:setIsShowGuidanceLinesEnabled(not isShowGuidanceLinesEnabled)
    end
end

function GlobalPositioningSystem.actionEventToggleGuidanceSteering(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_globalPositioningSystem

    spec.lastInputValues.guidanceIsActive = not spec.lastInputValues.guidanceIsActive

    -- Force stop guidance
    spec.lastInputValues.guidanceSteeringIsActive = false
end

function GlobalPositioningSystem.actionEventOnToggleUI(self, actionName, inputValue, callbackState, isAnalog)
    if not self.isClient then
        return
    end

    if self:getHasGuidanceSystem() and self == g_currentMission.controlledVehicle then
        g_currentMission.guidanceSteering.ui:onToggleUI()
    end
end

function GlobalPositioningSystem.actionEventSetAutoWidth(self, actionName, inputValue, callbackState, isAnalog)
    if not self:getHasGuidanceSystem() then
        return
    end

    local spec = self.spec_globalPositioningSystem
    local data = spec.guidanceData
    local width, offset = GlobalPositioningSystem.getActualWorkWidth(spec.guidanceNode, self)
    data.width = width
    data.offsetWidth = offset
    self:updateGuidanceData(data, false, false)
end

function GlobalPositioningSystem.actionEventWidth(self, actionName, inputValue, callbackState, isAnalog)
    if not self:getHasGuidanceSystem() then
        return
    end

    local spec = self.spec_globalPositioningSystem

    spec.lastInputValues.widthValue = inputValue
end

function GlobalPositioningSystem.actionEventShift(self, actionName, inputValue, callbackState, isAnalog)
    if not self:getHasGuidanceSystem() then
        return
    end

    local spec = self.spec_globalPositioningSystem
    spec.lastInputValues.shiftParallel = true
    spec.lastInputValues.shiftParallelValue = inputValue
end

function GlobalPositioningSystem.actionEventRealign(self, actionName, inputValue, callbackState, isAnalog)
    if not self:getHasGuidanceSystem() then
        return
    end

    local data = self:getGuidanceData()

    if not data.isCreated then
        g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_createTrackFirst"), 2000)
        return
    end

    GlobalPositioningSystem.realignTrack(self, data)
end

function GlobalPositioningSystem.actionEventSetABPoint(self, actionName, inputValue, callbackState, isAnalog)
    if not self:getHasGuidanceSystem() then
        return
    end

    local spec = self.spec_globalPositioningSystem

    spec.multiActionEvent:handle()
end

function GlobalPositioningSystem.actionEventEnableSteering(self, actionName, inputValue, callbackState, isAnalog)
    if not self:getHasGuidanceSystem() then
        return
    end

    local spec = self.spec_globalPositioningSystem
    self.spec_drivable.allowPlayerControl = self.guidanceSteeringIsActive

    if spec.guidanceData.width <= 0 then
        g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_setWidth"), 2000)
        return
    end

    if not spec.guidanceData.isCreated then
        g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_createTrackFirst"), 2000)
        return
    end

    spec.lastInputValues.guidanceSteeringIsActive = not spec.lastInputValues.guidanceSteeringIsActive
end

function GlobalPositioningSystem.registerMultiPurposeActionEvents(self)
    local spec = self.spec_globalPositioningSystem
    local event = MultiPurposeActionEvent:new(3)

    event:addAction(function()
        self:updateGuidanceData(nil, false, true)
        return true
    end)

    event:addAction(function()
        if spec.guidanceData.width <= 0 then
            g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_setWidth"), 2000)
            return false
        end

        self:interactWithGuidanceStrategy()

        return true
    end)

    event:addAction(function()
        if spec.guidanceData.width <= 0 then
            g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_setWidth"), 2000)
            return false
        end

        if spec.lineStrategy:needsDrivingDistanceThreshold() then
            if spec.abDistanceCounter < GlobalPositioningSystem.AB_DROP_DISTANCE then
                g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_dropDistance"):format(spec.abDistanceCounter), 4000)
                return false
            end
        end

        self:interactWithGuidanceStrategy()

        GlobalPositioningSystem.computeGuidanceDirection(self)

        return true
    end)

    spec.multiActionEvent = event
end
