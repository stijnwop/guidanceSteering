
CurveABStrategy = {}

local CurveABStrategy_mt = Class(CurveABStrategy)

function CurveABStrategy:new(customMt)
    if customMt == nil then
        customMt = CurveABStrategy_mt
    end

    local instance = {}

    setmetatable(instance, customMt)

    return instance
end

function CurveABStrategy:delete()
end

function CurveABStrategy:update(dt)
end

function CurveABStrategy:drawLine(info)
end
