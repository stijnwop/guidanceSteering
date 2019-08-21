--
-- ABPointPushedEvent
--
-- AB point push event to handle point creation on other clients.
--
-- Copyright (c) Wopster, 2019

ABPointPushedEvent = {}
local ABPointPushedEvent_mt = Class(ABPointPushedEvent, Event)

InitEventClass(ABPointPushedEvent, "ABPointPushedEvent")

function ABPointPushedEvent:emptyNew()
    local self = Event:new(ABPointPushedEvent_mt)

    return self
end

function ABPointPushedEvent:new(object)
    local self = ABPointPushedEvent:emptyNew()

    self.object = object

    return self
end

function ABPointPushedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)

    local spec = self.object.spec_globalPositioningSystem
    spec.lineStrategy:writeStream(streamId, connection)
end

function ABPointPushedEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    local spec = self.object.spec_globalPositioningSystem
    spec.lineStrategy:readStream(streamId, connection)

    self:run(connection)
end

function ABPointPushedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    self.object:pushABPoint(true)
end

function ABPointPushedEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or not noEventSend then
        if g_server ~= nil then
            g_server:broadcastEvent(ABPointPushedEvent:new(object), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(ABPointPushedEvent:new(object))
        end
    end
end
