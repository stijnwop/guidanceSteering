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
local RGB_GREEN = { 0, 0.447871, 0.003697 }
local RGB_BLUE = { 0, 0, 1 }
local RGB_RED = { 1, 0, 0 }

ABStrategy.ABLines = {
    ["left"] = { position = -1, rgb = RGB_BLUE, rgbActive = RGB_BLUE },
    ["middle"] = { position = 0, rgb = RGB_WHITE, rgbActive = RGB_GREEN },
    ["right"] = { position = 1, rgb = RGB_BLUE, rgbActive = RGB_BLUE },
}

ABStrategy.STEP_SIZE = 1 -- 1m each line
ABStrategy.NUM_STEPS = 15 -- draw 10

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
    instance.id = ABStrategy.AB

    setmetatable(instance, customMt or ABStrategy_mt)

    return instance
end

---Called on read stream.
function ABStrategy:readStream(streamId, connection)
end

---Called on write stream.
function ABStrategy:writeStream(streamId, connection)
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
    local numSteps = data.lineDistance + ABStrategy.NUM_STEPS
    --local drawBotherLines = self:getIsGuidancePossible()
    local drawBotherLines = data.isCreated
    local x, _, z, lineDirX, lineDirZ = unpack(data.driveTarget)

    if drawBotherLines then
        lineDirX, lineDirZ = unpack(data.snapDirection)
        lines = ABStrategy.ABLines
    end

    local stepSkips = 1
    local drawDirectionLine = self:getIsABDirectionPossible() and not drawBotherLines
    if drawDirectionLine then
        -- Todo: optimize
        local pointA = self.ab:getPointNode(ABPoint.POINT_A)
        local a = { localToWorld(pointA, 0, 0, 0) }
        local dirX = x - a[1]
        local dirZ = z - a[3]
        local length = MathUtil.vector2Length(dirX, dirZ)
        numSteps = math.max(math.floor(length) - 1, 0)
        stepSkips = 2
    end

    local lineXDir = data.snapDirectionMultiplier * lineDirX
    local lineZDir = data.snapDirectionMultiplier * lineDirZ

    local offset = 0
    if drawBotherLines then
        offset = data.lineDistance * 0.5
    end

    local lineOffset = g_currentMission.guidanceSteering:getLineOffset()
    local function drawSteps(step, stepSize, lx, lz, dirX, dirZ, rgb)
        if step >= numSteps then
            return
        end

        local x1 = lx + ABStrategy.STEP_SIZE * step * dirX
        local z1 = lz + ABStrategy.STEP_SIZE * step * dirZ
        local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + lineOffset
        local x2 = lx + ABStrategy.STEP_SIZE * (step + 1) * dirX
        local z2 = lz + ABStrategy.STEP_SIZE * (step + 1) * dirZ
        local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + lineOffset

        drawDebugLine(x1, y1, z1, rgb[1], rgb[2], rgb[3], x2, y2, z2, rgb[1], rgb[2], rgb[3])

        drawSteps(step + stepSkips, stepSize, lx, lz, dirX, dirZ, rgb)
    end

    for _, line in pairs(lines) do
        local beta = data.alphaRad + line.position / 2
        local lineX = x + data.width * lineDirZ * beta
        local lineZ = z - data.width * lineDirX * beta

        local rgb = guidanceSteeringIsActive and line.rgbActive or line.rgb

        drawSteps(1, ABStrategy.STEP_SIZE, lineX, lineZ, lineXDir, lineZDir, rgb)-- draw direction arrow
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

---Interaction function that is called from an MP event.
---@param data table
function ABStrategy:interact(data)
    self.ab:nextPoint(data)
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
