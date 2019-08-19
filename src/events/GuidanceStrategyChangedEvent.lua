--
-- GuidanceStrategyChangedEvent
--
-- Guidance strategy event to sync guidance data with server.
--
-- Copyright (c) Wopster, 2019

GuidanceStrategyChangedEvent = {}
local GuidanceStrategyChangedEvent_mt = Class(GuidanceStrategyChangedEvent, Event)

InitEventClass(GuidanceStrategyChangedEvent, "GuidanceStrategyChangedEvent")

function GuidanceStrategyChangedEvent:emptyNew()
    local self = Event:new(GuidanceStrategyChangedEvent_mt)

    return self
end

function GuidanceStrategyChangedEvent:new(vehicle, method)
    local self = GuidanceStrategyChangedEvent:emptyNew()

    self.vehicle = vehicle
    self.method = method

    return self
end

function GuidanceStrategyChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteInt8(streamId, self.method)
end

function GuidanceStrategyChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.method = streamReadInt8(streamId)

    self:run(connection)
end

function GuidanceStrategyChangedEvent:run(connection)
    self.vehicle:setGuidanceStrategy(self.method, true)

    -- Send from server to all clients
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end
end
