--
-- CardinalStrategy
--
-- Authors: Wopster
-- Description: Strategy class for cardinal degrees.
--
-- Copyright (c) Wopster, 2018

CardinalStrategy = {}

CardinalStrategy.NORTH = 0
CardinalStrategy.SOUTH = 0
CardinalStrategy.EAST = 0
CardinalStrategy.WEST = 0

local CardinalStrategy_mt = Class(CardinalStrategy)

function CardinalStrategy:new(vehicle, customMt)
    if customMt == nil then
        customMt = CardinalStrategy_mt
    end

    local instance = {}

    setmetatable(instance, customMt)

    return instance
end

function CardinalStrategy:delete()
end

function CardinalStrategy:update(dt, data, lastSpeed)
end

function CardinalStrategy:draw(data)
end

function CardinalStrategy:getGuidanceData(guidanceNode, data)
    local cardinal = 0 -- Todo: get cardinal from settings
    local x, y, z = 0,0,0
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
