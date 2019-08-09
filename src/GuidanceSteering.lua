---
-- GuidanceSteering
--
-- Main class for Guidance Steering
--
-- Copyright (c) Wopster, 2019

GuidanceSteering = {}

GuidanceSteering.SEND_NUM_BITS = 7 -- 2 ^ 7 = 128 max
GuidanceSteering.MAX_NUM_TRACKS = 2 ^ GuidanceSteering.SEND_NUM_BITS

local GuidanceSteering_mt = Class(GuidanceSteering)

function GuidanceSteering:new(mission, modDirectory, modName, i18n, gui, inputManager, messageCenter)
    local self = {}

    setmetatable(self, GuidanceSteering_mt)

    self:mergeModTranslations(i18n)

    self.isServer = mission:getIsServer()
    self.isClient = mission:getIsClient()

    self.mission = mission

    self.modDirectory = modDirectory
    self.modName = modName
    self.savedTracks = {}
    self.listeners = {}

    self.ui = GuidanceSteeringUI:new(mission, i18n, modDirectory, gui, inputManager, messageCenter)

    BaseMission.onEnterVehicle = Utils.appendedFunction(BaseMission.onEnterVehicle, GuidanceSteering.onEnterVehicle)
    BaseMission.onLeaveVehicle = Utils.appendedFunction(BaseMission.onLeaveVehicle, GuidanceSteering.onLeaveVehicle)

    return self
end

function GuidanceSteering:delete()
    self.ui:delete()
end

