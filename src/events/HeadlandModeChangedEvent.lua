--
-- HeadlandModeChangedEvent
--
-- Data changed event to sync guidance data with server.
--
-- Copyright (c) Wopster, 2019

HeadlandModeChangedEvent = {}
local HeadlandModeChangedEvent_mt = Class(HeadlandModeChangedEvent, Event)

InitEventClass(HeadlandModeChangedEvent, "HeadlandModeChangedEvent")

function HeadlandModeChangedEvent:emptyNew()
    local self = Event:new(HeadlandModeChangedEvent_mt)

    return self
end

function HeadlandModeChangedEvent:new(vehicle, mode, distance)
    local self = HeadlandModeChangedEvent:emptyNew()

    self.vehicle = vehicle
    self.mode = mode
    self.distance = distance

    return self
end

function HeadlandModeChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    streamWriteInt8(streamId, self.mode)
    streamWriteInt8(streamId, self.distance)
end

function HeadlandModeChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadInt8(streamId)
    self.distance = streamReadInt8(streamId)

    self:run(connection)
end

function HeadlandModeChangedEvent:run(connection)
    local spec = self.vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")

    spec.headlandMode = self.mode
    spec.headlandActDistance = self.distance

    -- Send from server to all clients
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end
end
