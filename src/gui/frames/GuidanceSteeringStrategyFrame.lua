GuidanceSteeringStrategyFrame = {}
local GuidanceSteeringStrategyFrame_mt = Class(GuidanceSteeringStrategyFrame, TabbedMenuFrameElement)

GuidanceSteeringStrategyFrame.CONTROLS = {
    CONTAINER = "container",
    STRATEGY = "guidanceSteeringStrategyElement",
    STRATEGY_METHOD = "guidanceSteeringStrategyMethodElement",
    TRACK = "guidanceSteeringTrackElement",
    CARDINALS = "guidanceSteeringCardinalsElement",
    -- Text box
    TRACK_TEXT_INPUT = "guidanceSteeringTrackNameElement",
    -- Buttons
    POINT_A_BUTTON = "guidanceSteeringPointAButton",
    POINT_B_BUTTON = "guidanceSteeringPointBButton",
    -- Warning box
    HELP_BOX = "settingsHelpBoxText"
}

function GuidanceSteeringStrategyFrame:new(i18n)
    local self = TabbedMenuFrameElement:new(nil, GuidanceSteeringStrategyFrame_mt)

    self.guidanceSteering = g_guidanceSteering

    self.i18n = i18n
    self.allowSave = false

    self:registerControls(GuidanceSteeringStrategyFrame.CONTROLS)

    return self
end

function GuidanceSteeringStrategyFrame:copyAttributes(src)
    GuidanceSteeringStrategyFrame:superClass().copyAttributes(self, src)

    self.i18n = src.i18n
end

function GuidanceSteeringStrategyFrame:initialize()
    self.guidanceSteeringStrategyElement:setTexts({
        self.i18n:getText("guidanceSteering_strategy_abStraight"),
    })

    local cardinals = {}

    for deg = 0, 360, 360 / 16 do
        table.insert(cardinals, deg)
    end

    self.guidanceSteeringCardinalsElement:setTexts(cardinals)
    self.guidanceSteeringTrackNameElement:setText("Track name")
end

function GuidanceSteeringStrategyFrame:onFrameOpen()
    GuidanceSteeringStrategyFrame:superClass().onFrameOpen(self)

    self.guidanceSteering:subscribe(self)

    local vehicle = self.guidanceSteering.ui:getVehicle()

    if vehicle ~= nil then
        local strategy = vehicle:getGuidanceStrategy()
        local data = vehicle:getGuidanceData()

        self.guidanceSteeringStrategyMethodElement:setTexts(strategy:getTexts(self.i18n))
        self.guidanceSteeringTrackElement:setState(data.lastLoadedTrackId)

        Logger.info("Loaded: ", data.lastLoadedTrackId)

        if data.lastLoadedTrackId ~= 0 then
            self:onClickLoadTrack(data.lastLoadedTrackId)
        end

        self.allowSave = true
    end

    self:onDisplayElementsChanged()
end

function GuidanceSteeringStrategyFrame:onFrameClose()
    GuidanceSteeringStrategyFrame:superClass().onFrameClose(self)

    if self.allowSave then
        local trackId = self.guidanceSteeringTrackElement:getState()
        local vehicle = self.guidanceSteering.ui:getVehicle()
        local data = vehicle:getGuidanceData()

        if trackId ~= data.lastLoadedTrackId then
            self:loadTrack(trackId)
            data.lastLoadedTrackId = trackId
        end

        self.allowSave = false
    end

    self.guidanceSteering:unsubscribe(self)
end

--- Get the frame's main content element's screen size.
function GuidanceSteeringStrategyFrame:getMainElementSize()
    return self.container.size
end

--- Get the frame's main content element's screen position.
function GuidanceSteeringStrategyFrame:getMainElementPosition()
    return self.container.absPosition
end

function GuidanceSteeringStrategyFrame:onClickRemoveTrack()
    -- Reset warning
    self:setWarningMessage("")

    local trackId = self.guidanceSteeringTrackElement:getState()

    if trackId ~= 0 then
        Logger.info("Removing track: ", trackId)
        self:deleteTrack(trackId)

        -- Reset loaded track when we are deleting it.
        if self.loadedTrackId == trackId then
            self.loadedTrackId = 0
        end
    end
end

function GuidanceSteeringStrategyFrame:getVehicleTrackData()
    local track = {}

    track.name = self.guidanceSteeringTrackNameElement:getText()
    track.strategy = self.guidanceSteeringStrategyElement:getState()
    track.method = self.guidanceSteeringStrategyMethodElement:getState()

    local vehicle = self.guidanceSteering.ui:getVehicle()
    if vehicle ~= nil then
        local data = vehicle:getGuidanceData()

        if not data.isCreated then
            self:setWarningMessage(g_i18n:getText("guidanceSteering_tooltip_trackIsNotCreated"))
            return nil
        end

        track.farmId = vehicle:getOwnerFarmId()
        track.guidanceData = {}
        track.guidanceData.width = data.width
        track.guidanceData.offsetWidth = data.offsetWidth
        track.guidanceData.snapDirection = data.snapDirection
        track.guidanceData.driveTarget = data.driveTarget
    end

    return track
end

