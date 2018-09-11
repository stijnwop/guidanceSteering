StraightABStrategy = {}

local ABLine = {
    ["middle"] = { position = 0, rgb = { 1, 1, 1 } }
}

local ABLines = {
    ["left"] = { position = -1, rgb = { 0, 0, .7 } },
    ["middle"] = { position = 0, rgb = { 1, 1, 1 } },
    ["right"] = { position = 1, rgb = { 0, 0, .7 } },
}

StraightABStrategy.STEP_SIZE = 1 -- 1m each line
StraightABStrategy.NUM_STEPS = 15 -- draw 15
StraightABStrategy.GROUND_CLEARANCE_OFFSET = .2

local StraightABStrategy_mt = Class(StraightABStrategy)

function StraightABStrategy:new(customMt)
    if customMt == nil then
        customMt = StraightABStrategy_mt
    end

    local instance = {}

    instance.straightABPoints = {} -- {id = object pointer, name = render name}

    setmetatable(instance, customMt)

    return instance
end

function StraightABStrategy:delete()
    GuidanceUtil.deleteABPoints(self.straightABPoints)
    self.straightABPoints = {}
end

function StraightABStrategy:update(dt, data, lastSpeed)
    for _, point in pairs(self.straightABPoints) do
        DebugUtil.drawDebugNode(point.node, point.name)
    end
end

function StraightABStrategy:draw(data)
    local lines = ABLine
    local step = 1
    local numSteps = StraightABStrategy.NUM_STEPS
    local drawBotherLines = self:getIsGuidancesPossible()
    local x, _, z, lineDirX, lineDirZ = unpack(data.driveTarget)

    if drawBotherLines then
        lineDirX, lineDirZ = unpack(data.snapDirection)
        lines = ABLines
    end

    local drawDirectionLine = self:getIsABDirectionPossible() and not drawBotherLines
    if drawDirectionLine then -- Todo: optimize
        --        local a = { localToWorld(self.straightABPoints[1].node, 0, 0, 0) }
        local a = { localToWorld(self.straightABPoints[1].node, 0, 0, 0) }
        local dirX = x - a[1]
        local dirZ = z - a[3]
        local length = Utils.vector2Length(dirX, dirZ)
        numSteps = math.max(math.floor(length) - 1, 0)
        step = 2
    end

    local lineXDir = data.snapDirectionMultiplier * lineDirX * data.movingDirection
    local lineZDir = data.snapDirectionMultiplier * lineDirZ * data.movingDirection

    for _, line in pairs(lines) do
        local lineX = x + data.width * lineDirZ * (data.alphaRad + line.position / 2)
        local lineZ = z - data.width * lineDirX * (data.alphaRad + line.position / 2)

        local r, g, b = unpack(line.rgb)

        for l = 1, numSteps, step do
            local x1 = lineX + StraightABStrategy.STEP_SIZE * l * lineXDir
            local z1 = lineZ + StraightABStrategy.STEP_SIZE * l * lineZDir
            local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + StraightABStrategy.GROUND_CLEARANCE_OFFSET
            local x2 = lineX + StraightABStrategy.STEP_SIZE * (l + 1) * lineXDir
            local z2 = lineZ + StraightABStrategy.STEP_SIZE * (l + 1) * lineZDir
            local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + StraightABStrategy.GROUND_CLEARANCE_OFFSET

            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)
        end

        -- draw direction arrow
        if not drawDirectionLine and line.position == 0 then
            local x = lineX + StraightABStrategy.STEP_SIZE * numSteps * lineXDir
            local z = lineZ + StraightABStrategy.STEP_SIZE * numSteps * lineZDir
            local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + StraightABStrategy.GROUND_CLEARANCE_OFFSET
            drawDebugArrow(x, y, z, lineXDir, 0, lineZDir, 0, math.tan(90), 0, r, g, b)
        end
    end
end

function StraightABStrategy:handleABPoints(guidanceNode, data)
    GuidanceUtil.createABPoint(guidanceNode, data, self.straightABPoints)
end

function StraightABStrategy:getGuidanceData(guidanceNode, data)
    local pointA = guidanceNode
    local pointB = self.straightABPoints[1].node
    local pointBIsDropped = self:getIsGuidancesPossible()

    if pointBIsDropped then
        pointA = self.straightABPoints[1].node
        pointB = self.straightABPoints[2].node
    end

    local a = { localToWorld(pointA, 0, 0, 0) }
    local b = { localToWorld(pointB, 0, 0, 0) }

    local dirX = a[1] - b[1]
    local dirZ = a[3] - b[3]
    local length = Utils.vector2Length(dirX, dirZ)

    dirX, dirZ = dirX / length, dirZ / length

    local x, y, z = getWorldTranslation(guidanceNode)
    --        local localDirX, localDirY, localDirZ = worldDirectionToLocal(pointA, localDirectionToWorld(pointB, 0, 0, 1))
--    local dirPoint = pointB
    if pointBIsDropped then
        dirX, _, dirZ = localDirectionToWorld(guidanceNode, worldDirectionToLocal(pointB, dirX, 0, dirZ))
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

function StraightABStrategy:getIsGuidancesPossible()
    return #self.straightABPoints == 2
end

function StraightABStrategy:getRequiresABDirection()
    return true
end

function StraightABStrategy:getIsABDirectionPossible()
    return #self.straightABPoints > 0
end
