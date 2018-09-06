--
-- Created by IntelliJ IDEA.
-- User: Wopereis
-- Date: 8/28/2018
-- Time: 6:40 PM
-- To change this template use File | Settings | File Templates.
--

GuidanceUtil = {}
GuidanceUtil.POINT_NAMES = { "A", "B", "C", "D", "E", "F" }

function GuidanceUtil.mathRound(number, idp)
    local multiplier = 10 ^ (idp or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function GuidanceUtil.createABPoint(guidanceNode, data, points)
    local numOfPoints = #points
    local name = GuidanceUtil.POINT_NAMES[math.max(numOfPoints + 1, numOfPoints)]

    local p = createTransformGroup(("AB_point_%s"):format(name))
    local x, _, z = unpack(data.driveTarget)
    local dx, dy, dz = localDirectionToWorld(guidanceNode, 0, 0, 1)
    local upX, upY, upZ = worldDirectionToLocal(guidanceNode, 0, 1, 0)
    local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

    link(getRootNode(), p)

    setTranslation(p, x, y, z)
    setDirection(p, dx, dy, dz, upX, upY, upZ)

    local point = { node = p, name = name }

    table.insert(points, point)
end


function GuidanceUtil.deleteABPoints(points)
    for _, point in pairs(points) do
        delete(point.node)
    end
end

function GuidanceUtil.getMaxWorkAreaWidth(guidanceNode, object)
    local maxWidth = 0
    local minWidth = 0

    if object.workAreas ~= nil then
        for _, workArea in pairs(object.workAreas) do
            local x0, _, _ = localToLocal(guidanceNode, workArea.start, 0, 0, 0)
            local x1, _, _ = localToLocal(guidanceNode, workArea.width, 0, 0, 0)
            local x2, _, _ = localToLocal(guidanceNode, workArea.height, 0, 0, 0)

            maxWidth = math.max(maxWidth, x0, x1, x2)
            minWidth = math.min(minWidth, x0, x1, x2)
        end
    end

    local width = math.abs(maxWidth) + math.abs(minWidth)

    return GuidanceUtil.mathRound(width, 2)
end

function GuidanceUtil.aProjectOnLine(px, pz, lineX, lineZ, lineDirX, lineDirZ)
    local dot = GuidanceUtil.getAProjectOnLineParameter(px, pz, lineX, lineZ, lineDirX, lineDirZ)

    return lineX + lineDirX * dot, lineZ + lineDirZ * dot
end

function GuidanceUtil.getAProjectOnLineParameter(px, pz, lineX, lineZ, lineDirX, lineDirZ)
    local dx, dz = px - lineX, pz - lineZ
    local dot = dx * lineDirX - dz * lineDirZ

    return dot
end

function GuidanceUtil.getDriveDirection(dx, dz)
    local length = Utils.vector2Length(dx, dz)
    local dlx = dx / length
    local dlz = dz / length

    return dlx, dlz
end

function GuidanceUtil.getDistanceToHeadLand(self, x, y, z, lookAheadStepDistance)
    if self.lastIsNotOnField then
        local vX, vY, vZ = unpack(self.lastValidGroundPos)
        local dist = Utils.vector3Length(vX - x, vY - y, vZ - z)
        return self.distanceToEnd - dist, not self.lastIsNotOnField
    end

    local distanceToHeadLand = lookAheadStepDistance
    local data = self.guidanceData
    local dx, dz = unpack(data.snapDirection)

    local fx = x + lookAheadStepDistance * data.snapDirectionFactor * dx * data.movingDirection
    local fz = z + lookAheadStepDistance * data.snapDirectionFactor * dz * data.movingDirection

    --    local isOnField = g_currentMission:getIsFieldOwnedAtWorldPos(fx, fz)

    local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, fx, 0, fz)
    local isOnField = densityBits ~= 0

    -- Todo: if debug
    local fy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, 0, fz)
    DebugUtil.drawDebugCircle(fx, fy + .2, fz, 1, 10)
    --

    self.lastIsNotOnField = not isOnField
    if isOnField then
        local distance = self.lastMovedDistance
        local dirX, dirY, dirZ = localDirectionToWorld(self.guidanceNode, 0, 0, distance + 0.75)
        self.lastValidGroundPos = { x + dirX, y + dirY, z + dirZ }
    else
        self.distanceToEnd = lookAheadStepDistance
        local vX, vY, vZ = unpack(self.lastValidGroundPos)
        local dist = Utils.vector3Length(vX - x, vY - y, vZ - z)
        distanceToHeadLand = self.distanceToEnd - dist
    end

    return distanceToHeadLand, isOnField
end
