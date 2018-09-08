CurveABStrategy = {}

local CurveABStrategy_mt = Class(CurveABStrategy)


local ABLine = {
    ["middle"] = { position = 0, rgb = { 1, 1, 1 } }
}

local ABLines = {
    ["left"] = { position = -1, rgb = { 0, 0, .7 } },
    ["middle"] = { position = 0, rgb = { 1, 1, 1 } },
    ["right"] = { position = 1, rgb = { 0, 0, .7 } },
}

CurveABStrategy.STEP_SIZE = 1 -- 1m each line
CurveABStrategy.NUM_STEPS = 15 -- draw 15
CurveABStrategy.GROUND_CLEARANCE_OFFSET = .2


function CurveABStrategy:new(customMt)
    if customMt == nil then
        customMt = CurveABStrategy_mt
    end

    local instance = {}

    instance.curvedABPoints = {} -- {id = object pointer, name = render name}
    instance.curve = {}
    instance.segmentPoints = {}
    instance.segmentGenerated = false

    instance.segmentInterval = 1 / (0.75 * 0.001) -- ms
    instance.firstInterval = true
    instance.segmentDt = 0

    setmetatable(instance, customMt)

    return instance
end

function CurveABStrategy:delete()
    GuidanceUtil.deleteABPoints(self.curvedABPoints)
    self.curvedABPoints = {}
    self.segmentPoints = {}
    self.curve = {}

    self.firstInterval = true
    self.segmentGenerated = false
end

function CurveABStrategy:update(dt, data, lastSpeed)

    for _, point in pairs(self.curvedABPoints) do
        DebugUtil.drawDebugNode(point.node, point.name)
    end

    local generate = self:getIsGuidancesPossible()

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
        return
    end

    -- spline generation
    if self:getIsABDirectionPossible()
            and not generate then
        if self.firstInterval then
            local x, y, z = getWorldTranslation(self.curvedABPoints[1].node)
            local dx, _, dz = localDirectionToWorld(self.curvedABPoints[1].node, 0, 0, 1)

            local segment = {
                x = x,
                y = y,
                z = z,
                dx = dx,
                dz = dz,
                isStartPoint = true,
                isEndPoint = false
            }

            table.insert(self.segmentPoints, segment)
            self.firstInterval = false
        else
            if lastSpeed > 1 then
                self.segmentDt = self.segmentDt + dt

                if self.segmentDt > self.segmentInterval then
                    local x, y, z, dx, dz = unpack(data.driveTarget)
                    print(("drop segment x: %.1f y: %.1f z: %.1f "):format(x, y, z))

                    local segment = {
                        x = x,
                        y = y,
                        z = z,
                        dx = dx,
                        dz = dz,
                        isStartPoint = false,
                        isEndPoint = false
                    }

                    table.insert(self.segmentPoints, segment)

                    self.segmentDt = 0
                end
            end
        end
    end

    -- just draw for now
    if generate and not self.segmentGenerated then
        print("generate")
        local x, y, z = getWorldTranslation(self.curvedABPoints[2].node)
        local dx, _, dz = localDirectionToWorld(self.curvedABPoints[2].node, 0, 0, 1)

        local segment = {
            x = x,
            y = y,
            z = z,
            dx = dx,
            dz = dz,
            isStartPoint = false,
            isEndPoint = true
        }

        table.insert(self.segmentPoints, segment)

        self.segmentGenerated = true

        self.curve = GuidanceUtil:computeSpline(self.segmentPoints, 3)
    end
end

function CurveABStrategy:draw(data)

end

-- Todo: duplicate on straight
function CurveABStrategy:getGuidanceDirection(guidanceNode)
    local pointA = guidanceNode
    local pointB = self.curvedABPoints[1].node
    local numOfABPoints = #self.curvedABPoints

    if numOfABPoints >= 2 then
        pointA = self.curvedABPoints[1].node
        pointB = self.curvedABPoints[2].node
    end

    --    local localDirX, localDirY, localDirZ = localDirectionToLocal(pointA, pointB, 0, 0, 1)
    local localDirX, localDirY, localDirZ = worldDirectionToLocal(pointA, localDirectionToWorld(pointB, 0, 0, 1))

    return { localDirectionToWorld(guidanceNode, localDirX, localDirY, localDirZ) }
end

function CurveABStrategy:handleABPoints(guidanceNode, data)
    GuidanceUtil.createABPoint(guidanceNode, data, self.curvedABPoints)
end

function CurveABStrategy:getIsGuidancesPossible()
    return #self.curvedABPoints == 2
end

function CurveABStrategy:getRequiresABDirection()
    return true
end

function CurveABStrategy:getIsABDirectionPossible()
    return #self.curvedABPoints > 0
end
