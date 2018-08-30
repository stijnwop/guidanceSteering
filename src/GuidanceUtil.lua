--
-- Created by IntelliJ IDEA.
-- User: Wopereis
-- Date: 8/28/2018
-- Time: 6:40 PM
-- To change this template use File | Settings | File Templates.
--

GuidanceUtil = {}

function GuidanceUtil.mathRound(number, idp)
    local multiplier = 10 ^ (idp or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function GuidanceUtil.getMaxWorkAreaWidth(guidanceNode, object)
    local width = 0

    if object.workAreas ~= nil then
        for _, workArea in pairs(object.workAreas) do
            --            if object:getIsWorkAreaActive(workArea) then
            local x0, _, _ = localToLocal(guidanceNode, workArea.start, 0, 0, 0)
            local x1, _, _ = localToLocal(guidanceNode, workArea.width, 0, 0, 0)
            local x2, _, _ = localToLocal(guidanceNode, workArea.height, 0, 0, 0)

            local maxWidth = math.max(x0, x1, x2)
            local minWidth = math.min(x0, x1, x2)

            width = math.max(width, math.abs(maxWidth) + math.abs(minWidth))
            --            end
        end
    end
    return GuidanceUtil.mathRound(width, 2)
end

function GuidanceUtil.getAProjectOnLineParameter(px, pz, lineX, lineZ, lineDirX, lineDirZ)
    local dx, dz = px - lineX, pz - lineZ
    local dot = dx * lineDirX - dz * lineDirZ

    return dot
end

function GuidanceUtil.getDriveDirection(dx, dz)
    local length = Utils.vector2Length(dx, dz)
    local dlx = dx / length
    local dlz = dz / length

    return dlx, dlz
end
