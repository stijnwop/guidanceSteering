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

function StraightABStrategy:update(dt)
    for _, point in pairs(self.straightABPoints) do
        DebugUtil.drawDebugNode(point.node, point.name)
    end
end

function StraightABStrategy:draw(data)
    local lines = ABLine
    local drawBotherLines = self:getIsGuidancesPossible()
    local x, _, z, lineDirX, lineDirZ = unpack(data.driveTarget)

    if drawBotherLines then
        lineDirX, lineDirZ = unpack(data.snapDirection)
        lines = ABLines
    end

    local lineXDir = data.snapDirectionMultiplier * lineDirX * data.movingDirection
    local lineZDir = data.snapDirectionMultiplier * lineDirZ * data.movingDirection

    for _, line in pairs(lines) do
        local lineX = x + data.width * lineDirZ * (data.alphaRad + line.position / 2)
        local lineZ = z - data.width * lineDirX * (data.alphaRad + line.position / 2)

        local r, g, b = unpack(line.rgb)

        for l = 1, StraightABStrategy.NUM_STEPS do
            local x1 = lineX + StraightABStrategy.STEP_SIZE * l * lineXDir
            local z1 = lineZ + StraightABStrategy.STEP_SIZE * l * lineZDir
            local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + StraightABStrategy.GROUND_CLEARANCE_OFFSET
            local x2 = lineX + StraightABStrategy.STEP_SIZE * (l + 1) * lineXDir
            local z2 = lineZ + StraightABStrategy.STEP_SIZE * (l + 1) * lineZDir
            local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + StraightABStrategy.GROUND_CLEARANCE_OFFSET

            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)
        end

        -- draw direction arrow
        if line.position == 0 then
            local x = lineX + StraightABStrategy.STEP_SIZE * StraightABStrategy.NUM_STEPS * lineXDir
            local z = lineZ + StraightABStrategy.STEP_SIZE * StraightABStrategy.NUM_STEPS * lineZDir
            local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + StraightABStrategy.GROUND_CLEARANCE_OFFSET
            drawDebugArrow(x, y, z, lineXDir, 0, lineZDir, 0, math.tan(90), 0, r, g, b)
        end
    end
end

function StraightABStrategy:handleABPoints(guidanceNode, data)
    GuidanceUtil.createABPoint(guidanceNode, data, self.straightABPoints)
end

function StraightABStrategy:getGuidanceDirection(guidanceNode)
    local pointA = guidanceNode
    local pointB = self.straightABPoints[1].node
    local numOfABPoints = #self.straightABPoints

    if numOfABPoints >= 2 then
        pointA = self.straightABPoints[1].node
        pointB = self.straightABPoints[2].node
    end

    --    local localDirX, localDirY, localDirZ = localDirectionToLocal(pointA, pointB, 0, 0, 1)
    local localDirX, localDirY, localDirZ = worldDirectionToLocal(pointA, localDirectionToWorld(pointB, 0, 0, 1))

    return { localDirectionToWorld(guidanceNode, localDirX, localDirY, localDirZ) }
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
