--
-- TrackDeleteEvent
--
-- Track deleted
--
-- Copyright (c) Wopster, 2019

TrackDeleteEvent = {}
local TrackDeleteEvent_mt = Class(TrackDeleteEvent, Event)

InitEventClass(TrackDeleteEvent, "TrackDeleteEvent")

function TrackDeleteEvent:emptyNew()
    local self = Event.new(TrackDeleteEvent_mt)

    self.guidanceSteering = g_currentMission.guidanceSteering

    return self
end

function TrackDeleteEvent:new(id)
    local self = TrackDeleteEvent:emptyNew()

    self.id = id

    return self
end

function TrackDeleteEvent:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.id)
end

function TrackDeleteEvent:readStream(streamId, connection)
    self.id = streamReadInt8(streamId)
    self:run(connection)
end

function TrackDeleteEvent:run(connection)
    self.guidanceSteering:deleteTrack(self.id)

    -- Send from server to all clients
    if not connection:getIsServer() then
        g_server:broadcastEvent(self)
    end
end
