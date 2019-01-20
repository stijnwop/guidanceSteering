MultiPurposeActionEvent = {}

local MultiPurposeActionEvent_mt = Class(MultiPurposeActionEvent)

function MultiPurposeActionEvent:new(maxNumberOfEvents)
    local instance = {}

    instance.numberOfEvents = 0
    instance.maxNumberOfEvents = maxNumberOfEvents
    instance.actions = {}

    setmetatable(instance, MultiPurposeActionEvent_mt)

    return instance
end

function MultiPurposeActionEvent:delete()
    self.actions = {}
end

function MultiPurposeActionEvent:addAction(callback)
    table.insert(self.actions, callback)
end

function MultiPurposeActionEvent:canHandle()
    return #self.actions > 0
end

function MultiPurposeActionEvent:handle()
    if self:canHandle() then
        local callback = self.actions[self.numberOfEvents + 1]

        if callback() then
            self:clicked()
        end

        if self.numberOfEvents >= self.maxNumberOfEvents then
            self:reset()
        end
    end
end

function MultiPurposeActionEvent:reset()
    self.numberOfEvents = 0
end

function MultiPurposeActionEvent:clicked()
    self.numberOfEvents = self.numberOfEvents + 1
end
