---
-- GuidanceUtil
--
-- Utility for Guidance Steering
--
-- Copyright (c) Wopster, 2019

GuidanceUtil = {}

---Gets the current active spray type when dealing with spray type configurations
---@param object table
function GuidanceUtil.getActiveSprayType(object)
    local activeSprayType

    if object.getIsSprayTypeActive ~= nil then
        local sprayerSpec = object:guidanceSteering_getSpecTable("sprayer")
        for id, sprayType in pairs(sprayerSpec.sprayTypes) do
            if object:getIsSprayTypeActive(sprayType) then
                activeSprayType = id
                break
            end
        end
    end

    return activeSprayType
end

---Calculates the work width
---@param object table
function GuidanceUtil.getMaxWorkAreaWidth(object)
    local workAreaSpec = object:guidanceSteering_getSpecTable("workArea")

    local calculateWorkAreas = true
    if workAreaSpec == nil or #workAreaSpec.workAreas == 0 then
        calculateWorkAreas = false
    end

    local maxWidth, minWidth = 0, 0

    local function createGuideNode(name, linkNode)
        local node = createTransformGroup(name)
        link(linkNode, node)
        setTranslation(node, 0, 0, 0)
        return node
    end

    local node = createGuideNode("width_node", object.rootNode)

    if calculateWorkAreas then
        local activeSprayType = GuidanceUtil.getActiveSprayType(object)
        -- Exclude ridged markers from workArea calculation
        local skipWorkAreas = {
            ["processRidgeMarkerArea"] = true
        }

        local function isWorkAreaValid(workArea)
            if skipWorkAreas[workArea.functionName] ~= nil then
                return false
            end

            if (activeSprayType ~= nil and workArea.sprayType ~= activeSprayType) then
                return false
            end

            return workArea.type ~= WorkAreaType.AUXILIARY
        end

        local function toLocalArea(workArea)
            if not isWorkAreaValid(workArea) then
                return nil -- will GC table value cause ipairs
            end

            local x0 = localToLocal(workArea.start, node, 0, 0, 0)
            local x1 = localToLocal(workArea.width, node, 0, 0, 0)
            local x2 = localToLocal(workArea.height, node, 0, 0, 0)

            return { x0, x1, x2 }
        end

        local areaWidths = stream(workAreaSpec.workAreas):map(toLocalArea):toList()
        maxWidth = stream(areaWidths):reduce(0, function(r, e)
            return math.max(r, unpack(e))
        end)
        minWidth = stream(areaWidths):reduce(math.huge, function(r, e)
            return math.min(r, unpack(e))
        end)
    end

    local width = maxWidth + math.abs(minWidth)
    local leftMarker, rightMarker = object:getAIMarkers()
    if leftMarker ~= nil and rightMarker ~= nil then
        local lx = localToLocal(leftMarker, node, 0, 0, 0)
        local rx = localToLocal(rightMarker, node, 0, 0, 0)
        width = math.max(math.abs(lx - rx), width)
    end

    local offset = (minWidth + maxWidth) * 0.5
    if math.abs(offset) < 0.1 then
        offset = 0
    end

    delete(node)

    return MathUtil.round(width, 3), MathUtil.round(offset, 3)
end

---Writes the guidance data with compressed values
---@param streamId number
---@param data table
function GuidanceUtil.writeGuidanceDataObject(streamId, data)
    local x, y, z, dirX, dirZ = unpack(data.driveTarget)
    local snapDirX, snapDirZ, snapX, snapZ = unpack(data.snapDirection)

    -- Compress width to int cause we round on the 3th decimal
    streamWriteUInt16(streamId, math.floor(data.width * 1000))
    streamWriteFloat32(streamId, data.offsetWidth)

    streamWriteBool(streamId, data.snapDirectionMultiplier ~= nil)
    if data.snapDirectionMultiplier ~= nil then
        streamWriteUIntN(streamId, data.snapDirectionMultiplier, 2)
    end

    streamWriteBool(streamId, data.alphaRad ~= nil)
    -- Todo: think we don't need this
    if data.alphaRad ~= nil then
        streamWriteFloat32(streamId, data.alphaRad) -- don't compress alphaRad
    end

    local compressionParamsXZ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
    local compressionParamsY = g_currentMission.vehicleXZPosHighPrecisionCompressionParams

    NetworkUtil.writeCompressedWorldPosition(streamId, x, compressionParamsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, y, compressionParamsY)
    NetworkUtil.writeCompressedWorldPosition(streamId, z, compressionParamsXZ)

    NetworkUtil.writeCompressedWorldPosition(streamId, dirX, compressionParamsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, dirZ, compressionParamsXZ)

    NetworkUtil.writeCompressedWorldPosition(streamId, snapX, compressionParamsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, snapZ, compressionParamsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, snapDirX, compressionParamsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, snapDirZ, compressionParamsXZ)
end

---Reads the compressed values from the network packet
---@param streamId number
function GuidanceUtil.readGuidanceDataObject(streamId)
    local data = {}

    data.width = streamReadUInt16(streamId) / 1000
    data.offsetWidth = streamReadFloat32(streamId)

    if streamReadBool(streamId) then
        data.snapDirectionMultiplier = streamReadUIntN(streamId, 2)
    end

    if streamReadBool(streamId) then
        data.alphaRad = streamReadFloat32(streamId)
    end

    local compressionParamsXZ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
    local compressionParamsY = g_currentMission.vehicleXZPosHighPrecisionCompressionParams

    local x = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)
    local y = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsY)
    local z = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)

    local dirX = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)
    local dirZ = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)

    data.driveTarget = { x, y, z, dirX, dirZ }

    local snapX = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)
    local snapZ = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)
    local snapDirX = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)
    local snapDirZ = NetworkUtil.readCompressedWorldPosition(streamId, compressionParamsXZ)

    data.snapDirection = { snapDirX, snapDirZ, snapX, snapZ }

    return data
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
