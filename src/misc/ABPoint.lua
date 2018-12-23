--
-- ABPoint
--
-- Authors: Wopster
-- Description: AB point class to handle AB points.
--
-- Copyright (c) Wopster, 2018

ABPoint = {}

local ABPoint_mt = Class(ABPoint)

ABPoint.POINT_A = "a"
ABPoint.POINT_B = "b"

ABPoint.AB_POINTS = {}
ABPoint.AB_POINTS[true] = ABPoint.POINT_A
ABPoint.AB_POINTS[false] = ABPoint.POINT_B

ABPoint.__index = ABPoint

function ABPoint:new(refNode)
    local instance = {}

    setmetatable(instance, ABPoint_mt)

    instance.points = { a = nil, b = nil }

    instance._refNode = refNode

    return instance
end

---
-- Purges the AB points
function ABPoint:purge()
    self:iterate(function(point)
        delete(point.node)
        point = nil
    end)

    self.points = { a = nil, b = nil }
end

---
-- Creates the next point dependent on the last point
-- @param data
--
function ABPoint:nextPoint(data)
    if self:getIsCreated() then return end

    local createAPoint = self.points[ABPoint.POINT_A] == nil
    local name = ABPoint.AB_POINTS[createAPoint]
    local next = self:_createNextPoint(data, name)

    return next
end

---
-- Creates the next world transform group
-- @param data
-- @param name
--
function ABPoint:_createNextPoint(data, name)
    local p = createTransformGroup(("AB_point_%s"):format(name))
    local x, _, z = unpack(data.driveTarget)
    if not (x ~= 0 or z ~= 0) then
        x, _, z = getWorldTranslation(self._refNode)
    end
    local dx, dy, dz = localDirectionToWorld(self._refNode, 0, 0, 1)
    local upX, upY, upZ = worldDirectionToLocal(self._refNode, 0, 1, 0)
    local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

    link(getRootNode(), p)

    setTranslation(p, x, y, z)
    setDirection(p, dx, dy, dz, upX, upY, upZ)

    local point = { node = p, name = name:upper() }

    self.points[name] = point

    return point
end

---
-- @param name
--
function ABPoint:getPointNode(name)
    return self.points[name].node
end

---
--
function ABPoint:getIsCreated()
    return self.points[ABPoint.POINT_B] ~= nil
end

---
--
function ABPoint:getIsEmpty()
    return self.points[ABPoint.POINT_A] == nil
            and self.points[ABPoint.POINT_B] == nil
end

---
-- Iteration function to have clean code access
-- @param visitor
--
function ABPoint:iterate(visitor)
    for _, point in pairs(self.points) do
        if point ~= nil then
            visitor(point)
        end
    end
end
