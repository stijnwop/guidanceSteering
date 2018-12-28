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

local forcedStoreCategories = {
    ["TRACTORSS"] = true,
    ["TRACTORSM"] = true,
    ["TRACTORSL"] = true,
    ["TRUCKS"] = true,
    ["TELELOADERS"] = false,
    ["TELELOADERVEHICLES"] = false,
    ["FRONTLOADERVEHICLES"] = false,
    ["FRONTLOADERS"] = false,
    ["WHEELLOADERS"] = false,
    ["WHEELLOADERVEHICLES"] = false,
    ["SKIDSTEERS"] = false,
    ["SKIDSTEERVEHICLES"] = false,
    ["ANIMALSVEHICLES"] = false,
    ["HARVESTERS"] = true,
    ["CUTTERS"] = false,
    ["FORAGEHARVESTERCUTTERS"] = false,
    ["CORNHEADERS"] = false,
    ["FORAGEHARVESTERS"] = true,
    ["BEETVEHICLES"] = true,
    ["POTATOVEHICLES"] = true,
    ["SPRAYERVEHICLES"] = true,
    ["COTTONVEHICLES"] = true,
    ["WOODHARVESTING"] = false,
    ["MOWERVEHICLES"] = true,
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

local function storeItemAllowsGuidanceSteering(storeItem)
    if forcedStoreCategories[storeItem.categoryName] == nil then
        Logger.info(storeItem.categoryName)
        if storeItem.specs ~= nil then
            -- Check for exception vehicles
            local specs = storeItem.specs
            local isFuelConsumer = #specs.fuel.consumers > 0
            local hasWorkingWidth = specs.workingWidth ~= nil

            if isFuelConsumer and hasWorkingWidth then
                return true
            end
        end

        return false
    end

    return forcedStoreCategories[storeItem.categoryName]
end

function _addGPSConfigurationUtil(xmlFile, superFunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
    local configurations = superFunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)

    if storeItemAllowsGuidanceSteering(storeItem) then
        local key = GlobalPositioningSystem.CONFIG_NAME
        if configurations ~= nil and configurations[key] == nil then
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
                price = 15000,
                dailyUpkeep = 0,
                isDefault = false,
                index = 2,
                name = g_i18n:getText("configuration_buyableGPS_withGPS"),
                enabled = true
            }

            configurations[key] = {}
            table.insert(configurations[key], entryNoGPS)
            table.insert(configurations[key], entryGPS)
        end
    end

    return configurations
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
