--
-- ABStrategy
--
-- Authors: Wopster
-- Description: Base class for AB based strategies.
--
-- Copyright (c) Wopster, 2018

ABStrategy = {}

local RGB_WHITE = { 1, 1, 1 }
local RGB_BLUE = { 0, 0, .7 }

ABStrategy.ABLines = {
    ["left"] = { position = -1, rgb = RGB_BLUE },
    ["middle"] = { position = 0, rgb = RGB_WHITE },
    ["right"] = { position = 1, rgb = RGB_BLUE },
}

local ABStrategy_mt = Class(ABStrategy)

function ABStrategy:new(vehicle, customMt)
    if customMt == nil then
        customMt = ABStrategy_mt
    end

    local instance = {}
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")

    instance.ab = ABPoint:new(spec.guidanceNode)
    instance.turnActive = false
    instance.vehicle = vehicle

    setmetatable(instance, customMt)

    return instance
end

function ABStrategy:delete()
    self.ab:purge()
end

function ABStrategy:update(dt)
    self.ab:iterate(function(point)
        DebugUtil.drawDebugNode(point.node, point.name)
    end)
end

function ABStrategy:draw(guidanceData)
end

function ABStrategy:getGuidanceData(guidanceNode, data)
    return nil
end

function ABStrategy:pushABPoint(guidanceData)
    return self.ab:nextPoint(guidanceData)
end

function ABStrategy:getIsGuidancesPossible()
    return self.ab:getIsCreated()
end

function ABStrategy:getHasABDependentDirection()
    return true
end

-- Todo: really needs to be accessible?
function ABStrategy:getIsABDirectionPossible()
    return not self.ab:getIsEmpty()
end
