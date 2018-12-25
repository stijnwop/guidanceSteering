--
-- StraightABStrategy
--
-- Authors: Wopster
-- Description: Strategy class for AB straight points.
--
-- Copyright (c) Wopster, 2018

StraightABStrategy = {}

StraightABStrategy.STEP_SIZE = 1 -- 1m each line
StraightABStrategy.NUM_STEPS = 15 -- draw 15
StraightABStrategy.GROUND_CLEARANCE_OFFSET = .2

local StraightABStrategy_mt = Class(StraightABStrategy, ABStrategy)

function StraightABStrategy:new(vehicle, customMt)
    if customMt == nil then
        customMt = StraightABStrategy_mt
    end

    local instance = ABStrategy:new(vehicle, customMt)

    return instance
end

function StraightABStrategy:delete()
    StraightABStrategy:superClass().delete(self)
end

function StraightABStrategy:update(dt, data, lastSpeed)
    StraightABStrategy:superClass().update(self, dt)
end

function StraightABStrategy:draw(data)
    StraightABStrategy:superClass().draw(self, data)

    local lines = { ABStrategy.ABLines["middle"] }
    local step = 1
    local numSteps = StraightABStrategy.NUM_STEPS
    local drawBotherLines = self:getIsGuidancesPossible()
    local x, _, z, lineDirX, lineDirZ = unpack(data.driveTarget)

    if drawBotherLines then
        lineDirX, lineDirZ = unpack(data.snapDirection)
        lines = ABStrategy.ABLines
    end

    local drawDirectionLine = self:getIsABDirectionPossible() and not drawBotherLines
    if drawDirectionLine then -- Todo: optimize
        local pointA = self.ab:getPointNode(ABPoint.POINT_A)
        local a = { localToWorld(pointA, 0, 0, 0) }
        local dirX = x - a[1]
        local dirZ = z - a[3]
        local length = MathUtil.vector2Length(dirX, dirZ)
        numSteps = math.max(math.floor(length) - 1, 0)
        step = 2
    end

    local lineXDir = data.snapDirectionMultiplier * lineDirX -- * data.movingDirection
    local lineZDir = data.snapDirectionMultiplier * lineDirZ -- * data.movingDirection

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
    end
end

function StraightABStrategy:getGuidanceData(guidanceNode, data)
    --    if self.vehicle.turningActive then
    --        return StraightABStrategy:superClass().getGuidanceData(self, guidanceNode, data)
    --    end

    local pointA = guidanceNode
    local pointB = self.ab:getPointNode(ABPoint.POINT_A)
    local pointBIsDropped = self:getIsGuidancesPossible()

    if pointBIsDropped then
        pointA = self.ab:getPointNode(ABPoint.POINT_A)
        pointB = self.ab:getPointNode(ABPoint.POINT_B)
    end

    local a = { localToWorld(pointA, 0, 0, 0) }
    local b = { localToWorld(pointB, 0, 0, 0) }

    local dirX = a[1] - b[1]
    local dirZ = a[3] - b[3]
    local length = MathUtil.vector2Length(dirX, dirZ)

    dirX, dirZ = dirX / length, dirZ / length

    local x, y, z = getWorldTranslation(guidanceNode)
    --        local localDirX, localDirY, localDirZ = worldDirectionToLocal(pointA, localDirectionToWorld(pointB, 0, 0, 1))
    --    local dirPoint = pointB
    local dx, dy, dz
    if pointBIsDropped then
        dx, dy, dz = localDirectionToWorld(guidanceNode, worldDirectionToLocal(pointB, dirX, 0, dirZ))
    else
        dx, dz = dirX, dirZ
    end

    -- tx, ty, tz = drive target translation
    -- dirX, dirZ = drive direction
    -- Todo: multiply by movingDirection
    local d = {
        tx = x,
        ty = y,
        tz = z,
        dirX = dx,
        dirZ = dz,
    }

    return d
end
