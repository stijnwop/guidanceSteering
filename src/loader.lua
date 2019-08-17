---
-- loader
--
-- loader script for the mod
--
-- Copyright (c) Wopster, 2018

local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("src/events/TrackSaveEvent.lua", directory))
source(Utils.getFilename("src/events/TrackDeleteEvent.lua", directory))
source(Utils.getFilename("src/events/ABPointPushedEvent.lua", directory))
source(Utils.getFilename("src/events/GuidanceDataChangedEvent.lua", directory))
source(Utils.getFilename("src/events/HeadlandModeChangedEvent.lua", directory))

source(Utils.getFilename("src/utils/Logger.lua", directory))
source(Utils.getFilename("src/utils/DriveUtil.lua", directory))
source(Utils.getFilename("src/utils/GuidanceUtil.lua", directory))
source(Utils.getFilename("src/utils/HeadlandUtil.lua", directory))
source(Utils.getFilename("src/utils/stream.lua", directory))

source(Utils.getFilename("src/gui/GuidanceSteeringUI.lua", directory))
source(Utils.getFilename("src/gui/GuidanceSteeringMenu.lua", directory))
source(Utils.getFilename("src/gui/frames/GuidanceSteeringSettingsFrame.lua", directory))
source(Utils.getFilename("src/gui/frames/GuidanceSteeringStrategyFrame.lua", directory))
source(Utils.getFilename("src/gui/hud/GuidanceSteeringHUD.lua", directory))

source(Utils.getFilename("src/GuidanceSteering.lua", directory))

source(Utils.getFilename("src/misc/FSM.lua", directory))
source(Utils.getFilename("src/misc/FSMContext.lua", directory))
source(Utils.getFilename("src/misc/StateEngine.lua", directory))
source(Utils.getFilename("src/misc/states/AbstractState.lua", directory))
source(Utils.getFilename("src/misc/states/FollowLineState.lua", directory))
source(Utils.getFilename("src/misc/states/OnHeadlandState.lua", directory))
source(Utils.getFilename("src/misc/states/StoppedState.lua", directory))
source(Utils.getFilename("src/misc/states/TurningState.lua", directory))

source(Utils.getFilename("src/misc/MultiPurposeActionEvent.lua", directory))
source(Utils.getFilename("src/misc/ABPoint.lua", directory))
--source(Utils.getFilename("src/misc/LinkedList.lua", directory))

source(Utils.getFilename("src/strategies/ABStrategy.lua", directory))
source(Utils.getFilename("src/strategies/StraightABStrategy.lua", directory))
--source(Utils.getFilename("src/strategies/CurveABStrategy.lua", directory))

local guidanceSteering
local guidanceConfigurations = {}

local function isEnabled()
    return guidanceSteering ~= nil
end

function init()
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)

    Mission00.load = Utils.prependedFunction(Mission00.load, loadMission)
    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)

    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, saveToXMLFile)

    -- Networking
    SavegameSettingsEvent.readStream = Utils.appendedFunction(SavegameSettingsEvent.readStream, readStream)
    SavegameSettingsEvent.writeStream = Utils.appendedFunction(SavegameSettingsEvent.writeStream, writeStream)

    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
    StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, addGPSConfigurationUtil)
end

function loadMission(mission)
    assert(g_guidanceSteering == nil)

    guidanceSteering = GuidanceSteering:new(mission, directory, modName, g_i18n, g_gui, g_gui.inputManager, g_messageCenter)

    getfenv(0)["g_guidanceSteering"] = guidanceSteering

    addModEventListener(guidanceSteering)

    local xmlFile = loadXMLFile("ConfigurationXML", directory .. "resources/buyableGPSConfiguration.xml")
    if xmlFile ~= nil then
        for i = 1, 2 do
            local key = ("buyableGPSConfigurations.buyableGPSConfiguration(%d)"):format(i - 1)

            local config = {}
            config.desc = ""
            config.isDefault = getXMLBool(xmlFile, key .. "#isDefault")
            config.dailyUpkeep = 0
            config.index = i
            config.price = getXMLInt(xmlFile, key .. "#price")
            config.name = g_i18n:getText(getXMLString(xmlFile, key .. "#name"))
            config.enabled = getXMLBool(xmlFile, key .. "#enabled")

            table.insert(guidanceConfigurations, config)
        end

        delete(xmlFile)
    end
end

