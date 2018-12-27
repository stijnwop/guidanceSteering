local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("src/utils/Logger.lua", directory))
source(Utils.getFilename("src/utils/DriveUtil.lua", directory))
source(Utils.getFilename("src/utils/GuidanceUtil.lua", directory))

source(Utils.getFilename("src/gui/GuidanceSteeringUI.lua", directory))
source(Utils.getFilename("src/gui/GuidanceSteeringHUD.lua", directory))

source(Utils.getFilename("src/GuidanceSteering.lua", directory))

source(Utils.getFilename("src/misc/MultiPurposeActionEvent.lua", directory))
source(Utils.getFilename("src/misc/ABPoint.lua", directory))
--source(Utils.getFilename("src/misc/LinkedList.lua", directory))

source(Utils.getFilename("src/strategies/ABStrategy.lua", directory))
source(Utils.getFilename("src/strategies/StraightABStrategy.lua", directory))
--source(Utils.getFilename("src/strategies/CurveABStrategy.lua", directory))

local guidanceSteering

function _init()
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, _unload)

    Mission00.load = Utils.prependedFunction(Mission00.load, _load)
    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, _loadedMission)
    Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, _startMission)

    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, _validateVehicleTypes)
    --    StoreManager.loadItem = Utils.appendedFunction(StoreManager.loadItem, _addGPSConfiguration)
    StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, _addGPSConfigurationUtil)
end

function _load(mission)
    assert(g_guidanceSteering == nil)

    guidanceSteering = GuidanceSteering:new(mission, directory, modName, g_i18n, g_gui, g_gui.inputManager)

    g_guidanceSteering = guidanceSteering
    _G["g_guidanceSteering"] = guidanceSteering

    addModEventListener(guidanceSteering)
end

function _loadedMission(mission, node)
    --    if not isActive() then return end

    if mission.cancelLoading then
        return
    end

    guidanceSteering:onMissionLoaded(mission)

    --    if mission:getIsServer() and mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/seasons.xml") then
    --        local xmlFile = loadXMLFile("SeasonsXML", mission.missionInfo.savegameDirectory .. "/seasons.xml")
    --        if xmlFile ~= nil then
    --            seasons:onMissionLoadFromSavegame(mission, xmlFile)
    --            delete(xmlFile)
    --        end
    --    end
end

-- Player clicked on start
function _startMission(mission)
    --    if not isActive() then return end

    guidanceSteering:onMissionStart(mission)
end


function _unload()
    removeModEventListener(guidanceSteering)

    if GS_IS_CONSOLE_VERSION then
    end

    guidanceSteering:delete()
    guidanceSteering = nil -- Allows garbage collecting
    _G["g_guidanceSteering"] = nil
end

function _validateVehicleTypes(vehicleTypeManager)
    GuidanceSteering.installSpecializations(g_vehicleTypeManager, g_specializationManager, directory, modName)
end

local allowedStoreCategories = {
    ["TRACTORSS"] = true,
    ["TRACTORSM"] = true,
    ["TRACTORSL"] = true,
    ["TRUCKS"] = true,
    ["HARVESTERS"] = true,
    ["FORAGEHARVESTERS"] = true,
    ["BEETVEHICLES"] = true,
    ["POTATOVEHICLES"] = true
}

function _addGPSConfigurationUtil(xmlFile, superFunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
    local configurations = superFunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)

    if allowedStoreCategories[storeItem.categoryName] then
        if configurations ~= nil and configurations["buyableGPS"] == nil then
            configurations["buyableGPS"] = {}

            local entryNoGPS = {
                desc = "",
                price = 0,
                dailyUpkeep = 0,
                isDefault = true,
                index = 1,
                name = g_i18n:getText("configuration_buyableGPS_withoutGPS"),
                enabled = false
            }

            local entryGPS = {
                desc = "",
                price = 10000,
                dailyUpkeep = 0,
                isDefault = false,
                index = 2,
                name = g_i18n:getText("configuration_buyableGPS_withGPS"),
                enabled = true
            }

            table.insert(configurations["buyableGPS"], entryNoGPS)
            table.insert(configurations["buyableGPS"], entryGPS)
        end
    end

    return configurations
end

function _addGPSConfiguration(self, xmlFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle)
    Logger.info("", xmlFilename)
end

_init()

-- Fixes

function Vehicle:guidanceSteering_getSpecTable(name)
    local spec = self["spec_" .. modName .. "." .. name]
    if spec ~= nil then
        return spec
    end

    return self["spec_" .. name]
end