function GuidanceSteeringStrategyFrame:onClickSaveTrack()
    local trackId = self.guidanceSteeringTrackElement:getState()
    local track = self.guidanceSteering:getTrack(trackId)
    local name = self.guidanceSteeringTrackNameElement:getText()
    local isNewTrack = track ~= nil and name ~= track.name

    if track ~= nil and not isNewTrack then
        local trackData = self:getVehicleTrackData()
        if trackData ~= nil then
            Logger.info("Saving track: " .. trackId, trackData)
            self:saveTrack(trackId, trackData)
        end
    else
        -- Get a new Id
        trackId = self.guidanceSteering:getNewTrackId()
        local trackData = self:getVehicleTrackData()
        -- Reset warning
        self:setWarningMessage("")

        -- might check if the name already exists
        if self.guidanceSteering:isExistingTrack(trackId, trackData.name) then
            self:setWarningMessage(g_i18n:getText("guidanceSteering_tooltip_trackAlreadyExists"):format(trackData.name))
            return
        end

        if trackData ~= nil then
            Logger.info("Creating track: " .. trackId, trackData)
            self:saveTrack(trackId, trackData)
        end
    end
end

function GuidanceSteeringStrategyFrame:onClickLoadTrack(trackId)
    local track = self.guidanceSteering:getTrack(trackId)

    if track ~= nil then
        self.guidanceSteeringTrackNameElement:setText(track.name)
        self.guidanceSteeringStrategyElement:setState(track.strategy)
        self.guidanceSteeringStrategyMethodElement:setState(track.method)
    end

    self:onDisplayElementsChanged()
    -- After the new list is updated set the current track.
    self.guidanceSteeringTrackElement:setState(trackId)
end

function GuidanceSteeringStrategyFrame:onClickSetPointA()
    local vehicle = self.guidanceSteering.ui:getVehicle()

    if vehicle == nil then
        return
    end

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if not spec.lineStrategy:getIsABDirectionPossible() then
        -- First request reset to make sure the current track is clear
        vehicle:updateGuidanceData(nil, false, true)
        vehicle:pushABPoint()
    end
end

function GuidanceSteeringStrategyFrame:onClickSetPointB()
    local vehicle = self.guidanceSteering.ui:getVehicle()

    if vehicle == nil then
        return
    end

    local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
    if spec.lineStrategy:getIsABDirectionPossible() then
        vehicle:pushABPoint()
        GlobalPositioningSystem.computeGuidanceDirection(vehicle)
    end
end

function GuidanceSteeringStrategyFrame:onEnterPressedTrackName()
end

--- Functions

---Called by the GuidanceSteering class
function GuidanceSteeringStrategyFrame:onTrackChanged(trackId)
    self:onClickLoadTrack(trackId)
end

function GuidanceSteeringStrategyFrame:loadTrack(trackId)
    local track = self.guidanceSteering:getTrack(trackId)

    if self.guidanceSteering:isTrackValid(trackId) then
        local vehicle = self.guidanceSteering.ui:getVehicle()

        if vehicle ~= nil then
            local data = vehicle:getGuidanceData()
            Logger.info("Loading track for client: ", trackId)

            -- First request reset to make sure the current track is clear
            vehicle:updateGuidanceData(nil, false, true)

            data.width = track.guidanceData.width
            data.offsetWidth = track.guidanceData.offsetWidth
            data.snapDirection = track.guidanceData.snapDirection
            data.driveTarget = track.guidanceData.driveTarget

            -- Now we send a creation event
            vehicle:updateGuidanceData(data, true, false)
        end
    end
end

function GuidanceSteeringStrategyFrame:saveTrack(trackId, track)
    g_client:getServerConnection():sendEvent(TrackSaveEvent:new(trackId, track))
end

function GuidanceSteeringStrategyFrame:deleteTrack(trackId)
    g_client:getServerConnection():sendEvent(TrackDeleteEvent:new(trackId))
end

function GuidanceSteeringStrategyFrame:setWarningMessage(message)
    self.settingsHelpBoxText:setText(message)
end

function GuidanceSteeringStrategyFrame:onDisplayElementsChanged()
    self:displayTrackElement()
    self:displayMethodElements()
end

function GuidanceSteeringStrategyFrame:displayMethodElements()
    local method = self.guidanceSteeringStrategyMethodElement:getState() - 1

    if method == ABStrategy.AB then
        self.guidanceSteeringPointAButton:setVisible(true)
        self.guidanceSteeringPointBButton:setVisible(true)
        self.guidanceSteeringCardinalsElement:setVisible(false)
    elseif method == ABStrategy.A_AUTO_B or method == ABStrategy.A_PLUS_HEADING then
        self.guidanceSteeringPointAButton:setVisible(true)
        self.guidanceSteeringPointBButton:setVisible(false)
        self.guidanceSteeringCardinalsElement:setVisible(method == ABStrategy.A_PLUS_HEADING)
    end
end

function GuidanceSteeringStrategyFrame:displayTrackElement()
    local texts = {}
    for _, t in ipairs(self.guidanceSteering.savedTracks) do
        table.insert(texts, t.name)
    end

    self.guidanceSteeringTrackElement:setTexts(texts)
end

GuidanceSteeringStrategyFrame.L10N_SYMBOL = {}
