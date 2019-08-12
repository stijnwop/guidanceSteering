---
-- DriveUtil
--
-- Utility for driving the vehicle.
--
-- Copyright (c) Wopster, 2019

---@class DriveUtil
DriveUtil = {}

DriveUtil.MOVING_DIRECTION_FORWARDS = 1
DriveUtil.MOVING_DIRECTION_BACKWARDS = -1
DriveUtil.HIT_THRESHOLD = 100000
DriveUtil.TARGET_STEP = 5 -- m

---Calculates the direction beta for the target points.
---@param data table
---@param autoInvertOffset boolean
local function getDirectionBeta(data, autoInvertOffset)
    if data.offsetWidth ~= 0 then
        local snapFactor = autoInvertOffset and data.snapDirectionMultiplier or 1.0
        return data.alphaRad - snapFactor * data.offsetWidth / data.width
    end

    return data.alphaRad
end

---Guides the given vehicle based on the guidance data.
---@param vehicle table
---@param dt number delta time
function DriveUtil.guideSteering(vehicle, dt)
    if vehicle:getIsAIActive() then
        -- Disallow when AI is active
        return
    end

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")

    local data = spec.guidanceData
    local driveX, driveY, driveZ = unpack(data.driveTarget)
    local snapDirX, snapDirZ = unpack(data.snapDirection)
    local lineDirX = data.snapDirectionMultiplier * snapDirX
    local lineDirZ = data.snapDirectionMultiplier * snapDirZ

    -- Calculate target points
    local beta = getDirectionBeta(data, spec.autoInvertOffset)
    local x = driveX + data.width * snapDirZ * beta
    local z = driveZ - data.width * snapDirX * beta

    local targetX = x + DriveUtil.TARGET_STEP * lineDirX
    local targetZ = z + DriveUtil.TARGET_STEP * lineDirZ

    local pointX, _, pointZ = worldToLocal(spec.guidanceNode, targetX, driveY, targetZ)
    DriveUtil.driveToPoint(vehicle, dt, pointX, pointZ)

    -- lock max speed to working tool
    local speed = vehicle:getSpeedLimit(true)
    local drivable_spec = vehicle:guidanceSteering_getSpecTable("drivable")
    if drivable_spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
        speed = math.min(speed, drivable_spec.cruiseControl.speed)
    end

    vehicle:getMotor():setSpeedLimit(speed)

    DriveUtil.accelerateInDirection(vehicle, spec.axisForward, dt)
end

---Drives the given vehicle to the point.
---@param vehicle table
---@param dt number
---@param tX number
---@param tZ number
function DriveUtil.driveToPoint(vehicle, dt, tX, tZ)
    if vehicle.firstTimeRun then
        local halfX = tX * 0.5
        local halfZ = tZ * 0.5

        local dirX, dirZ = halfZ, -halfX
        if tX > 0 then
            dirX, dirZ = -halfZ, halfX
        end

        local hasIntersection, _, f2 = MathUtil.getLineLineIntersection2D(halfX, halfZ, dirX, dirZ, 0, 0, tX, 0)

        local rotTime = 0
        if hasIntersection and math.abs(f2) < DriveUtil.HIT_THRESHOLD then
            local radius = tX * f2
            rotTime = vehicle.wheelSteeringDuration * (math.atan(1 / radius) / math.atan(1 / vehicle.maxTurningRadius))
        end

        local targetRotTime = 0
        if rotTime >= 0 then
            targetRotTime = math.min(rotTime, vehicle.maxRotTime)
        else
            targetRotTime = math.max(rotTime, vehicle.minRotTime)
        end

        if targetRotTime > vehicle.rotatedTime then
            vehicle.rotatedTime = math.min(vehicle.rotatedTime + dt * vehicle:getAISteeringSpeed(), targetRotTime)
        else
            vehicle.rotatedTime = math.max(vehicle.rotatedTime - dt * vehicle:getAISteeringSpeed(), targetRotTime)
        end
    end
end

---Drives the given vehicle in a direction.
---@param vehicle table
---@param dt number
---@param steeringAngleLimit number
---@param movingDirection number
---@param lx number
---@param lz number
function DriveUtil.driveInDirection(vehicle, dt, steeringAngleLimit, movingDirection, lx, lz)
    if lx ~= nil and lz ~= nil then
        local data = vehicle.guidanceData
        local dot = lz
        local moveForwards = movingDirection == DriveUtil.MOVING_DIRECTION_FORWARDS
        local angle = math.deg(math.acos(dot)) * data.snapDirectionMultiplier * movingDirection
        local t = math.acos(lx)
        if t < 1.5708 then
            angle = angle + 180
        end

        local turnLeft = lz > 0.00001
        if not moveForwards then
            turnLeft = not turnLeft
        end

        local targetRotTime
        if turnLeft then
            --rotate to the left
            targetRotTime = vehicle.maxRotTime * math.min(angle / steeringAngleLimit, 1)
        else
            --rotate to the right
            targetRotTime = vehicle.minRotTime * math.min(angle / steeringAngleLimit, 1)
        end

        if targetRotTime > vehicle.rotatedTime then
            vehicle.rotatedTime = math.min(vehicle.rotatedTime + dt * vehicle:getAISteeringSpeed(), targetRotTime)
        else
            vehicle.rotatedTime = math.max(vehicle.rotatedTime - dt * vehicle:getAISteeringSpeed(), targetRotTime)
        end
    end
end

---Accelerates the given vehicle.
---@param vehicle table
---@param axisForward number
---@param dt number
function DriveUtil.accelerateInDirection(vehicle, axisForward, dt)
    local spec = vehicle.spec_drivable
    local acceleration = 0

    if vehicle:getIsMotorStarted()
            and vehicle:getMotorStartTime() <= g_currentMission.time then
        acceleration = axisForward
        if math.abs(acceleration) > 0 then
            vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
        end

        if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
            acceleration = 1.0
        end
    end

    if not vehicle:getCanMotorRun() then
        acceleration = 0
        if vehicle:getIsMotorStarted() then
            vehicle:stopMotor()
        end
    end

    if vehicle.firstTimeRun then
        if vehicle.spec_wheels ~= nil then
            WheelsUtil.updateWheelsPhysics(vehicle, dt, vehicle.lastSpeedReal * vehicle.movingDirection, acceleration, false, g_currentMission.missionInfo.stopAndGoBraking)
        end
    end

    return acceleration
end
