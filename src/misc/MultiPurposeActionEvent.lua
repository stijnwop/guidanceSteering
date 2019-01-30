---
-- MultiPurposeActionEvent
--
-- Event with multiple actions
--
-- Copyright (c) Wopster, 2019

MultiPurposeActionEvent = {}

local MultiPurposeActionEvent_mt = Class(MultiPurposeActionEvent)

---Creates a new instance
---@param maxNumberOfEvents table
function MultiPurposeActionEvent:new(maxNumberOfEvents)
    local instance = {}

    instance.numberOfEvents = 0
    instance.maxNumberOfEvents = maxNumberOfEvents
    instance.actions = {}

    setmetatable(instance, MultiPurposeActionEvent_mt)

    return instance
end

---Deletes the actions
function MultiPurposeActionEvent:delete()
    self.actions = {}
end

---Adds a function to the action list
---@param callback function
function MultiPurposeActionEvent:addAction(callback)
    table.insert(self.actions, callback)
end

---Checks if the event can handle an action
function MultiPurposeActionEvent:canHandle()
    return #self.actions > 0
end

---Handle event
function MultiPurposeActionEvent:handle()
    if self:canHandle() then
        local callback = self.actions[self.numberOfEvents + 1]

        if callback() then
            self:invoked()
        end

        if self.numberOfEvents >= self.maxNumberOfEvents then
            self:reset()
        end
    end
end

---Reset event counter
function MultiPurposeActionEvent:reset()
    self.numberOfEvents = 0
end

---Increases counter after invoke
function MultiPurposeActionEvent:invoked()
    self.numberOfEvents = self.numberOfEvents + 1
end
