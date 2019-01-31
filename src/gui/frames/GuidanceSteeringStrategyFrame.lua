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
    --self.guidanceSteeringStrategyMethodElement.onLeftButtonClicked = Utils.appendedFunction(self.guidanceSteeringStrategyMethodElement.onLeftButtonClicked, self.onDisplayElementsChanged)
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

-- Todo: create custom button element
--
--function GuidanceSteeringStrategyFrame:onLeftButtonClicked()
--    GuidanceSteeringStrategyFrame:superClass().onLeftButtonClicked(self)
--
--end
--
--function GuidanceSteeringStrategyFrame:onRightButtonClicked()
--    GuidanceSteeringStrategyFrame:superClass().onLeftButtonClicked(self)
--
--end

function GuidanceSteeringStrategyFrame:onFrameOpen()
    GuidanceSteeringStrategyFrame:superClass().onFrameOpen(self)

    local vehicle = g_guidanceSteering.ui:getVehicle()

    if vehicle ~= nil then
        local strategy = vehicle:getGuidanceStrategy()

        self.guidanceSteeringStrategyMethodElement:setTexts(strategy:getTexts(self.i18n))

        self.allowSave = true
    end

    self:onDisplayElementsChanged()
end

function GuidanceSteeringStrategyFrame:onFrameClose()
    GuidanceSteeringStrategyFrame:superClass().onFrameClose(self)

    if self.allowSave then

        self.allowSave = false
    end
end

--- Get the frame's main content element's screen size.
function GuidanceSteeringStrategyFrame:getMainElementSize()
    return self.container.size
end

--- Get the frame's main content element's screen position.
function GuidanceSteeringStrategyFrame:getMainElementPosition()
    return self.container.absPosition
end

--- Buttons

function GuidanceSteeringStrategyFrame:onClickNewTrack()
    local id = self.guidanceSteeringTrackElement:getState() + 1
    local name = self.guidanceSteeringTrackNameElement:getText()

    -- Reset
    self:setWarningMessage("")

    -- might check if the name already exists
    if g_guidanceSteering:getTrackNameExist(name) then
        self:setWarningMessage(g_i18n:getText("guidanceSteering_tooltip_trackAlreadyExists"):format(name))
        return
    end

    Logger.info("Create: ", name)
    g_guidanceSteering:createTrack(id, name)

    self:displayTrackElement()
    self.guidanceSteeringTrackElement:setState(id)
end

function GuidanceSteeringStrategyFrame:onClickRemoveTrack()
    -- Reset
    self:setWarningMessage("")

    Logger.info("Remove: ", self.guidanceSteeringTrackElement:getState())
    local state = self.guidanceSteeringTrackElement:getState()
    g_guidanceSteering:deleteTrack(state)

    self:displayTrackElement()
    self:onClickLoadTrack(state - 1)
end

function GuidanceSteeringStrategyFrame:onClickSaveTrack()
    local vehicle = g_guidanceSteering.ui:getVehicle()
    if vehicle ~= nil then
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        local data = spec.guidanceData
        Logger.info("Save: ", self.guidanceSteeringTrackElement:getState())

        local state = self.guidanceSteeringTrackElement:getState()
        local track = g_guidanceSteering:getTrack(state)

        track.name = self.guidanceSteeringTrackNameElement:getText()
        track.strategy = self.guidanceSteeringStrategyElement:getState()
        track.method = self.guidanceSteeringStrategyMethodElement:getState()

        track.guidanceData.width = data.width
        track.guidanceData.offsetWidth = data.offsetWidth
        track.guidanceData.snapDirection = data.snapDirection
        track.guidanceData.driveTarget = data.driveTarget

        local id = self.guidanceSteeringTrackElement:getState()
        if g_currentMission:getIsServer() then
            g_guidanceSteering:saveTrack(id, track)
        else
            g_client:getServerConnection():sendEvent(TrackChangedEvent:new(id, track))
        end
    end
end

function GuidanceSteeringStrategyFrame:onClickLoadTrack(state)
    local track = g_guidanceSteering:getTrack(state)

    if track ~= nil then
        local vehicle = g_guidanceSteering.ui:getVehicle()
        if vehicle ~= nil then
            local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
            local data = spec.guidanceData

            self.guidanceSteeringTrackNameElement:setText(track.name)
            self.guidanceSteeringStrategyElement:setState(track.strategy)
            self.guidanceSteeringStrategyMethodElement:setState(track.method)

            -- First request reset to make sure the current track is clear
            vehicle:updateGuidanceData(nil, false, true)

            data.width = track.guidanceData.width
            data.offsetWidth = track.guidanceData.offsetWidth
            data.snapDirection = track.guidanceData.snapDirection
            data.driveTarget = track.guidanceData.driveTarget

            -- Now we send a creation event
            vehicle:updateGuidanceData(data, true, false)

            self:onDisplayElementsChanged()
        end
    end
end

function GuidanceSteeringStrategyFrame:onClickSetPointA()
end

function GuidanceSteeringStrategyFrame:onClickSetPointB()
end

function GuidanceSteeringStrategyFrame:onEnterPressedTrackName()
end

--- Functions

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
    for _, t in ipairs(g_guidanceSteering.savedTracks) do
        table.insert(texts, t.name)
    end

    self.guidanceSteeringTrackElement:setTexts(texts)
end

GuidanceSteeringStrategyFrame.L10N_SYMBOL = {}
