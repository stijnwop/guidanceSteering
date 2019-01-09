TrackChangedEvent = {}
local TrackChangedEvent_mt = Class(TrackChangedEvent, Event)

InitEventClass(TrackChangedEvent, "TrackChangedEvent")

function TrackChangedEvent:emptyNew()
    local self = Event:new(TrackChangedEvent_mt)

    self.guidanceSteering = g_guidanceSteering

    return self
end

function TrackChangedEvent:new(id, data)
    local self = TrackChangedEvent:emptyNew()

    self.id = id
    self.data = data

    return self
end

function TrackChangedEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.id)
    NetworkUtil.writeNodeObject(streamId, self.bale)
end

function TrackChangedEvent:readStream(streamId, connection)
    self.id = streamReadUInt8(streamId)
    self.data = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end

function TrackChangedEvent:run(connection)
    if connection:getIsServer() then
        self.guidanceSteering:saveTrack(self.id, self.data)

        -- Send from server to all clients
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection)
        end
    end
end
