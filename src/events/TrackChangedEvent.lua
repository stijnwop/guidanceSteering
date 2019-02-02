--
-- TrackChangedEvent
--
-- Saved/new track changed
--
-- Copyright (c) Wopster, 2019

TrackChangedEvent = {}
local TrackChangedEvent_mt = Class(TrackChangedEvent, Event)

InitEventClass(TrackChangedEvent, "TrackChangedEvent")

function TrackChangedEvent:emptyNew()
    local self = Event:new(TrackChangedEvent_mt)

    self.guidanceSteering = g_guidanceSteering

    return self
end

function TrackChangedEvent:new(id, name, createEmpty, track)
    local self = TrackChangedEvent:emptyNew()

    self.id = id
    self.name = name
    self.createEmpty = createEmpty
    self.track = track

    return self
end

function TrackChangedEvent:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.id)
    streamWriteString(streamId, self.name)
    streamWriteBool(streamId, self.createEmpty)

    --streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

    if not self.createEmpty then
        local track = self.track

        streamWriteInt8(streamId, track.strategy)
        streamWriteInt8(streamId, track.method)

        GuidanceUtil.writeGuidanceDataObject(streamId, track.guidanceData)
    end
end

function TrackChangedEvent:readStream(streamId, connection)
    self.id = streamReadInt8(streamId)
    self.name = streamReadString(streamId)
    self.createEmpty = streamReadBool(streamId)

    --self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

    if not self.createEmpty then
        local track = {}

        track.name = self.name
        track.strategy = streamReadInt8(streamId)
        track.method = streamReadInt8(streamId)

        track.guidanceData = GuidanceUtil.readGuidanceDataObject(streamId)

        self.track = track
    end

    self:run(connection)
end

function TrackChangedEvent:run(connection)
    if self.createEmpty then
        self.guidanceSteering:createTrack(self.id, self.name)
    else
        self.guidanceSteering:saveTrack(self.id, self.track)
    end

    -- Send from server to all clients
    if not connection:getIsServer() then
        g_server:broadcastEvent(self)
    end
end
