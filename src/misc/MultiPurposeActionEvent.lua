MultiPurposeActionEvent = {}

local MultiPurposeActionEvent_mt = Class(MultiPurposeActionEvent)

function MultiPurposeActionEvent:new(maxNumberOfEvents, callbacks)
    local instance = {}

    instance.numberOfEvents = 0
    instance.maxNumberOfEvents = maxNumberOfEvents
    instance.callbacks = callbacks

    setmetatable(instance, MultiPurposeActionEvent_mt)

    return instance
end

function MultiPurposeActionEvent:handle()
    local callback = self.callbacks[self.numberOfEvents + 1]

    if callback() then
        self:clicked()
    end

    if self.numberOfEvents >= self.maxNumberOfEvents then
        self:reset()
    end
end

function MultiPurposeActionEvent:reset()
    self.numberOfEvents = 0
end

function MultiPurposeActionEvent:clicked()
    self.numberOfEvents = self.numberOfEvents + 1
end
