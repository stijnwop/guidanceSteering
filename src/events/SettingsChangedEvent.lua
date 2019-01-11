SettingsChangedEvent = {}
local SettingsChangedEvent_mt = Class(SettingsChangedEvent, Event)

InitEventClass(SettingsChangedEvent, "SettingsChangedEvent")

function SettingsChangedEvent:emptyNew()
    local self = Event:new(SettingsChangedEvent_mt)

    return self
end

function SettingsChangedEvent:new(vehicle, guidanceIsActive, showGuidanceLines, guidanceSteeringIsActive, guidanceTerrainAngleIsActive)
    local self = SettingsChangedEvent:emptyNew()

    self.vehicle = vehicle
    self.guidanceIsActive = guidanceIsActive
    self.showGuidanceLines = showGuidanceLines
    self.guidanceSteeringIsActive = guidanceSteeringIsActive
    self.guidanceTerrainAngleIsActive = guidanceTerrainAngleIsActive

    return self
end

function SettingsChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.guidanceIsActive)
    streamWriteBool(streamId, self.showGuidanceLines)
    streamWriteBool(streamId, self.guidanceSteeringIsActive)
    streamWriteBool(streamId, self.guidanceTerrainAngleIsActive)
end

function SettingsChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.guidanceIsActive = streamReadBool(streamId)
    self.showGuidanceLines = streamReadBool(streamId)
    self.guidanceSteeringIsActive = streamReadBool(streamId)
    self.guidanceTerrainAngleIsActive = streamReadBool(streamId)

    self:run(connection)
end

function SettingsChangedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    local spec = self.vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    spec.guidanceIsActive = self.guidanceIsActive
    spec.showGuidanceLines = self.showGuidanceLines
    spec.guidanceSteeringIsActive = self.guidanceSteeringIsActive
    spec.guidanceTerrainAngleIsActive = self.guidanceTerrainAngleIsActive
end
