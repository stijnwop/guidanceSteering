--
-- TrackSaveEvent
--
-- Saved track
--
-- Copyright (c) Wopster, 2019

TrackSaveEvent = {}
local TrackSaveEvent_mt = Class(TrackSaveEvent, Event)

InitEventClass(TrackSaveEvent, "TrackSaveEvent")

function TrackSaveEvent:emptyNew()
    local self = Event.new(TrackSaveEvent_mt)

    self.guidanceSteering = g_currentMission.guidanceSteering

    return self
end

function TrackSaveEvent:new(id, track)
    local self = TrackSaveEvent:emptyNew()

    self.id = id
    self.track = track

    return self
end

function TrackSaveEvent:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.id)

    --streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

    local track = self.track

    streamWriteString(streamId, track.name)
    streamWriteInt8(streamId, track.strategy)
    streamWriteInt8(streamId, track.method)

    GuidanceUtil.writeGuidanceDataObject(streamId, track.guidanceData)
end

function TrackSaveEvent:readStream(streamId, connection)
    self.id = streamReadInt8(streamId)

    --self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

    local track = {}
    track.name = streamReadString(streamId)
    track.strategy = streamReadInt8(streamId)
    track.method = streamReadInt8(streamId)
    track.guidanceData = GuidanceUtil.readGuidanceDataObject(streamId)

    self.track = track

    self:run(connection)
end

function TrackSaveEvent:run(connection)
    self.guidanceSteering:saveTrack(self.id, self.track)

    -- Send from server to all clients
    if not connection:getIsServer() then
        g_server:broadcastEvent(self)
    end
end
