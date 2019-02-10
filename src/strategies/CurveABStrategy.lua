---
-- CurveABStrategy
--
-- Strategy class for AB curve points.
--
-- Copyright (c) Wopster, 2018

CurveABStrategy = {}

local CurveABStrategy_mt = Class(CurveABStrategy)

local ABLine = {
    ["middle"] = { position = 0, rgb = { 1, 1, 1 } }
}

local ABLines = {
    ["left"] = { position = -1, rgb = { 0, 0, .7 } },
    --    ["middle"] = { position = 0, rgb = { 1, 1, 1 } },
    ["right"] = { position = 1, rgb = { 0, 0, .7 } },
}

CurveABStrategy.STEP_SIZE = 1 -- 1m each line
CurveABStrategy.NUM_STEPS = 15 -- draw 15
CurveABStrategy.GROUND_CLEARANCE_OFFSET = .2

function CurveABStrategy:new(customMt)
    local instance = {}
    
    setmetatable(instance, customMt or CurveABStrategy_mt)

    instance.curvedABPoints = {} -- {id = object pointer, name = render name}
    instance.curve = {}
    instance.offsetCurves = {} -- draw only
    instance.segmentPoints = {}
    instance.linkedSegmentPoints = nil
    instance.segmentGenerated = false

    instance.segmentInterval = 1 / (0.75 * 0.001) -- ms
    instance.firstInterval = true
    instance.segmentDt = 0

    return instance
end

function CurveABStrategy:delete()
    GuidanceUtil.deleteABPoints(self.curvedABPoints)
    self.curvedABPoints = {}
    self.segmentPoints = {}
    self.linkedSegmentPoints = {}
    self.curve = {}
    self.offsetCurves = {}

    self.firstInterval = true
    self.segmentGenerated = false
end

function CurveABStrategy:update(dt, data, guidanceNode, lastSpeed)

    for _, point in pairs(self.curvedABPoints) do
        DebugUtil.drawDebugNode(point.node, point.name)
    end

    local generate = self:getIsGuidancePossible()

    if generate then
        --        local numSegements = #self.curve
        --        for i = 1, numSegements do
        --            --            local distance = length / numSegements
        --            local dot = self.curve[i]
        --            local dot2 = self.curve[math.min(i + 1, numSegements)]
        --            drawDebugLine(dot.x, dot.y, dot.z, 1, 1, 1, dot2.x, dot2.y, dot2.z, 1, 1, 1)
        --            drawDebugPoint(dot.x, dot.y, dot.z, 1, 0, 0, 1)
        --            drawDebugPoint(dot2.x, dot2.y, dot2.z, 0, 1, 0, 1)
        --        end
    end

    if self.segmentGenerated then
        self.curve = self:createParallelSpline(self.segmentPoints, data, data.alphaRad)

        return
    end

    -- spline generation
    if self:getIsABDirectionPossible()
            and not generate then
        if self.firstInterval then
            --            local x, y, z = getWorldTranslation(self.curvedABPoints[1].node)
            local x, y, z = localToWorld(self.curvedABPoints[1].node, 0, 0, 0)

            local segment = {
                x = x,
                y = y,
                z = z,
                isStartPoint = true,
                isEndPoint = false
            }

            table.insert(self.segmentPoints, segment)

            self.linkedSegmentPoints = LinkedList:new()
            print(print_r(self.linkedSegmentPoints))
            self.linkedSegmentPoints:add(segment)

            self.firstInterval = false
        else
            if lastSpeed > 1 then
                self.segmentDt = self.segmentDt + dt

                if self.segmentDt > self.segmentInterval then
                    local x, y, z = localToWorld(guidanceNode, 0, 0, 0)
                    --                    local x, y, z = unpack(data.driveTarget)
                    print(("old drop segment x: %.1f y: %.1f z: %.1f "):format(x, y, z))

                    local segment = {
                        x = x,
                        y = y,
                        z = z,
                        isStartPoint = false,
                        isEndPoint = false
                    }

                    table.insert(self.segmentPoints, segment)
                    self.linkedSegmentPoints:add(segment)

                    self.segmentDt = 0
                end
            end
        end
    end

    -- just draw for now
    if generate and not self.segmentGenerated then
        print("generate")
        local x, y, z = localToWorld(self.curvedABPoints[2].node, 0, 0, 0)
        --        local x, y, z = getWorldTranslation(self.curvedABPoints[2].node)

        local segment = {
            x = x,
            y = y,
            z = z,
            isStartPoint = false,
            isEndPoint = true
        }

        table.insert(self.segmentPoints, segment)
        self.linkedSegmentPoints:add(segment)
        self.linkedSegmentPoints:iterateInsertOrder()

        self.segmentGenerated = true

        --        self.curve = GuidanceUtil:computeSpline(self.segmentPoints, 3)

        --        self.offsetCurves = {}
        --        for _, line in pairs(ABLines) do
        --            local c = self:createParallelSpline(self.segmentPoints, data, data.alphaRad + line.position / 2)
        --            table.insert(self.offsetCurves, c)
        --        end
    end
