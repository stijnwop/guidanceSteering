
GuidanceSteering = {}

local GuidanceSteering_mt = Class(GuidanceSteering)

function GuidanceSteering:new(mission, modDirectory, modName)
    local self = {}

    setmetatable(self, GuidanceSteering_mt)

    self.isServer = mission:getIsServer()
    self.modDirectory = modDirectory
    self.modName = modName
end

function GuidanceSteering:delete()
end

function GuidanceSteering:update(dt)
end

function GuidanceSteering:draw(dt)
end

function GuidanceSteering.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
    -- Specializations are namespaced for mods: the names are prefixed with the mod folder/zip name and a dot. E.g. FS19_RM_Seasons.snowTracks
    specializationManager:addSpecialization("globalPositioningSystem", "GlobalPositioningSystem", Utils.getFilename("src/vehicles/GlobalPositioningSystem.lua", modDirectory), nil) -- Nil is important here

    for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
--                for name, o in pairs(typeEntry.specializations) do
--                    Logger.info("", o)
--                end
--        Logger.info(typeName, typeEntry.specializationNames)

        if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) then
            -- Make sure to namespace the spec again
            vehicleTypeManager:addSpecialization(typeName, modName .. ".globalPositioningSystem")
        end
    end
end
