GuidanceSteering = {}

local GuidanceSteering_mt = Class(GuidanceSteering)

function GuidanceSteering:new(mission, modDirectory, modName, i18n, gui, inputManager)
    local self = {}

    setmetatable(self, GuidanceSteering_mt)

    self.isServer = mission:getIsServer()
    self.modDirectory = modDirectory
    self.modName = modName

    self.ui = GuidanceSteeringUI:new(mission, i18n, modDirectory, inputManager)

    return self
end

function GuidanceSteering:delete()
    self.ui:delete()
end

function GuidanceSteering:onMissionLoaded(mission)
    self.ui:load()
end

function GuidanceSteering:onMissionStart(mission)
    self.ui:onMissionStart()
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

    Drivable.actionEventAccelerate = Utils.overwrittenFunction(Drivable.actionEventAccelerate, GuidanceSteering.actionEventAccelerate)
    Drivable.actionEventBrake = Utils.overwrittenFunction(Drivable.actionEventBrake, GuidanceSteering.actionEventBrake)
    Drivable.actionEventSteer = Utils.overwrittenFunction(Drivable.actionEventSteer, GuidanceSteering.actionEventSteer)
end

function GuidanceSteering.actionEventAccelerate(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog)

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.guidanceSteeringIsActive then
        spec.axisAccelerate = MathUtil.clamp(inputValue, 0, 1)
    end
end

function GuidanceSteering.actionEventBrake(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog)

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.guidanceSteeringIsActive then
        spec.axisBrake = MathUtil.clamp(inputValue, 0, 1)
    end
end

function GuidanceSteering.actionEventSteer(vehicle, superFunc, actionName, inputValue, callbackState, isAnalog)
    superFunc(vehicle, actionName, inputValue, callbackState, isAnalog)

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.guidanceSteeringIsActive and inputValue ~= 0 then
        spec.guidanceSteeringIsActive = false
    end
end