--
-- ABStrategy
--
-- Authors: Wopster
-- Description: Base class for AB based strategies.
--
-- Copyright (c) Wopster, 2018

ABStrategy = {}

ABStrategy.AB = 0
ABStrategy.A_AUTO_B = 1
ABStrategy.A_PLUS_HEADING = 2

ABStrategy.METHODS = {
    ABStrategy.AB,
    ABStrategy.A_AUTO_B,
    ABStrategy.A_PLUS_HEADING
}

local RGB_WHITE = { 1, 1, 1 }
local RGB_BLUE = { 0, 0, .7 }

ABStrategy.ABLines = {
    ["left"] = { position = -1, rgb = RGB_BLUE },
    ["middle"] = { position = 0, rgb = RGB_WHITE },
    ["right"] = { position = 1, rgb = RGB_BLUE },
}

ABStrategy.STEP_SIZE = 1 -- 1m each line
ABStrategy.NUM_STEPS = 15 -- draw 15
ABStrategy.GROUND_CLEARANCE_OFFSET = .2

local ABStrategy_mt = Class(ABStrategy)

---Create a new instance of the ABStrategy
---@param vehicle table
---@param customMt table
function ABStrategy:new(vehicle, customMt)
    if customMt == nil then
        customMt = ABStrategy_mt
    end

    local instance = {}
    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")

    instance.ab = ABPoint:new(spec.guidanceNode)
    instance.turnActive = false
    instance.vehicle = vehicle

    setmetatable(instance, customMt)

    return instance
end

---Delete
function ABStrategy:delete()
    self.ab:purge()
end

---Update
---@param dt number
function ABStrategy:update(dt)
    self.ab:iterate(function(point)
        DebugUtil.drawDebugNode(point.node, point.name)
    end)
end

---Draw
---@param data table
function ABStrategy:draw(data)
    local lines = { ABStrategy.ABLines["middle"] }
    local step = 1
    local numSteps = ABStrategy.NUM_STEPS
    --local drawBotherLines = self:getIsGuidancePossible()
    local drawBotherLines = data.isCreated
    local x, _, z, lineDirX, lineDirZ = unpack(data.driveTarget)

    if drawBotherLines then
        lineDirX, lineDirZ = unpack(data.snapDirection)
        lines = ABStrategy.ABLines
    end

    local drawDirectionLine = self:getIsABDirectionPossible() and not drawBotherLines
    if drawDirectionLine then
        -- Todo: optimize
        local pointA = self.ab:getPointNode(ABPoint.POINT_A)
        local a = { localToWorld(pointA, 0, 0, 0) }
        local dirX = x - a[1]
        local dirZ = z - a[3]
        local length = MathUtil.vector2Length(dirX, dirZ)
        numSteps = math.max(math.floor(length) - 1, 0)
        step = 2
    end

    local lineXDir = data.snapDirectionMultiplier * lineDirX
    local lineZDir = data.snapDirectionMultiplier * lineDirZ

    for _, line in pairs(lines) do
        local lineX = x + data.width * lineDirZ * (data.alphaRad + line.position / 2)
        local lineZ = z - data.width * lineDirX * (data.alphaRad + line.position / 2)

        local r, g, b = unpack(line.rgb)

        for l = 1, numSteps, step do
            local x1 = lineX + ABStrategy.STEP_SIZE * l * lineXDir
            local z1 = lineZ + ABStrategy.STEP_SIZE * l * lineZDir
            local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + ABStrategy.GROUND_CLEARANCE_OFFSET
            local x2 = lineX + ABStrategy.STEP_SIZE * (l + 1) * lineXDir
            local z2 = lineZ + ABStrategy.STEP_SIZE * (l + 1) * lineZDir
            local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + ABStrategy.GROUND_CLEARANCE_OFFSET

            setTextBold(true)
            GuidanceUtil.renderTextAtWorldPosition(x1, y1, z1, ".", getCorrectTextSize(0.018), 0, r, g, b)
            GuidanceUtil.renderTextAtWorldPosition(x2, y2, z2, ".", getCorrectTextSize(0.018), 0, r, g, b)
        end
    end
end

---Gets the guidance drive data
---@param guidanceNode number
---@param data table
function ABStrategy:getGuidanceData(guidanceNode, data)
    return nil
end

---Creates the next AB point
---@param guidanceData table
function ABStrategy:pushABPoint(guidanceData)
    return self.ab:nextPoint(guidanceData)
end

---Gets if guidance can be activated
function ABStrategy:getIsGuidancePossible()
    return self.ab:getIsCreated()
end

---Returns if this strategy is AB depended
function ABStrategy:getHasABDependentDirection()
    return true
end

---Returns if we can guide based on AB points
function ABStrategy:getIsABDirectionPossible()
    return not self.ab:getIsEmpty()
end

---Gets the UI texts for the methods
---@param i18n table
function ABStrategy:getTexts(i18n)
    -- Remember the order is important here.
    return {
        i18n:getText("guidanceSteering_strategyMethod_aPlusB"), -- ABStrategy.AB
        i18n:getText("guidanceSteering_strategyMethod_autoB"), -- ABStrategy.A_AUTO_B
        i18n:getText("guidanceSteering_strategyMethod_aPlusHeading") -- ABStrategy.A_PLUS_HEADING
    }
end
