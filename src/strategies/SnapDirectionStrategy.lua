---
-- SnapDirectionStrategy
--
-- Strategy class for heading radians (A+direction).
--
-- Copyright (c) Wopster, 2022

---@class SnapDirectionStrategy: ABStrategy
SnapDirectionStrategy = {}

local CardinalStrategy_mt = Class(SnapDirectionStrategy, ABStrategy)

function SnapDirectionStrategy:new(vehicle, customMt)
    local instance = ABStrategy:new(vehicle, customMt or CardinalStrategy_mt)

    instance.currentDirection = nil
    instance.id = ABStrategy.A_PLUS_DIRECTION

    return instance
end

function SnapDirectionStrategy:readStream(streamId, connection)
    SnapDirectionStrategy:superClass().readStream(self, streamId, connection)

    if streamReadBool(streamId) then
        self.currentDirection = streamReadFloat32(streamId)
    end
end

function SnapDirectionStrategy:writeStream(streamId, connection)
    SnapDirectionStrategy:superClass().writeStream(self, streamId, connection)

    streamWriteBool(streamId, self.currentDirection ~= nil)
    if self.currentDirection ~= nil then
        streamWriteFloat32(streamId, self.currentDirection)
    end
end

function SnapDirectionStrategy:delete()
    SnapDirectionStrategy:superClass().delete(self)
    self.currentDirection = nil
end

function SnapDirectionStrategy:interact(guidanceData)
    if self.ab:getIsEmpty() then
        self.ab:nextPoint(guidanceData)

        local spec = self.vehicle.spec_globalPositioningSystem
        local dirX, _, dirZ = localDirectionToWorld(spec.guidanceNode, 0, 0, 1)
        self.currentDirection = math.abs(MathUtil.getYRotationFromDirection(dirX, dirZ) - math.pi)

        if spec.lineStrategy:getIsGuidancePossible() then
            -- When possible we do handle the next event directly.
            spec.multiActionEvent:reset()
            self.vehicle:interactWithGuidanceStrategy() -- call again for event.
            GlobalPositioningSystem.computeGuidanceDirection(self.vehicle)
        end
    end
end

---Gets the guidance drive data for the given cardinals
---@param guidanceNode number
---@param data table
function SnapDirectionStrategy:getGuidanceData(guidanceNode, data)
    local x, y, z = getWorldTranslation(guidanceNode)
    local dx, dz = 0, 0

    if self.currentDirection ~= nil then
        local cardinal = self.currentDirection + math.pi
        dx, dz = math.sin(cardinal), -math.cos(cardinal)
    end

    return { x, y, z, dx, dz }
end

function SnapDirectionStrategy:getIsGuidancePossible()
    return self.ab:getPointNode(ABPoint.POINT_A) ~= nil
end

function SnapDirectionStrategy:needsDrivingDistanceThreshold()
    return false
end
