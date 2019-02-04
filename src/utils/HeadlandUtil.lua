HeadlandUtil = {}

function HeadlandUtil:getHeadLandMode()

end

function HeadlandUtil.getDistanceToHeadLand(processor, object, x, y, z, lookAheadStepDistance)
    if processor.lastIsNotOnField then
        local vX, vY, vZ = unpack(processor.lastValidGroundPos)
        local dist = MathUtil.vector3Length(vX - x, vY - y, vZ - z)
        return processor.distanceToEnd - dist, not processor.lastIsNotOnField
    end

    local distanceToHeadLand = lookAheadStepDistance
    local data = object:getGuidanceData()
    local dx, dz = unpack(data.snapDirection)

    local fx = x + lookAheadStepDistance * data.snapDirectionMultiplier * dx
    local fz = z + lookAheadStepDistance * data.snapDirectionMultiplier * dz

    local bits = getDensityAtWorldPos(g_currentMission.terrainDetailId, fx, 0, fz)
    local isOnField = bits ~= 0

    --if spec.showGuidanceLines then
        local fy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, 0, fz)
        DebugUtil.drawDebugCircle(fx, fy + .2, fz, 1, 10)
    --end

    processor.lastIsNotOnField = not isOnField
    if isOnField then
        local spec = object:guidanceSteering_getSpecTable("globalPositioningSystem")
        local distance = object.lastMovedDistance
        local dirX, dirY, dirZ = localDirectionToWorld(spec.guidanceNode, 0, 0, distance + 0.75)
        processor.lastValidGroundPos = { x + dirX, y + dirY, z + dirZ }
    else
        processor.distanceToEnd = lookAheadStepDistance
        local vX, vY, vZ = unpack(processor.lastValidGroundPos)
        local dist = MathUtil.vector3Length(vX - x, vY - y, vZ - z)
        distanceToHeadLand = processor.distanceToEnd - dist
    end

    return distanceToHeadLand, isOnField
end