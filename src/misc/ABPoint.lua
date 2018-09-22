--
-- Created by IntelliJ IDEA.
-- User: Wopereis
-- Date: 9/21/2018
-- Time: 9:01 PM
-- To change this template use File | Settings | File Templates.
--

ABPoint = {}

local ABPoint_mt = Class(ABPoint)

ABPoint.POINT_A = "A"
ABPoint.POINT_B = "B"

ABPoint.__index = ABPoint

function ABPoint:new(refNode)
    local instance = {}

    setmetatable(instance, ABPoint_mt)

    instance.pointA = nil
    instance.pointB = nil

    instance._refNode = refNode

    return instance
end

---
-- Purges the AB points
function ABPoint:purge()
    self:iterate(function(point)
        delete(point.node)
    end)

    self.pointA = nil
    self.pointB = nil
end

---
-- Creates the next point dependent on the last point
-- @param data
--
function ABPoint:nextPoint(data)
    if self:getIsCreated() then return end

    local isPointA = self.pointA == nil
    local name = isPointA and ABPoint.POINT_A or ABPoint.POINT_B
    local next = self:_createNextPoint(data, name)

    if isPointA then
        self.pointA = next
        return self.pointA
    end

    self.pointB = next
    return self.pointB
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

    local point = { node = p, name = name }

    return point
end

function ABPoint:getPointNode(name)
    if name == ABPoint.POINT_A then
        return self.pointA.node
    end

    return self.pointB.node
end
---
--
function ABPoint:getIsCreated()
    return self.pointB ~= nil
end

---
--
function ABPoint:getIsEmpty()
    return self.pointA == nil and self.pointB == nil
end

---
-- Iteration function to have clean code access
-- @param visitor
--
function ABPoint:iterate(visitor)
    if self.pointA ~= nil then
        visitor(self.pointA)
    end

    if self.pointB ~= nil then
        visitor(self.pointB)
    end
end
