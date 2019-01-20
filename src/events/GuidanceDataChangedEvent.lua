GuidanceDataChangedEvent = {}
local GuidanceDataChangedEvent_mt = Class(GuidanceDataChangedEvent, Event)

InitEventClass(GuidanceDataChangedEvent, "GuidanceDataChangedEvent")

function GuidanceDataChangedEvent:emptyNew()
    local self = Event:new(GuidanceDataChangedEvent_mt)

    return self
end

function GuidanceDataChangedEvent:new(vehicle, doReset, data)
    local self = GuidanceDataChangedEvent:emptyNew()

    self.vehicle = vehicle
    self.doReset = doReset
    self.data = data

    return self
end

function GuidanceDataChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.doReset)
    if not self.doReset then
        GuidanceUtil.writeGuidanceDataObject(streamId, self.data)
    end
end

function GuidanceDataChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.doReset = streamReadBool(streamId)

    if not self.doReset then
        self.data = GuidanceUtil.readGuidanceDataObject(streamId)
    end

    self:run(connection)
end

function GuidanceDataChangedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    self.vehicle:updateGuidanceData(self.doReset, self.data, true)
end

function GuidanceDataChangedEvent.sendEvent(vehicle, doReset, data, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(GuidanceDataChangedEvent:new(vehicle, doReset, data), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(GuidanceDataChangedEvent:new(vehicle, doReset, data))
        end
    end
end
