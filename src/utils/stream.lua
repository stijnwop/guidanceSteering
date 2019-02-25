---
-- stream
--
-- Better list handling
--
-- Copyright (c) Wopster, 2019

local BaseStream = {}
local BaseStream_mt = { __index = BaseStream }

function BaseStream.stream(list)
    local t = {}

    setmetatable(t, BaseStream_mt)

    t.list = list

    return t
end

---Performs a reduction on the elements of the current list, using the provided identity value and an associative accumulation function, and returns the reduced value.
---@param identity any
---@param accumulator function
function BaseStream:reduce(identity, accumulator)
    local result = identity
    for _, element in ipairs(self.list) do
        result = accumulator(result, element)
    end
    return result
end

---Returns current stream with the list consisting of the results that where applied by the predicate function.
---@param predicate function
function BaseStream:map(predicate)
    local result = {}
    for i, element in ipairs(self.list) do
        result[i] = predicate(element)
    end
    self.list = result
    return self
end

---Returns current stream with the list consisting of the filtered results
---@param predicate table
function BaseStream:filter(predicate)
end

---Finds first element of the list that matches the given predicate function
---@param predicate function
function BaseStream:findFirst(predicate)
    for _, value in ipairs(self.list) do
        if predicate(value) then
            return value
        end
    end

    return nil
end

---Returns the current list
function BaseStream:toList()
    return self.list
end

setmetatable(BaseStream, { __call = function(_, ...)
    return BaseStream.stream(...)
end })

stream = BaseStream
