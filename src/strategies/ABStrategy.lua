--
-- ABStrategy
--
-- Authors: Wopster
-- Description: Base class for AB based strategies.
--
-- Copyright (c) Wopster, 2018

ABStrategy = {}

ABStrategy.AB = 0
ABStrategy.A_AUTO_B = 1
ABStrategy.A_PLUS_HEADING = 2

ABStrategy.METHODS = {
    ABStrategy.AB,
    ABStrategy.A_AUTO_B,
    ABStrategy.A_PLUS_HEADING
}

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

---Gets the guidance drive data
---@param guidanceNode number
---@param data table
function ABStrategy:getGuidanceData(guidanceNode, data)
    return nil
end

---Creates the next AB point
---@param guidanceData table
function ABStrategy:pushABPoint(guidanceData)
    return self.ab:nextPoint(guidanceData)
end

---Gets if guidance can be activated
function ABStrategy:getIsGuidancePossible()
    return self.ab:getIsCreated()
end

---Returns if this strategy is AB depended
function ABStrategy:getHasABDependentDirection()
    return true
end

---Returns if we can guide based on AB points
function ABStrategy:getIsABDirectionPossible()
    return not self.ab:getIsEmpty()
end

---Gets the UI texts for the methods
---@param i18n table
function ABStrategy:getTexts(i18n)
    -- Remember the order is important here.
    return {
        i18n:getText("guidanceSteering_strategyMethod_aPlusB"), -- ABStrategy.AB
        i18n:getText("guidanceSteering_strategyMethod_autoB"), -- ABStrategy.A_AUTO_B
        i18n:getText("guidanceSteering_strategyMethod_aPlusHeading") -- ABStrategy.A_PLUS_HEADING
    }
end
