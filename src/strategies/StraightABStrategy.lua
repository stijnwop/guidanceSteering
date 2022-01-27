---
-- StraightABStrategy
--
-- Strategy class for AB straight points.
--
-- Copyright (c) Wopster, 2018

---@class StraightABStrategy: ABStrategy
StraightABStrategy = {}

local StraightABStrategy_mt = Class(StraightABStrategy, ABStrategy)

function StraightABStrategy:new(vehicle, customMt)
    local instance = ABStrategy:new(vehicle, customMt or StraightABStrategy_mt)
    return instance
end

---Gets the guidance drive data for straight AB lines.
---@param guidanceNode number
---@param data table
function StraightABStrategy:getGuidanceData(guidanceNode, data)
    local pointA = guidanceNode
    local pointB = self.ab:getPointNode(ABPoint.POINT_A)
    local isPointBDropped = self:getIsGuidancePossible()

    if isPointBDropped then
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
    local dx, dy, dz = dirX, 0, dirZ
    if isPointBDropped then
        dx, dy, dz = localDirectionToWorld(guidanceNode, worldDirectionToLocal(pointB, dirX, 0, dirZ))
    end

    -- tx, ty, tz = drive target translation
    -- dirX, dirZ = drive direction
    return { x, y, z, dx, dz }
end
