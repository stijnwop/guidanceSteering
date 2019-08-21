---
-- ABStrategy
--
-- Base class for AB based strategies.
--
-- Copyright (c) Wopster, 2018

ABStrategy = {}

ABStrategy.AB = 0
ABStrategy.A_PLUS_HEADING = 1
ABStrategy.A_AUTO_B = 2

ABStrategy.METHODS = {
    ABStrategy.AB,
    ABStrategy.A_AUTO_B,
    ABStrategy.A_PLUS_HEADING
}

local RGB_WHITE = { 1, 1, 1 }
local RGB_GREEN = { 0, 1, 0 }
local RGB_BLUE = { 0.9913, 0.3940, 0.007 }
local RGB_RED = { 1, 0, 0 }

ABStrategy.ABLines = {
    ["left"] = { position = -1, rgb = RGB_BLUE, rgbActive = RGB_BLUE },
    ["middle"] = { position = 0, rgb = RGB_WHITE, rgbActive = RGB_GREEN },
    ["right"] = { position = 1, rgb = RGB_BLUE, rgbActive = RGB_BLUE },
}

ABStrategy.STEP_SIZE = 1 -- 1m each line
ABStrategy.NUM_STEPS = 10 -- draw 10
ABStrategy.GROUND_CLEARANCE_OFFSET = .2

local ABStrategy_mt = Class(ABStrategy)

---Create a new instance of the ABStrategy
---@param vehicle table
---@param customMt table
function ABStrategy:new(vehicle, customMt)
    local instance = {}
    local spec = vehicle.spec_globalPositioningSystem

    instance.ab = ABPoint:new(spec.guidanceNode)
    instance.turnActive = false
    instance.vehicle = vehicle

    setmetatable(instance, customMt or ABStrategy_mt)

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
---@param guidanceSteeringIsActive boolean
---@param autoInvertOffset boolean
function ABStrategy:draw(data, guidanceSteeringIsActive, autoInvertOffset)
    local lines = { ABStrategy.ABLines["middle"] }
    local skipStep = 1
    local numSteps = data.lineDistance + ABStrategy.NUM_STEPS
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
        skipStep = 2
    end

    local lineXDir = data.snapDirectionMultiplier * lineDirX
    local lineZDir = data.snapDirectionMultiplier * lineDirZ

    local offset = 0
    if drawBotherLines then
        offset = data.lineDistance * 0.5
    end

    local function drawSteps(step, stepSize, lx, lz, dirX, dirZ, rgb)
        if step >= numSteps then
            return
        end

        local x1 = lx - offset * dirX + stepSize * step * dirX
        local z1 = lz - offset * dirZ + stepSize * step * dirZ
        local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + ABStrategy.GROUND_CLEARANCE_OFFSET

        GuidanceUtil.renderTextAtWorldPosition(x1, y1, z1, ".", 0.02, rgb)
        drawSteps(step + skipStep, stepSize, lx, lz, dirX, dirZ, rgb)
    end

    for _, line in pairs(lines) do
        local beta = data.alphaRad + line.position / 2
        local lineX = x + data.width * lineDirZ * beta
        local lineZ = z - data.width * lineDirX * beta

        local rgb = guidanceSteeringIsActive and line.rgbActive or line.rgb

        drawSteps(1, ABStrategy.STEP_SIZE, lineX, lineZ, lineXDir, lineZDir, rgb)
    end

    if data.offsetWidth ~= 0 then
        local snapFactor = autoInvertOffset and data.snapDirectionMultiplier or 1.0
        local beta = data.alphaRad - snapFactor * data.offsetWidth / data.width
        local lineX = x + data.width * lineDirZ * beta
        local lineZ = z - data.width * lineDirX * beta

        drawSteps(1, ABStrategy.STEP_SIZE, lineX, lineZ, lineXDir, lineZDir, RGB_RED)
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

---Returns true when the vehicle needs to drive a certain threshold, false otherwise.
function ABStrategy:needsDrivingDistanceThreshold()
    return true
end

---Gets the UI texts for the methods
---@param i18n table
function ABStrategy:getTexts(i18n)
    -- Remember the order is important here.
    return {
        i18n:getText("guidanceSteering_strategyMethod_aPlusB"), -- ABStrategy.AB
        i18n:getText("guidanceSteering_strategyMethod_aPlusHeading") -- ABStrategy.A_PLUS_HEADING
        --i18n:getText("guidanceSteering_strategyMethod_autoB"), -- ABStrategy.A_AUTO_B
    }
end