function GuidanceSteering:onMissionLoadFromSavegame(xmlFile)
    self.showGuidanceLines = Utils.getNoNil(getXMLBool(xmlFile, "guidanceSteering.settings.showGuidanceLines"), true)
    self.guidanceTerrainAngleIsActive = Utils.getNoNil(getXMLBool(xmlFile, "guidanceSteering.settings.guidanceTerrainAngleIsActive"), true)

    local i = 0
    while true do
        local key = ("guidanceSteering.tracks.track(%d)"):format(i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end

        local track = {}

        track.name = getXMLString(xmlFile, key .. "#name")
        track.strategy = getXMLInt(xmlFile, key .. "#strategy")
        track.method = getXMLInt(xmlFile, key .. "#method")

        track.guidanceData = {}
        track.guidanceData.width = Utils.getNoNil(MathUtil.round(getXMLFloat(xmlFile, key .. ".guidanceData#width"), 3), GlobalPositioningSystem.DEFAULT_WIDTH)
        track.guidanceData.offsetWidth = Utils.getNoNil(MathUtil.round(getXMLFloat(xmlFile, key .. ".guidanceData#offsetWidth"), 3), GlobalPositioningSystem.DEFAULT_OFFSET)
        track.guidanceData.snapDirection = { StringUtil.getVectorFromString(getXMLString(xmlFile, key .. ".guidanceData#snapDirection")) }
        track.guidanceData.driveTarget = { StringUtil.getVectorFromString(getXMLString(xmlFile, key .. ".guidanceData#driveTarget")) }

        ListUtil.addElementToList(self.savedTracks, track)

        i = i + 1
    end
end

function GuidanceSteering:onMissionLoaded(mission)
    self.ui:load()
end

function GuidanceSteering:onMissionSaveToSavegame(xmlFile)
    setXMLInt(xmlFile, "guidanceSteering#version", 1)

    setXMLBool(xmlFile, "guidanceSteering.settings.showGuidanceLines", self.showGuidanceLines)
    setXMLBool(xmlFile, "guidanceSteering.settings.guidanceTerrainAngleIsActive", self.guidanceTerrainAngleIsActive)

    if self.savedTracks ~= nil then
        for i, track in ipairs(self.savedTracks) do
            local key = ("guidanceSteering.tracks.track(%d)"):format(i - 1)

            setXMLInt(xmlFile, key .. "#id", i)
            setXMLString(xmlFile, key .. "#name", track.name)
            setXMLInt(xmlFile, key .. "#strategy", track.strategy)
            setXMLInt(xmlFile, key .. "#method", track.method)
            setXMLFloat(xmlFile, key .. ".guidanceData#width", track.guidanceData.width)
            setXMLFloat(xmlFile, key .. ".guidanceData#offsetWidth", track.guidanceData.offsetWidth)
            setXMLString(xmlFile, key .. ".guidanceData#snapDirection", table.concat(track.guidanceData.snapDirection, " "))
            setXMLString(xmlFile, key .. ".guidanceData#driveTarget", table.concat(track.guidanceData.driveTarget, " "))
        end
    end
end

function GuidanceSteering:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local numTracks = streamReadUIntN(streamId, GuidanceSteering.SEND_NUM_BITS) + 1

        for i = 1, numTracks do
            local track = {}
            track.name = streamReadString(streamId)
            track.strategy = streamReadUIntN(streamId, 2)
            track.method = streamReadUIntN(streamId, 2)

            track.guidanceData = GuidanceUtil.readGuidanceDataObject(streamId)

            self.savedTracks[i] = track
            Logger.info(i, track)
        end
    end
end

function GuidanceSteering:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUIntN(streamId, #self.savedTracks - 1, GuidanceSteering.SEND_NUM_BITS)

        for _, track in ipairs(self.savedTracks) do
            streamWriteString(streamId, track.name)
            streamWriteUIntN(streamId, track.strategy, 2)
            streamWriteUIntN(streamId, track.method, 2)

            GuidanceUtil.writeGuidanceDataObject(streamId, track.guidanceData)
        end
    end
end

function GuidanceSteering:update(dt)
end

function GuidanceSteering:draw(dt)
end

---Add listener
---@param listener table
function GuidanceSteering:subscribe(listener)
    if not ListUtil.hasListElement(self.listeners, listener) then
        ListUtil.addElementToList(self.listeners, listener)
    end
end

---Remove listener
---@param listener table
function GuidanceSteering:unsubscribe(listener)
    ListUtil.removeElementFromList(self.listeners, listener)
end

---Notify listeners on track change
---@param id number
function GuidanceSteering:onTrackChanged(id)
    for _, listener in pairs(self.listeners) do
        listener:onTrackChanged(id)
    end
end

---Private method to create a new track
---@param id number
---@param data table
local function _createTrack(self, id, data)
    Logger.info("Creating track: " .. id, data.name)

    if id > GuidanceSteering.MAX_NUM_TRACKS then
        Logger.warning(("Maximum of %s saved tracks reached!"):format(GuidanceSteering.MAX_NUM_TRACKS))
        return
    end

    local entry = ListUtil.copyTable(data)
    entry.farmId = 0 -- Todo: make tracks farm dependent

    if not ListUtil.hasListElement(self.savedTracks, entry) then
        ListUtil.addElementToList(self.savedTracks, entry)

        -- Sort by name
        table.sort(self.savedTracks, function(lhs, rhs)
            return lhs.name < rhs.name
        end)

        -- Call listeners
        self:onTrackChanged(id)
    end
end

---Private method to save a track
---@param id number
---@param data table
local function _saveTrack(self, id, data)
    Logger.info("Saving " .. id .. " with track data: ", data)
    local track = self:getTrack(id)

    if track.name ~= data.name then
        track.name = data.name
    end

    track.strategy = data.strategy
    track.method = data.method
    track.guidanceData.width = data.guidanceData.width
    track.guidanceData.offsetWidth = data.guidanceData.offsetWidth
    track.guidanceData.snapDirection = data.guidanceData.snapDirection
    track.guidanceData.driveTarget = data.guidanceData.driveTarget

    -- Call listeners
    self:onTrackChanged(id)
end

---Facade to handle saving or creating tracks
---@param id number
---@param data table
function GuidanceSteering:saveTrack(id, data)
    if self:hasTrack(id) then
        _saveTrack(self, id, data)
    else
        _createTrack(self, id, data)
    end
end

---Deletes the track at the given index
---@param id number
function GuidanceSteering:deleteTrack(id)
    local entry = self:getTrack(id)

    if entry ~= nil then
        Logger.info("Deleting track: ", id)

        ListUtil.removeElementFromList(self.savedTracks, entry)

        -- Call listeners
        self:onTrackChanged(ListUtil.size(self.savedTracks))
    end
end

---Gets the track table by the given index
---@param id number
function GuidanceSteering:getTrack(id)
    return self.savedTracks[id]
end

---Return true if the track exits, false otherwise
---@param id number
function GuidanceSteering:hasTrack(id)
    return self.savedTracks[id] ~= nil
end

---Returns the next index
function GuidanceSteering:getNewTrackId()
    return ListUtil.size(self.savedTracks) + 1
end

---Checks if the current track is valid to load
---@param id number
function GuidanceSteering:isTrackValid(id)
    local track = self:getTrack(id)

    if track == nil then
        return false
    end

    local valid = true
    local nInvalid = 0
    for _, dir in ipairs(track.guidanceData.snapDirection) do
        valid = valid and dir ~= 0 or nInvalid < 2
        -- x and z directions can be 0 degrees.
        if not valid then
            nInvalid = nInvalid + 1
        end
    end

    -- Some direction can be 0 when position is perfectly straight, but when multiple are 0 the direction is not set.
    return valid
end

---Checks if the given name exists on a different track
---@param id number
---@param name string
function GuidanceSteering:isExistingTrack(id, name)
    for trackId, track in pairs(self.savedTracks) do
        if trackId ~= id and track.name == name then
            return true
        end
    end

    return false
end

function GuidanceSteering:isShowGuidanceLinesEnabled()
    return self.showGuidanceLines
end

function GuidanceSteering:setIsShowGuidanceLinesEnabled(enabled)
    self.showGuidanceLines = enabled
end

function GuidanceSteering:isGuidanceEnabled()
    return self.guidanceIsActive
end

function GuidanceSteering:setIsGuidanceEnabled(enabled)
    self.guidanceIsActive = enabled
end

function GuidanceSteering:isTerrainAngleSnapEnabled()
    return self.guidanceTerrainAngleIsActive
end

function GuidanceSteering:setIsTerrainAngleSnapEnabled(enabled)
    self.guidanceTerrainAngleIsActive = enabled
end

function GuidanceSteering:isAutoInvertOffsetEnabled()
    return self.autoInvertOffset
end

function GuidanceSteering:setIsAutoInvertOffsetEnabled(enabled)
    self.autoInvertOffset = enabled
end

---Set the current vehicle for the GS GUI.
function GuidanceSteering:onEnterVehicle()
    if self:getIsClient() then
        local vehicle = self.controlledVehicle
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        local hasGuidanceSystem = spec ~= nil and spec.hasGuidanceSystem

        if hasGuidanceSystem then
            local gui = g_guidanceSteering.ui
            gui:setVehicle(vehicle)
        end
    end
end

---Set remove the vehicle from the GS GUI.
function GuidanceSteering:onLeaveVehicle()
    if self:getIsClient() then
        local gui = g_guidanceSteering.ui
        gui:setVehicle(nil)
    end
end

function GuidanceSteering.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
    specializationManager:addSpecialization("globalPositioningSystem", "GlobalPositioningSystem", Utils.getFilename("src/vehicles/GlobalPositioningSystem.lua", modDirectory), nil) -- Nil is important here

    for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
        if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) and
                not SpecializationUtil.hasSpecialization(SplineVehicle, typeEntry.specializations) then
            vehicleTypeManager:addSpecialization(typeName, modName .. ".globalPositioningSystem")
        end
    end

    Drivable.actionEventAccelerate = Utils.overwrittenFunction(Drivable.actionEventAccelerate, GuidanceSteering.actionEventAccelerate)
    Drivable.actionEventBrake = Utils.overwrittenFunction(Drivable.actionEventBrake, GuidanceSteering.actionEventBrake)
    Drivable.actionEventSteer = Utils.overwrittenFunction(Drivable.actionEventSteer, GuidanceSteering.actionEventSteer)
end

function GuidanceSteering.actionEventAccelerate(vehicle, superFunc, actionName, inputValue, ...)
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec ~= nil and vehicle:getHasGuidanceSystem() and spec.guidanceSteeringIsActive then
        spec.axisAccelerate = MathUtil.clamp(inputValue, 0, 1)
    end

    superFunc(vehicle, actionName, inputValue, ...)
end

function GuidanceSteering.actionEventBrake(vehicle, superFunc, actionName, inputValue, ...)
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec ~= nil and vehicle:getHasGuidanceSystem() and spec.guidanceSteeringIsActive then
        spec.axisBrake = MathUtil.clamp(inputValue, 0, 1)
    end

    superFunc(vehicle, actionName, inputValue, ...)
end

function GuidanceSteering.actionEventSteer(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog, ...)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog, ...)

    if inputValue ~= 0 then
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        if spec ~= nil and vehicle:getHasGuidanceSystem() and spec.lastInputValues.guidanceSteeringIsActive then
            if not isAnalog then
                spec.lastInputValues.guidanceSteeringIsActive = false
            else
                -- When dealing with a controller or steering wheel look at the input value.
                spec.lastInputValues.guidanceSteeringIsActive = not (math.abs(inputValue) > 0.5)
            end

            if not spec.lastInputValues.guidanceSteeringIsActive then
                vehicle:onSteeringStateChanged(false)
            end
        end
    end
end

-- Thanks to Jos
-- Ripped from Seasons
function GuidanceSteering:mergeModTranslations(i18n)
    -- We can copy all our translations to the global table because we prefix everything with guidanceSteering_
    -- The mod-based l10n lookup only really works for vehicles, not UI and script mods.
    local global = getfenv(0).g_i18n.texts
    for key, text in pairs(i18n.texts) do
        global[key] = text
    end
end
