
StraightABStrategy = {}

local StraightABStrategy_mt = Class(StraightABStrategy)

function StraightABStrategy:new(customMt)
    if customMt == nil then
        customMt = StraightABStrategy_mt
    end

    local instance = {}

    setmetatable(instance, customMt)

    return instance
end

function StraightABStrategy:delete()
end

function StraightABStrategy:update(dt)
end

function StraightABStrategy:drawLine(info)
end
