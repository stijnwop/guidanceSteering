---
-- CardinalStrategy
--
-- Strategy class for cardinal degrees also called A+heading.
--
-- Copyright (c) Wopster, 2018

CardinalStrategy = {}

local CardinalStrategy_mt = Class(CardinalStrategy, ABStrategy)

function CardinalStrategy:new(vehicle, customMt)
    local instance = ABStrategy:new(vehicle, customMt or CardinalStrategy_mt)

    instance.currentCardinal = nil

    return instance
end

function CardinalStrategy:delete()
    CardinalStrategy:superClass().delete(self)
    self.currentCardinal = nil
end

function CardinalStrategy:update(dt)
    CardinalStrategy:superClass().update(self, dt)
end

function CardinalStrategy:draw(data, guidanceSteeringIsActive, autoInvertOffset)
    CardinalStrategy:superClass().draw(self, data, guidanceSteeringIsActive, autoInvertOffset)
end

local function showCardinalDialog(target)
    g_gui:showTextInputDialog({
        text = "Desired cardinal (degrees)",
        defaultText = "0",
        maxCharacters = 3,
        target = target,
        callback = CardinalStrategy.cardinalCallback,
        confirmText = "Set cardinal"
    })
end

function CardinalStrategy:pushABPoint(guidanceData)
    if self.ab:getIsEmpty() then
        showCardinalDialog(self)
        return self.ab:nextPoint(guidanceData)
    end
end

function CardinalStrategy:cardinalCallback(cardinal)
    cardinal = tonumber(cardinal)
    if cardinal ~= nil then
        self.currentCardinal = MathUtil.degToRad(cardinal)

        local spec = self.vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        if spec.lineStrategy:getIsGuidancePossible() then
            -- When possible we do handle the next event directly.
            spec.multiActionEvent:reset()
            GlobalPositioningSystem.computeGuidanceDirection(self.vehicle)
        end
    else
        showCardinalDialog(self)
    end
end

---Gets the guidance drive data for the given cardinals
---@param guidanceNode number
---@param data table
function CardinalStrategy:getGuidanceData(guidanceNode, data)
    local pointA = self.ab:getPointNode(ABPoint.POINT_A)

    local x, y, z = getWorldTranslation(guidanceNode)
    local dx, dz = 0, 0
    if self.currentCardinal ~= nil then
        local cardinal = self.currentCardinal + math.pi
        dx, dz = math.sin(cardinal), -math.cos(cardinal)
    else
        local a = { localToWorld(guidanceNode, 0, 0, 0) }
        local b = { localToWorld(pointA, 0, 0, 0) }

        local dirX = a[1] - b[1]
        local dirZ = a[3] - b[3]
        local length = MathUtil.vector2Length(dirX, dirZ)

        dx, dz = dirX / length, dirZ / length
    end

    return { x, y, z, dx, dz }
end

function CardinalStrategy:getIsGuidancePossible()
    return self.ab:getPointNode(ABPoint.POINT_A) ~= nil
end

function CardinalStrategy:needsDrivingDistanceThreshold()
    return false
end
