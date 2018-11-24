
GuidanceUtil = {}

function GuidanceUtil.mathRound(number, idp)
    local multiplier = 10 ^ (idp or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function GuidanceUtil.createABPoint(guidanceNode, data, name)
    local p = createTransformGroup(("AB_point_%s"):format(name))
    local x, _, z = unpack(data.driveTarget)
    if not (x ~= 0 or z ~= 0) then
        x, _, z = getWorldTranslation(guidanceNode)
    end
    local dx, dy, dz = localDirectionToWorld(guidanceNode, 0, 0, 1)
    local upX, upY, upZ = worldDirectionToLocal(guidanceNode, 0, 1, 0)
    local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

    link(getRootNode(), p)

    setTranslation(p, x, y, z)
    setDirection(p, dx, dy, dz, upX, upY, upZ)

    local point = { node = p, name = name }

    return point
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
    local length = MathUtil.vector2Length(dx, dz)
    local dlx = dx / length
    local dlz = dz / length

    return dlx, dlz
end

function GuidanceUtil.getDistanceToHeadLand(self, x, y, z, lookAheadStepDistance)
    if self.lastIsNotOnField then
        local vX, vY, vZ = unpack(self.lastValidGroundPos)
        local dist = MathUtil.vector3Length(vX - x, vY - y, vZ - z)
        return self.distanceToEnd - dist, not self.lastIsNotOnField
    end

    local distanceToHeadLand = lookAheadStepDistance
    local data = self.guidanceData
    local dx, dz = unpack(data.snapDirection)

    local fx = x + lookAheadStepDistance * data.snapDirectionMultiplier * dx * data.movingDirection
    local fz = z + lookAheadStepDistance * data.snapDirectionMultiplier * dz * data.movingDirection

    --    local isOnField = g_currentMission:getIsFieldOwnedAtWorldPos(fx, fz)

    local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, fx, 0, fz)
    local isOnField = densityBits ~= 0

    if self.showGuidanceLines then
        local fy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, 0, fz)
        DebugUtil.drawDebugCircle(fx, fy + .2, fz, 1, 10)
    end

    self.lastIsNotOnField = not isOnField
    if isOnField then
        local distance = self.lastMovedDistance
        local dirX, dirY, dirZ = localDirectionToWorld(self.guidanceNode, 0, 0, distance + 0.75)
        self.lastValidGroundPos = { x + dirX, y + dirY, z + dirZ }
    else
        self.distanceToEnd = lookAheadStepDistance
        local vX, vY, vZ = unpack(self.lastValidGroundPos)
        local dist = MathUtil.vector3Length(vX - x, vY - y, vZ - z)
        distanceToHeadLand = self.distanceToEnd - dist
    end

    return distanceToHeadLand, isOnField
end

function GuidanceUtil:computeCatmullRomSpline(t, p0, p1, p2, p3)
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ^ 2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t ^ 3)
end

function GuidanceUtil.getHasSplinePoint(spline, x, y, z)
    local t = #spline
    local p = spline[t]
    return t > 0
            and p.x == x
            and p.y == y
            and p.z == z
end

function GuidanceUtil:computeSpline(points, smoothingSteps)
    local numOfPoints = #points
    if numOfPoints < 3 then
        return points
    end

    local spline = {}
    local smoothingSteps = smoothingSteps or 5 -- default step 5 times

    for i = 1, numOfPoints - 1 do
        local current = points[i]
        local next = points[math.min(i + 1, numOfPoints)]

        -- Curve controllers
        local p0, p1, p2, p3
        if current.isStartPoint then
            p0, p1, p2, p3 = current, current, next, points[i + 2]
        elseif next.isEndPoint then
            p0, p1, p2, p3 = points[numOfPoints - 2], points[numOfPoints - 1], next, next
        else
            p0, p1, p2, p3 = points[i - 1], current, next, points[i + 2]
        end

        for t = 0, 1, 1 / smoothingSteps do
            local x = GuidanceUtil:computeCatmullRomSpline(t, p0.x, p1.x, p2.x, p3.x)
            local y = GuidanceUtil:computeCatmullRomSpline(t, p0.y, p1.y, p2.y, p3.y)
            local z = GuidanceUtil:computeCatmullRomSpline(t, p0.z, p1.z, p2.z, p3.z)

            if not GuidanceUtil.getHasSplinePoint(spline, x, y, z) then
                local point = {
                    x = x,
                    y = y,
                    z = z
                }

                table.insert(spline, point)
            end
        end
    end

    return spline
end

function GuidanceUtil:getClosestPointIndex(points, x, z, data)
    local closestDistance = math.huge
    local closestPointIndex
    local numPoints = #points

    -- Possible to make this faster? like a merge sort approach? But this isn't always linear
    for i = 1, numPoints do
        local p = points[i]
        local distance = MathUtil.vector2Length(p.x - x, p.z - z)

        if distance < closestDistance then
            closestDistance = distance
            closestPointIndex = 1
            --            if data.snapDirectionMultiplier > 0 then
            --                closestPointIndex = math.min(i + 1, numPoints)
            --            else
            --                closestPointIndex = math.max(i - 1, 1)
            --            end
        end
    end

    return closestPointIndex
end
