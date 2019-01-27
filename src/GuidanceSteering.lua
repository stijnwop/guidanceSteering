GuidanceSteering = {}

local GuidanceSteering_mt = Class(GuidanceSteering)

function GuidanceSteering:new(mission, modDirectory, modName, i18n, gui, inputManager, messageCenter, settingsModel)
    local self = {}

    setmetatable(self, GuidanceSteering_mt)

    self:mergeModTranslations(i18n)

    self.isServer = mission:getIsServer()
    self.modDirectory = modDirectory
    self.modName = modName
    self.savedTracks = {}

    self.ui = GuidanceSteeringUI:new(mission, i18n, modDirectory, gui, inputManager, messageCenter, settingsModel)

    return self
end

function GuidanceSteering:delete()
    self.ui:delete()
end

function GuidanceSteering:onMissionLoaded(mission)
    self.ui:load()
end

function GuidanceSteering:onMissionSaveToSavegame(xmlFile)
    setXMLInt(xmlFile, "guidanceSteering#version", 1)

    if self.savedTracks ~= nil then
        for i, track in ipairs(self.savedTracks) do
            local key = ("guidanceSteering.tracks.track(%d)"):format(i - 1)
            setXMLInt(xmlFile, key .. "#id", i)
            setXMLString(xmlFile, key .. "#name", track.name)
            setXMLInt(xmlFile, key .. "#strategy", track.strategy)
            setXMLInt(xmlFile, key .. "#method", track.method)
            setXMLFloat(xmlFile, key .. "#width", track.width)
            setXMLFloat(xmlFile, key .. "#offsetWidth", track.offsetWidth)
            setXMLString(xmlFile, key .. "#snapDirection", table.concat(track.snapDirection, " "))
            setXMLString(xmlFile, key .. "#driveTarget", table.concat(track.driveTarget, " "))
        end
    end
end

function GuidanceSteering:update(dt)
end

function GuidanceSteering:draw(dt)
end

function GuidanceSteering:createTrack(name)
    local entry = {
        name = name,
        strategy = 0,
        method = 0,
        width = 0,
        offsetWidth = 0,
        snapDirection = { 0, 0, 0, 0 },
        driveTarget = { 0, 0, 0, 0, 0 }
    }

    if not ListUtil.hasListElement(self.savedTracks, entry) then
        ListUtil.addElementToList(self.savedTracks, entry)
        Logger.info("add", entry)
    end
end

function GuidanceSteering:saveTrack(id, data)
    local entry = self.savedTracks[id]

    if entry ~= nil then
        entry.strategy = data.strategy
        entry.method = data.method
        entry.width = data.width
        entry.offsetWidth = data.offsetWidth
        entry.snapDirection = data.snapDirection
        entry.driveTarget = data.driveTarget
    end
end

function GuidanceSteering:deleteTrack(id)
    local entry = self.savedTracks[id]
    ListUtil.removeElementFromList(self.savedTracks, entry)
end

function GuidanceSteering:getTrack(id)
    return self.savedTracks[id]
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

function GuidanceSteering.actionEventAccelerate(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog)

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec ~= nil and spec.hasGuidanceSystem and spec.guidanceSteeringIsActive then
        spec.axisAccelerate = MathUtil.clamp(inputValue, 0, 1)
    end
end

function GuidanceSteering.actionEventBrake(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog)

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec ~= nil and spec.hasGuidanceSystem and spec.guidanceSteeringIsActive then
        spec.axisBrake = MathUtil.clamp(inputValue, 0, 1)
    end
end

function GuidanceSteering.actionEventSteer(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog)

    if inputValue ~= 0 then
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        if spec ~= nil and spec.hasGuidanceSystem and spec.lastInputValues.guidanceSteeringIsActive then
            spec.lastInputValues.guidanceSteeringIsActive = false
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