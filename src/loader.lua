local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("src/utils/Logger.lua", directory))
source(Utils.getFilename("src/utils/GuidanceUtil.lua", directory))
source(Utils.getFilename("src/GuidanceSteering.lua", directory))

source(Utils.getFilename("src/misc/ABPoint.lua", directory))
--source(Utils.getFilename("src/misc/LinkedList.lua", directory))

source(Utils.getFilename("src/strategies/ABStrategy.lua", directory))
source(Utils.getFilename("src/strategies/StraightABStrategy.lua", directory))
--source(Utils.getFilename("src/strategies/CurveABStrategy.lua", directory))

local guidanceSteering

function _init()
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, _unload)

    Mission00.load = Utils.prependedFunction(Mission00.load, _load)

    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, _validateVehicleTypes)
end

function _load(mission)
    assert(g_guidanceSteering == nil)

    guidanceSteering = GuidanceSteering:new(mission, directory, modName)

    g_guidanceSteering = guidanceSteering
    _G["g_guidanceSteering"] = guidanceSteering

    addModEventListener(guidanceSteering)
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

_init()

function Vehicle:guidanceSteering_getSpecTable(name)
    local spec = self["spec_" .. modName .. "." .. name]
    if spec ~= nil then
        return spec
    end

    return self["spec_" .. name]
end
