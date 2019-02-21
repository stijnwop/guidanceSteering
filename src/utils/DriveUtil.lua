---
-- DriveUtil
--
-- Utility for driving the vehicle.
--
-- Copyright (c) Wopster, 2019

DriveUtil = {}

DriveUtil.MOVING_DIRECTION_FORWARDS = 1
DriveUtil.MOVING_DIRECTION_BACKWARDS = -1
DriveUtil.HIT_THRESHOLD = 100000
DriveUtil.TARGET_STEP = 5 -- m

function DriveUtil.guideSteering(vehicle, dt)
    if vehicle.isHired then
        -- Disallow when AI is active
        return
    end

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    local drivable_spec = vehicle:guidanceSteering_getSpecTable("drivable")

    local data = spec.guidanceData

    local dX, dY, dZ = unpack(data.driveTarget)
    local snapDirX, snapDirZ = unpack(data.snapDirection)
    local lineXDir = data.snapDirectionMultiplier * snapDirX
    local lineZDir = data.snapDirectionMultiplier * snapDirZ
    -- Calculate target points
    local x = dX + data.width * snapDirZ * data.alphaRad
    local z = dZ - data.width * snapDirX * data.alphaRad
    local tX = x + DriveUtil.TARGET_STEP * lineXDir
    local tZ = z + DriveUtil.TARGET_STEP * lineZDir

    if spec.showGuidanceLines then
        DebugUtil.drawDebugCircle(tX, dY + .2, tZ, .5, 10, { 0, 1, 0 })
    end

    local pX, _, pZ = worldToLocal(spec.guidanceNode, tX, dY, tZ)

    DriveUtil.driveToPoint(vehicle, dt, pX, pZ)

    -- lock max speed to working tool
    local speed = vehicle:getSpeedLimit(true)
    if drivable_spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
        speed = math.min(speed, drivable_spec.cruiseControl.speed)
    end

    vehicle:getMotor():setSpeedLimit(speed)

    DriveUtil.accelerateInDirection(vehicle, drivable_spec.axisForward, dt)
end

---driveToPoint
---@param self table
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

---driveInDirection
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

        Logger.info("x", { steeringAngle = angle, lz = lz, lx = lx })

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

---accelerateInDirection
---@param vehicle table
---@param axisForward number
---@param dt number
function DriveUtil.accelerateInDirection(vehicle, axisForward, dt)
    local spec = vehicle.spec_drivable
    local acceleration = 0

    if vehicle:getIsMotorStarted()
            and vehicle:getMotorStartTime() <= g_currentMission.time then
        acceleration = axisForward
        if math.abs(acceleration) > 0.8 then
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
