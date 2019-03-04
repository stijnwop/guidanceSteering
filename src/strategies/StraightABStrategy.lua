---
-- StraightABStrategy
--
-- Strategy class for AB straight points.
--
-- Copyright (c) Wopster, 2018

StraightABStrategy = {}

local StraightABStrategy_mt = Class(StraightABStrategy, ABStrategy)

function StraightABStrategy:new(vehicle, customMt)
    local instance = ABStrategy:new(vehicle, customMt or StraightABStrategy_mt)

    return instance
end

function StraightABStrategy:delete()
    StraightABStrategy:superClass().delete(self)
end

function StraightABStrategy:update(dt)
    StraightABStrategy:superClass().update(self, dt)
end

function StraightABStrategy:draw(data, guidanceSteeringIsActive, autoInvertOffset)
    StraightABStrategy:superClass().draw(self, data, guidanceSteeringIsActive, autoInvertOffset)
end

---Gets the guidance drive data for straight ab lines
---@param guidanceNode number
---@param data table
function StraightABStrategy:getGuidanceData(guidanceNode, data)
    --    if self.vehicle.turningActive then
    --        return StraightABStrategy:superClass().getGuidanceData(self, guidanceNode, data)
    --    end

    local pointA = guidanceNode
    local pointB = self.ab:getPointNode(ABPoint.POINT_A)
    local pointBIsDropped = self:getIsGuidancePossible()

    if pointBIsDropped then
        pointA = self.ab:getPointNode(ABPoint.POINT_A)
        pointB = self.ab:getPointNode(ABPoint.POINT_B)
    end

    local a = { localToWorld(pointA, 0, 0, 0) }
    local b = { localToWorld(pointB, 0, 0, 0) }

    local dirX = a[1] - b[1]
    local dirZ = a[3] - b[3]
    local length = MathUtil.vector2Length(dirX, dirZ)

    dirX, dirZ = dirX / length, dirZ / length

    local x, y, z = getWorldTranslation(guidanceNode)
    --        local localDirX, localDirY, localDirZ = worldDirectionToLocal(pointA, localDirectionToWorld(pointB, 0, 0, 1))
    --    local dirPoint = pointB
    local dx, dy, dz
    if pointBIsDropped then
        dx, dy, dz = localDirectionToWorld(guidanceNode, worldDirectionToLocal(pointB, dirX, 0, dirZ))
    else
        dx, dz = dirX, dirZ
    end

    -- tx, ty, tz = drive target translation
    -- dirX, dirZ = drive direction
    -- Todo: multiply by movingDirection
    local d = {
        x,
        y,
        z,
        dx,
        dz,
    }

    return d
end
