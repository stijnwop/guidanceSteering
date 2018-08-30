--
-- ManualAttachingRegistrationHelper
--
-- Authors: Wopster
-- Description: The register class to load the specialization
--
-- Copyright (c) Wopster, 2015 - 2017

Register = {
    baseDirectory = g_currentModDirectory
}

if SpecializationUtil.specializations["guidanceSteering"] == nil then
    SpecializationUtil.registerSpecialization('guidanceSteering', 'GuidanceSteering', Register.baseDirectory .. 'src/GuidanceSteering.lua')
end

---
-- @param name
--
function Register:loadMap(name)
    if not g_currentMission.guidanceRegistrationHelperIsLoaded then
        self:register()
        g_currentMission.guidanceRegistrationHelperIsLoaded = true
    else
        print("ManualAttaching - error: The ManualAttachingRegistrationHelper have been loaded already! Remove one of the copy's!")
    end
end

---
--
function Register:deleteMap()
    if g_currentMission.guidanceRegistrationHelperIsLoaded then
        self:unregister()
        g_currentMission.guidanceRegistrationHelperIsLoaded = false
    end
end

---
-- @param ...
--
function Register:keyEvent(...)
end

---
-- @param ...
--
function Register:mouseEvent(...)
end

---
-- @param dt
--
function Register:update(dt)
end

---
--
function Register:draw()
end

---
--
function Register:register()
    local extensionSpec = SpecializationUtil.getSpecialization('guidanceSteering')

    for _, vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
        if vehicleType ~= nil
                and SpecializationUtil.hasSpecialization(Steerable, vehicleType.specializations) then
            table.insert(vehicleType.specializations, extensionSpec)
        end
    end
end

---
--
function Register:unregister()
    local extensionSpec = SpecializationUtil.getSpecialization('guidanceSteering')

    for _, vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
        if vehicleType ~= nil then
            for i, spec in ipairs(vehicleType.specializations) do
                if spec == extensionSpec then
                    table.remove(vehicleType.specializations, i)
                    break
                end
            end
        end
    end
end

addModEventListener(Register)