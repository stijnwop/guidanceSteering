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

---driveToPoint
---@param self table
---@param dt number
---@param tX number
---@param tZ number
function DriveUtil.driveToPoint(self, dt, tX, tZ)
    if self.firstTimeRun then
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
            rotTime = self.wheelSteeringDuration * (math.atan(1 / radius) / math.atan(1 / self.maxTurningRadius))
        end

        local targetRotTime = 0
        if rotTime >= 0 then
            targetRotTime = math.min(rotTime, self.maxRotTime)
        else
            targetRotTime = math.max(rotTime, self.minRotTime)
        end

        if targetRotTime > self.rotatedTime then
            self.rotatedTime = math.min(self.rotatedTime + dt * self:getAISteeringSpeed(), targetRotTime)
        else
            self.rotatedTime = math.max(self.rotatedTime - dt * self:getAISteeringSpeed(), targetRotTime)
        end
    end
end

---driveInDirection
---@param self table
---@param dt number
---@param steeringAngleLimit number
---@param movingDirection number
---@param lx number
---@param lz number
function DriveUtil.driveInDirection(self, dt, steeringAngleLimit, movingDirection, lx, lz)
    if lx ~= nil and lz ~= nil then
        local data = self.guidanceData
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
            targetRotTime = self.maxRotTime * math.min(angle / steeringAngleLimit, 1)
        else
            --rotate to the right
            targetRotTime = self.minRotTime * math.min(angle / steeringAngleLimit, 1)
        end

        if targetRotTime > self.rotatedTime then
            self.rotatedTime = math.min(self.rotatedTime + dt * self:getAISteeringSpeed(), targetRotTime)
        else
            self.rotatedTime = math.max(self.rotatedTime - dt * self:getAISteeringSpeed(), targetRotTime)
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
