---
-- GuidanceUtil
--
-- Utility for Guidance Steering
--
-- Copyright (c) Wopster, 2019

GuidanceUtil = {}

function GuidanceUtil.getMaxWorkAreaWidth(guidanceNode, object)
    local maxWidth = 0
    local minWidth = 0
    local workAreaSpec = object:guidanceSteering_getSpecTable("workArea")

    local excludedWorkAreas = {
        ["processRidgeMarkerArea"] = true
    }

    -- Todo: some tools have work area depending on their filltype/sprayType!

    if workAreaSpec ~= nil and workAreaSpec.workAreas ~= nil then
        for _, workArea in pairs(workAreaSpec.workAreas) do
            if excludedWorkAreas[workArea.functionName] == nil then
                local x0, _, _ = localToLocal(guidanceNode, workArea.start, 0, 0, 0)
                local x1, _, _ = localToLocal(guidanceNode, workArea.width, 0, 0, 0)
                local x2, _, _ = localToLocal(guidanceNode, workArea.height, 0, 0, 0)

                maxWidth = math.max(maxWidth, x0, x1, x2)
                minWidth = math.min(minWidth, x0, x1, x2)
            end
        end
    end

    local width = math.abs(maxWidth) + math.abs(minWidth)

    return MathUtil.round(width, 3)
end

function GuidanceUtil.writeGuidanceDataObject(streamId, data)
    -- Todo: currentLane and ... do you we need to sync?

    --local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams


    --
    --NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
    --NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
    --NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
    --
    --streamWriteFloat32(streamId, dirX)
    --streamWriteFloat32(streamId, dirZ)

    --local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
    --local paramsXZ = g_currentMission.vehicleXZPosCompressionParams

    local x, y, z, dirX, dirZ = unpack(data.driveTarget)
    local snapDirX, snapDirZ, snapX, snapZ = unpack(data.snapDirection)

    streamWriteFloat32(streamId, data.width)
    streamWriteInt8(streamId, data.snapDirectionMultiplier)
    streamWriteBool(streamId, data.isCreated)
    streamWriteFloat32(streamId, data.alphaRad)

    --NetworkUtil.writeCompressedWorldPosition(streamId, snapX, paramsXZ)
    --NetworkUtil.writeCompressedWorldPosition(streamId, snapZ, paramsXZ)
    --

    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)
    streamWriteFloat32(streamId, dirX)
    streamWriteFloat32(streamId, dirZ)

    streamWriteFloat32(streamId, snapX)
    streamWriteFloat32(streamId, snapZ)
    streamWriteFloat32(streamId, snapDirX)
    streamWriteFloat32(streamId, snapDirZ)
end

function GuidanceUtil.readGuidanceDataObject(streamId)
    local data = {}
    --local paramsXZ = g_currentMission.vehicleXZPosCompressionParams

    data.width = streamReadFloat32(streamId)
    data.snapDirectionMultiplier = streamReadInt8(streamId)
    data.isCreated = streamReadBool(streamId)
    data.alphaRad = streamReadFloat32(streamId)

    --local snapX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    --local snapZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)

    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    local dirX = streamReadFloat32(streamId)
    local dirZ = streamReadFloat32(streamId)

    data.driveTarget = { x, y, z, dirX, dirZ }

    local snapX = streamReadFloat32(streamId)
    local snapZ = streamReadFloat32(streamId)
    local snapDirX = streamReadFloat32(streamId)
    local snapDirZ = streamReadFloat32(streamId)

    data.snapDirection = { snapDirX, snapDirZ, snapX, snapZ }

    return data
end

function GuidanceUtil.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, r, g, b)
    local sx, sy, sz = project(x, y, z)
    if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextColor(0.0, 0.0, 0.0, 0.75)
        renderText(sx, sy - 0.0015 + textOffset, textSize, text)
        setTextColor(r, g, b, 0.95)
        renderText(sx, sy + textOffset, textSize, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
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
    local spec = self:guidanceSteering_getSpecTable("globalPositioningSystem")

    if spec.lastIsNotOnField then
        local vX, vY, vZ = unpack(spec.lastValidGroundPos)
        local dist = MathUtil.vector3Length(vX - x, vY - y, vZ - z)
        return spec.distanceToEnd - dist, not spec.lastIsNotOnField
    end

    local distanceToHeadLand = lookAheadStepDistance
    local data = spec.guidanceData
    local dx, dz = unpack(data.snapDirection)

    local fx = x + lookAheadStepDistance * data.snapDirectionMultiplier * dx
    local fz = z + lookAheadStepDistance * data.snapDirectionMultiplier * dz

    local bits = getDensityAtWorldPos(g_currentMission.terrainDetailId, fx, 0, fz)
    local isOnField = bits ~= 0

    if spec.showGuidanceLines then
        local fy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, 0, fz)
        DebugUtil.drawDebugCircle(fx, fy + .2, fz, 1, 10)
    end

    spec.lastIsNotOnField = not isOnField
    if isOnField then
        local distance = self.lastMovedDistance
        local dirX, dirY, dirZ = localDirectionToWorld(spec.guidanceNode, 0, 0, distance + 0.75)
        spec.lastValidGroundPos = { x + dirX, y + dirY, z + dirZ }
    else
        spec.distanceToEnd = lookAheadStepDistance
        local vX, vY, vZ = unpack(spec.lastValidGroundPos)
        local dist = MathUtil.vector3Length(vX - x, vY - y, vZ - z)
        distanceToHeadLand = spec.distanceToEnd - dist
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
