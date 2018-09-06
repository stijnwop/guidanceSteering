--
-- Created by IntelliJ IDEA.
-- User: Wopereis
-- Date: 8/27/2018
-- Time: 4:21 PM
-- To change this template use File | Settings | File Templates.
--

GuidanceLine = {}

GuidanceLine.STEP_SIZE = 1 -- 1m each line
GuidanceLine.NUM_STEPS = 15 -- draw 15
GuidanceLine.GROUND_CLEARANCE_OFFSET = .2

GuidanceLine.ABLines = {
    ["left"] = { position = -1, rgb = { 0, 0, .7 } },
    ["middle"] = { position = 0, rgb = { 1, 1, 1 } },
    ["right"] = { position = 1, rgb = { 0, 0, .7 } },
}

local GuidanceLine_mt = Class(GuidanceLine)

function GuidanceLine:new(offset, rgb)
    local instance = {}

    setmetatable(instance, GuidanceLine_mt)

    --    instance.node = node
    instance.rgb = rgb
    instance.offset = offset

    return instance
end

function GuidanceLine:drawABLine(x, z, snapX, snapZ, width, moveDirection, beta, snapDirectionFactor)
    for key, line in pairs(GuidanceLine.ABLines) do
        local line0x = x + width * snapZ * (beta + line.position / 2)
        local line0z = z - width * snapX * (beta + line.position / 2)
        local lineXDirection = snapDirectionFactor * snapX * moveDirection
        local lineZDirection = snapDirectionFactor * snapZ * moveDirection

        local r, g, b = unpack(line.rgb)

        for l = 0, GuidanceLine.NUM_STEPS, GuidanceLine.STEP_SIZE do
            local lineAx = line0x + GuidanceLine.STEP_SIZE * l * lineXDirection
            local lineAz = line0z + GuidanceLine.STEP_SIZE * l * lineZDirection
            local lineAy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lineAx, 0, lineAz) + GuidanceLine.GROUND_CLEARANCE_OFFSET

            local lineBx = line0x + GuidanceLine.STEP_SIZE * (l + 1) * lineXDirection
            local lineBz = line0z + GuidanceLine.STEP_SIZE * (l + 1) * lineZDirection
            local lineBy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lineBx, 0, lineBz) + GuidanceLine.GROUND_CLEARANCE_OFFSET

            drawDebugLine(lineAx, lineAy, lineAz, r, g, b, lineBx, lineBy, lineBz, r, g, b)
        end
    end
end