end

function CurveABStrategy:createParallelSpline(points, data, dir)
    local numOfPoints = #points
    local parallelPoints = {}

    local lineDirX, lineDirZ = unpack(data.snapDirection)

    local lineXDir = data.snapDirectionMultiplier * lineDirX * data.movingDirection
    local lineZDir = data.snapDirectionMultiplier * lineDirZ * data.movingDirection

    for i = 1, numOfPoints do
        local p = points[i]
        --        local pNext = points[math.max(numOfPoints - i, 1)]
        local pNext = points[math.min(i + 1, numOfPoints)]

        if i == numOfPoints then
            pNext = points[i - 1]
        end

        local dirX, dirZ = pNext.x - p.x, pNext.z - p.z

        if i == numOfPoints then
            dirX, dirZ = p.x - pNext.x, p.z - pNext.z
        end

        local length = math.sqrt(dirX * dirX + dirZ * dirZ)
        -- normalize
        if length and length > 0.0001 then
            dirX = dirX / length
            dirZ = dirZ / length
        end

        local x = p.x + data.width * dirZ * dir * lineXDir
        local z = p.z - data.width * dirX * dir * lineZDir
        -- Todo: only needed for draw
        local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        local point = {
            x = x,
            y = y,
            z = z,
            isStartPoint = i == 1,
            isEndPoint = i == numOfPoints
        }

        table.insert(parallelPoints, point)
    end

    -- if recompute
    return GuidanceUtil:computeSpline(parallelPoints, 3)
    --    return parallelPoints
end

function CurveABStrategy:draw(data)
    local lines = ABLine
    local drawBotherLines = self:getIsGuidancePossible()

    if drawBotherLines then
        lines = ABLines
    end

    local function drawCurve(c, r, g, b)
        local numSegements = #c

        for i = 1, numSegements do
            local dot = c[i]
            local dot2 = c[math.min(i + 1, numSegements)]
            drawDebugLine(dot.x, dot.y + .2, dot.z, r, g, b, dot2.x, dot2.y + .2, dot2.z, r, g, b)
        end
    end

    drawCurve(self.curve, 1, 1, 1)

    -- Todo: draw parts of the curve
    if drawBotherLines then
        --        for _, line in pairs(lines) do
        --            local c = self:createParallelSpline(self.segmentPoints, data, data.alphaRad + line.position / 2)
        --            local r, g, b = unpack(line.rgb)
        --            drawCurve(c, r, g, b)
        --        end
    end
end

-- Todo: duplicate on straight
function CurveABStrategy:getGuidanceData(guidanceNode, data)
    local validCurve = #self.curve ~= 0
    local x, y, z = getWorldTranslation(guidanceNode)
    local dirX, dirZ

    if not validCurve then
        dirX, _, dirZ = localDirectionToWorld(guidanceNode, 0, 0, 1)
        --        x, y, z = getWorldTranslation(guidanceNode)
    else
        local index = GuidanceUtil:getClosestPointIndex(self.curve, x, z, data)
        -- Todo: save last index
        -- Todo: draw from this point for performance
        local p = self.curve[index]
        dirX, dirZ = p.x - x, p.z - z
        local length = math.sqrt(dirX * dirX + dirZ * dirZ)
        -- normalize
        --    if length and length > 0.0001 then
        dirX = dirX / length
        dirZ = dirZ / length
        --    end
        x, y, z = p.x, p.y, p.z
    end

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

function CurveABStrategy:pushABPoint(guidanceNode, data)
    GuidanceUtil.createABPoint(guidanceNode, data, self.curvedABPoints)
end

function CurveABStrategy:getIsGuidancePossible()
    return #self.curvedABPoints == 2
end

function CurveABStrategy:getRequiresABDirection()
    return true
end

function CurveABStrategy:getIsABDirectionPossible()
    return #self.curvedABPoints > 0
end