function loadedMission(mission, node)
    if not isEnabled() then
        return
    end

    if mission:getIsServer() then
        if mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/guidanceSteering.xml") then
            local xmlFile = loadXMLFile("GuidanceXML", mission.missionInfo.savegameDirectory .. "/guidanceSteering.xml")
            if xmlFile ~= nil then
                guidanceSteering:onMissionLoadFromSavegame(xmlFile)
                delete(xmlFile)
            end
        end
    end

    if mission.cancelLoading then
        return
    end

    guidanceSteering:onMissionLoaded(mission)
end

function unload()
    if not isEnabled() then
        return
    end

    removeModEventListener(guidanceSteering)

    guidanceSteering:delete()
    guidanceSteering = nil -- Allows garbage collecting
    getfenv(0)["g_guidanceSteering"] = nil
end

function saveToXMLFile(missionInfo)
    if not isEnabled() then
        return
    end

    if missionInfo.isValid then
        local xmlFile = createXMLFile("GuidanceXML", missionInfo.savegameDirectory .. "/guidanceSteering.xml", "guidanceSteering")
        if xmlFile ~= nil then
            guidanceSteering:onMissionSaveToSavegame(xmlFile)

            saveXMLFile(xmlFile)
            delete(xmlFile)
        end
    end
end

function readStream(e, streamId, connection)
    if not isEnabled() then
        return
    end

    guidanceSteering:onReadStream(streamId, connection)
end

function writeStream(e, streamId, connection)
    if not isEnabled() then
        return
    end

    guidanceSteering:onWriteStream(streamId, connection)
end

function validateVehicleTypes(vehicleTypeManager)
    GuidanceSteering.installSpecializations(g_vehicleTypeManager, g_specializationManager, directory, modName)
end

-- StoreItem insertion

local disallowedCategories = {
    ["TELELOADERS"] = false,
    ["TELELOADERVEHICLES"] = false,
    ["FRONTLOADERVEHICLES"] = false,
    ["FRONTLOADERS"] = false,
    ["WHEELLOADERS"] = false,
    ["WHEELLOADERVEHICLES"] = false,
    ["SKIDSTEERS"] = false,
    ["SKIDSTEERVEHICLES"] = false,
    ["ANIMALSVEHICLES"] = false,
    ["CUTTERS"] = false,
    ["FORAGEHARVESTERCUTTERS"] = false,
    ["CORNHEADERS"] = false,
    ["WOODHARVESTING"] = false,
    ["ANIMALS"] = false,
    ["CUTTERTRAILERS"] = false,
    ["TRAILERS"] = false,
    ["SLURRYTANKS"] = false,
    ["MANURESPREADERS"] = false,
    ["LOADERWAGONS"] = false,
    ["AUGERWAGONS"] = false,
    ["WINDROWERS"] = false,
    ["WEIGHTS"] = false,
    ["LOWLOADERS"] = false,
    ["WOOD"] = false,
    ["BELTS"] = false,
    ["LEVELER"] = false,
    ["CARS"] = false,
    ["DECORATION"] = false,
    ["PLACEABLEMISC"] = false,
    ["PLACEABLEMISC"] = false,
    ["CHAINSAWS"] = false,
    ["SHEDS"] = false,
    ["BIGBAGS"] = false,
    ["BALES"] = false,
    ["ANIMALPENS"] = false,
    ["FARMHOUSES"] = false,
    ["SILOS"] = false,
}

local function canAddGuidanceSteeringConfiguration(storeItem, xmlFile)
    local isDrivable = hasXMLProperty(xmlFile, "vehicle.drivable")
    local isMotorized = hasXMLProperty(xmlFile, "vehicle.motorized")

    return disallowedCategories[storeItem.categoryName] == nil and isDrivable and isMotorized
end

function addGPSConfigurationUtil(xmlFile, superFunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
    local configurations = superFunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)

    if canAddGuidanceSteeringConfiguration(storeItem, xmlFile) then
        local key = GlobalPositioningSystem.CONFIG_NAME

        if configurations ~= nil then
            if configurations[key] == nil then
                configurations[key] = guidanceConfigurations
            else
                -- Add enabled values to added xml configurations
                for id, config in pairs(configurations[key]) do
                    config.enabled = id > 1
                end
            end
        end
    end

    return configurations
end

init()

-- Fixes

function Vehicle:guidanceSteering_getModName()
    return modName
end

function Vehicle:guidanceSteering_getSpecTable(name)
    local spec = self["spec_" .. modName .. "." .. name]
    if spec ~= nil then
        return spec
    end

    return self["spec_" .. name]
end
