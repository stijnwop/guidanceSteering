--
-- GuidanceDataChangedEvent
--
-- Data changed event to sync guidance data with server.
--
-- Copyright (c) Wopster, 2019

GuidanceDataChangedEvent = {}
local GuidanceDataChangedEvent_mt = Class(GuidanceDataChangedEvent, Event)

InitEventClass(GuidanceDataChangedEvent, "GuidanceDataChangedEvent")

function GuidanceDataChangedEvent:emptyNew()
    local self = Event:new(GuidanceDataChangedEvent_mt)

    return self
end

function GuidanceDataChangedEvent:new(vehicle, data, isCreation, isReset)
    local self = GuidanceDataChangedEvent:emptyNew()

    self.vehicle = vehicle
    self.data = data
    self.isCreation = isCreation
    self.isReset = isReset

    return self
end

function GuidanceDataChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isCreation)
    streamWriteBool(streamId, self.isReset)
    if not self.isReset then
        GuidanceUtil.writeGuidanceDataObject(streamId, self.data)
    end
end

function GuidanceDataChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isCreation = streamReadBool(streamId)
    self.isReset = streamReadBool(streamId)

    if not self.isReset then
        self.data = GuidanceUtil.readGuidanceDataObject(streamId)
    end

    --g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm())
    self:run(connection)
end

function GuidanceDataChangedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    self.vehicle:updateGuidanceData(self.data, self.isCreation, self.isReset, true)
end

function GuidanceDataChangedEvent.sendEvent(vehicle, data, isCreation, isReset, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(GuidanceDataChangedEvent:new(vehicle, data, isCreation, isReset), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(GuidanceDataChangedEvent:new(vehicle, data, isCreation, isReset))
        end
    end
end
