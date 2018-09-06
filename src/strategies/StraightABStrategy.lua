StraightABStrategy = {}

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

function StraightABStrategy:draw(info)
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