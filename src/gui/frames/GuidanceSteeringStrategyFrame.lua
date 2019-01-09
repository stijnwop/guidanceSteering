GuidanceSteeringStrategyFrame = {}
local GuidanceSteeringStrategyFrame_mt = Class(GuidanceSteeringStrategyFrame, TabbedMenuFrameElement)

GuidanceSteeringStrategyFrame.CONTROLS = {
    CONTAINER = "container",
    STRATEGY = "guidanceSteeringStrategyElement",
    STRATEGY_METHOD = "guidanceSteeringStrategyMethodElement",
    TRACK = "guidanceSteeringTrackElement",
    CARDINALS = "guidanceSteeringCardinalsElement",

    -- Buttons
    POINT_A_BUTTON = "guidanceSteeringPointAButton",
    POINT_B_BUTTON = "guidanceSteeringPointBButton"
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
        local vehicle = g_guidanceSteering.ui:getVehicle()
        if vehicle ~= nil then
            local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
            local data = spec.guidanceData
            Logger.info("Auto save: ", self.guidanceSteeringTrackElement:getState())

            local saveData = {}

            saveData.strategy = self.guidanceSteeringStrategyElement:getState()
            saveData.method = self.guidanceSteeringStrategyMethodElement:getState()
            saveData.width = data.width
            saveData.offsetWidth = data.offsetWidth
            saveData.snapDirection = data.snapDirection
            saveData.driveTarget = data.driveTarget

            local id = self.guidanceSteeringTrackElement:getState()
            if g_currentMission:getIsServer() then
                g_guidanceSteering:saveTrack(id, saveData)
                vehicle:setGuidanceData(data)
            else
                g_client:getServerConnection():sendEvent(TrackChangedEvent:new(id, saveData))
            end
        end

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
    local state = self.guidanceSteeringTrackElement:getState() + 1

    Logger.info("Create: ", self.guidanceSteeringTrackElement:getState())
    g_guidanceSteering:createTrack(("Some name %s"):format(state))

    self:displayTrackElement()
    self.guidanceSteeringTrackElement:setState(state)
end

function GuidanceSteeringStrategyFrame:onClickRemoveTrack()

    Logger.info("Remove: ", self.guidanceSteeringTrackElement:getState())
    local state = self.guidanceSteeringTrackElement:getState()
    g_guidanceSteering:deleteTrack(state)

    self:displayTrackElement()
    self.guidanceSteeringTrackElement:setState(state - 1)
end

function GuidanceSteeringStrategyFrame:onClickSetPointA()
end

function GuidanceSteeringStrategyFrame:onClickSetPointB()
end

--- Functions

function GuidanceSteeringStrategyFrame:buildDataTable(current)

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
    for id, t in ipairs(g_guidanceSteering.savedTracks) do
        table.insert(texts, t.name)
    end

    self.guidanceSteeringTrackElement:setTexts(texts)
end

GuidanceSteeringStrategyFrame.L10N_SYMBOL = {}