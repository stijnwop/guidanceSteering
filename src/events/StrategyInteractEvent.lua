--
-- StrategyInteractEvent
--
-- Strategy push event to handle strategy interaction on other clients.
--
-- Copyright (c) Wopster, 2019

StrategyInteractEvent = {}
local StrategyInteractEvent_mt = Class(StrategyInteractEvent, Event)

InitEventClass(StrategyInteractEvent, "StrategyInteractEvent")

function StrategyInteractEvent:emptyNew()
    local self = Event.new(StrategyInteractEvent_mt)

    return self
end

function StrategyInteractEvent:new(object)
    local self = StrategyInteractEvent:emptyNew()

    self.object = object

    return self
end

function StrategyInteractEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)

    local spec = self.object.spec_globalPositioningSystem
    spec.lineStrategy:writeStream(streamId, connection)
end

function StrategyInteractEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    local spec = self.object.spec_globalPositioningSystem
    spec.lineStrategy:readStream(streamId, connection)

    self:run(connection)
end

function StrategyInteractEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    self.object:interactWithGuidanceStrategy(true)
end

function StrategyInteractEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or not noEventSend then
        if g_server ~= nil then
            g_server:broadcastEvent(StrategyInteractEvent:new(object), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(StrategyInteractEvent:new(object))
        end
    end
end
