---
-- ABPoint
--
-- AB point class to handle AB points.
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

---creates a new ABPoint instance
---@param refNode number
function ABPoint:new(refNode)
    local instance = {}

    setmetatable(instance, ABPoint_mt)

    instance.points = { a = nil, b = nil }

    instance._refNode = refNode

    return instance
end

---purges the point nodes
function ABPoint:purge()
    self:iterate(function(point)
        delete(point.node)
        point = nil
    end)

    self.points = { a = nil, b = nil }
end

---Creates the next point dependent on the last point
---@param data table
function ABPoint:nextPoint(data)
    if self:getIsCreated() then
        return
    end

    local createAPoint = self.points[ABPoint.POINT_A] == nil
    local name = ABPoint.AB_POINTS[createAPoint]
    local next = self:_createNextPoint(data, name)

    return next
end

---Creates the next world transform group
---@param data table
---@param name string
function ABPoint:_createNextPoint(data, name)
    local p = createTransformGroup(("AB_point_%s"):format(name))
    local x, y, z = unpack(data.driveTarget)
    if not (x ~= 0 or z ~= 0) then
        x, y, z = getWorldTranslation(self._refNode)
    end
    local dx, dy, dz = localDirectionToWorld(self._refNode, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(self._refNode, 0, 1, 0)

    y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

    link(getRootNode(), p)

    setTranslation(p, x, y, z)
    setDirection(p, dx, dy, dz, upX, upY, upZ)

    local point = { node = p, name = name:upper() }

    self.points[name] = point

    return point
end

---Gets point node by name
---@param name string
function ABPoint:getPointNode(name)
    return self.points[name].node
end

---Gets if the AB points are created
function ABPoint:getIsCreated()
    return self.points[ABPoint.POINT_B] ~= nil
end

---Gets if AB is empty
function ABPoint:getIsEmpty()
    return self.points[ABPoint.POINT_A] == nil
            and self.points[ABPoint.POINT_B] == nil
end

---Iteration function to have clean code access
---@param visitor table
function ABPoint:iterate(visitor)
    for _, point in pairs(self.points) do
        if point ~= nil then
            visitor(point)
        end
    end
end
