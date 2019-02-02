---
-- CardinalStrategy
--
-- Strategy class for cardinal degrees also called A+heading.
--
-- Copyright (c) Wopster, 2018

CardinalStrategy = {}

CardinalStrategy.NORTH = 0
CardinalStrategy.SOUTH = 90
CardinalStrategy.EAST = -90
CardinalStrategy.WEST = 180

local CardinalStrategy_mt = Class(CardinalStrategy, ABStrategy)

function CardinalStrategy:new(vehicle, customMt)
    if customMt == nil then
        customMt = CardinalStrategy_mt
    end

    local instance = ABStrategy:new(vehicle, customMt)

    return instance
end

function CardinalStrategy:delete()
    CardinalStrategy:superClass().delete(self)
end

function CardinalStrategy:update(dt)
    CardinalStrategy:superClass().update(self, dt)
end

function CardinalStrategy:draw(data, guidanceSteeringIsActive)
    CardinalStrategy:superClass().draw(self, data, guidanceSteeringIsActive)
end

---Gets the guidance drive data for the given cardinals
---@param guidanceNode number
---@param data table
function CardinalStrategy:getGuidanceData(guidanceNode, data)
    local cardinal = 0 -- Todo: get cardinal from settings

    local pointA = self.ab:getPointNode(ABPoint.POINT_A)

    local x, y, z = 0, 0, 0
    local dirX, dirZ = math.sin(cardinal), math.cos(cardinal)

    -- tx, ty, tz = drive target translation
    -- dirX, dirZ = drive direction
    local d = {
        tx = x,
        ty = y,
        tz = z,
        dirX = dirX,
        dirZ = dirZ,
    }

    return d
end

function CardinalStrategy:getIsGuidancePossible()
    return self.ab:getPointNode(ABPoint.POINT_A) ~= nil
end
