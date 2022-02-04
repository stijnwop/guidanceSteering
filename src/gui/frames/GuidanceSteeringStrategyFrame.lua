---
-- GuidanceSteeringStrategyFrame
--
-- Frame to handle the tracks and guidance strategy.
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringStrategyFrame
GuidanceSteeringStrategyFrame = {}

local GuidanceSteeringStrategyFrame_mt = Class(GuidanceSteeringStrategyFrame, TabbedMenuFrameElement)

GuidanceSteeringStrategyFrame.CONTROLS = {
    CONTAINER = "container",
    STRATEGY = "guidanceSteeringStrategyElement",
    STRATEGY_METHOD = "guidanceSteeringStrategyMethodElement",
    -- Text box
    TRACK_TEXT_INPUT = "guidanceSteeringTrackNameElement",
    -- Check box
    SCOPE_FARM_ID = "guidanceSteeringScopeFarmIdElement",
    -- Buttons
    POINT_A_BUTTON = "guidanceSteeringPointAButton",
    POINT_B_BUTTON = "guidanceSteeringPointBButton",
    CREATE_TRACK = "guidanceSteeringCreateTrackButton",
    SAVE_TRACK = "guidanceSteeringSaveTrackButton",
    REMOVE_TRACK = "guidanceSteeringRemoveTrackButton",
    ROTATE_TRACK = "guidanceSteeringRotateTrackButton",
    -- Warning box
    HELP_BOX = "settingsHelpBoxText",

    LIST = "list",
    TEMPLATE = "listItemTemplate",
    CATEGORY_TEMPLATE = "listCategoryTemplate",
}

---Creates a new instance of the GuidanceSteeringStrategyFrame.
---@return GuidanceSteeringStrategyFrame
function GuidanceSteeringStrategyFrame.new(ui, i18n)
    local self = TabbedMenuFrameElement.new(nil, GuidanceSteeringStrategyFrame_mt)

    self.guidanceSteering = g_currentMission.guidanceSteering

    self.ui = ui
    self.i18n = i18n
    self.allowSave = false
    self.rowToTrackId = {}

    self.lastLoadedTrackId = -1

    self:registerControls(GuidanceSteeringStrategyFrame.CONTROLS)

    return self
end

function GuidanceSteeringStrategyFrame:copyAttributes(src)
    GuidanceSteeringStrategyFrame:superClass().copyAttributes(self, src)

    self.ui = src.ui
    self.i18n = src.i18n
end

function GuidanceSteeringStrategyFrame:initialize()
    self.guidanceSteeringStrategyElement:setTexts({
        self.i18n:getText("guidanceSteering_strategy_abStraight"),
    })

    self.guidanceSteeringTrackNameElement:setText("Track name")

    self:build()
end

function GuidanceSteeringStrategyFrame:build()
    local uiFilename = self.ui.uiFilename

    -- Buttons
    self.guidanceSteeringCreateTrackButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringSaveTrackButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringRemoveTrackButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringRotateTrackButton:setImageFilename(nil, uiFilename)

    self.guidanceSteeringCreateTrackButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringStrategyFrame.UVS.CREATE_TRACK))
    self.guidanceSteeringSaveTrackButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringStrategyFrame.UVS.SAVE_TRACK))
    self.guidanceSteeringRemoveTrackButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringStrategyFrame.UVS.REMOVE_TRACK))
    self.guidanceSteeringRotateTrackButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringStrategyFrame.UVS.ROTATE_TRACK))
end

function GuidanceSteeringStrategyFrame:onFrameOpen()
    GuidanceSteeringStrategyFrame:superClass().onFrameOpen(self)

    self.guidanceSteering:subscribe(self)
    self:buildList()

    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        local strategy = vehicle:getGuidanceStrategy()

        self.guidanceSteeringStrategyMethodElement:setTexts(strategy:getTexts(self.i18n))
        self.guidanceSteeringStrategyMethodElement:setState(strategy.id + 1)
        self:displayMethodElements()

        self.allowSave = true
    end
end

function GuidanceSteeringStrategyFrame:onFrameClose()
    GuidanceSteeringStrategyFrame:superClass().onFrameClose(self)

    if self.allowSave then
        local element = self.rowToTrackId[self.list:getSelectedElement()]
        if element ~= nil then
            local trackId = element.trackId

            if trackId ~= nil then
                if self.lastLoadedTrackId ~= trackId then
                    self:loadTrack(trackId)
                    self.lastLoadedTrackId = trackId
                end
            end
        end

        self.allowSave = false
    end

    self.guidanceSteering:unsubscribe(self)
end

function GuidanceSteeringStrategyFrame:buildList()
    local selectedElement = self.list:getSelectedElement()
    local selectedTrackId, selectedIndex = nil, 2

    if selectedElement ~= nil then
        local track = self.rowToTrackId[selectedElement]
        if track ~= nil then
            selectedTrackId = track.trackId
        end
    end

    self.list:deleteListItems()

    self.rowToTrackId = {}

    local farmId = AccessHandler.EVERYONE
    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        farmId = vehicle:getOwnerFarmId()
    end

    local groups = { "Base group" }
    for _, group in ipairs(groups) do

        for id, track in pairs(self.guidanceSteering:getTracksForFarmId(farmId)) do
            local row = self:createItem(("%s - %s"):format(id, track.name))
            local selectionIndex = #self.list.elements

            self.rowToTrackId[row] = { trackId = id, selectionIndex = selectionIndex }

            if id == selectedTrackId then
                selectedIndex = selectionIndex
            end
        end
    end

    self.list:updateAbsolutePosition()

    -- Go to cell 2 and cell 1 is a category
    self.list:setSelectedIndex(selectedIndex)
    self:onListSelectionChanged()
end

---Create a list group
function GuidanceSteeringStrategyFrame:createGroupHeader(title)
    local item = self.listCategoryTemplate:clone(self.list)
    item:applyProfile("trackListItemGroup")
    item:getDescendantByName("title"):setText(title)
    item.doNotAlternate = true

    return item
end

---Create a list item
function GuidanceSteeringStrategyFrame:createItem(title)
    local item = self.listItemTemplate:clone(self.list)
    item:applyProfile("trackListItem")
    item:getDescendantByName("title"):setText(title)

    return item
end

--- Get the frame's main content element's screen size.
function GuidanceSteeringStrategyFrame:getMainElementSize()
    return self.container.size
end

--- Get the frame's main content element's screen position.
function GuidanceSteeringStrategyFrame:getMainElementPosition()
    return self.container.absPosition
end

function GuidanceSteeringStrategyFrame:onClickSelect(_, element)

end

function GuidanceSteeringStrategyFrame:onListSelectionChanged()
    local element = self.rowToTrackId[self.list:getSelectedElement()]
    if element ~= nil then
        self:onDisplayElementsChanged(element)
    end
end

function GuidanceSteeringStrategyFrame:onClickCreateTrack()
    -- Get a new Id
    local trackId = self.guidanceSteering:getNewTrackId()
    local trackData = self:getVehicleTrackData()

    if trackData ~= nil then
        -- might check if the name already exists
        if self.guidanceSteering:isExistingTrack(trackId, trackData) then
            self:setWarningMessage(self.i18n:getText("guidanceSteering_tooltip_trackAlreadyExists"):format(trackData.name))
            return
        end

        self:saveTrack(trackId, trackData)
    end
end

function GuidanceSteeringStrategyFrame:onClickSaveTrack()
    local element = self.rowToTrackId[self.list:getSelectedElement()]
    if element ~= nil then
        local trackId = element.trackId
        local track = self.guidanceSteering:getTrack(trackId)

        if track ~= nil then
            local trackData = self:getVehicleTrackData()
            if trackData ~= nil then
                self:saveTrack(trackId, trackData)
            end
        end
    end
end

function GuidanceSteeringStrategyFrame:onClickRemoveTrack()
    local element = self.rowToTrackId[self.list:getSelectedElement()]

    if element ~= nil then
        local trackId = element.trackId

        if trackId ~= 0 then
            self:deleteTrack(trackId)

            local vehicle = self.ui:getVehicle()
            if vehicle ~= nil then
                -- Reset loaded track when we are deleting it.
                if trackId ~= self.lastLoadedTrackId then
                    self:loadTrack(trackId)
                    self.lastLoadedTrackId = trackId
                end
            end
        end
    end
end

function GuidanceSteeringStrategyFrame:onClickRotateTrack()
    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        local data = vehicle:getGuidanceData()

        if not data.isCreated then
            self:setWarningMessage(self.i18n:getText("guidanceSteering_tooltip_trackIsNotCreated"))
            return
        end

        GlobalPositioningSystem.rotateTrack(vehicle, data)
    end
end

function GuidanceSteeringStrategyFrame:getFarmId()
    local isScoped = self.guidanceSteeringScopeFarmIdElement:getIsChecked()

    if isScoped then
        local vehicle = self.ui:getVehicle()
        if vehicle ~= nil then
            return vehicle:getOwnerFarmId()
        end
    end

    return AccessHandler.EVERYONE
end

function GuidanceSteeringStrategyFrame:getVehicleTrackData()
    local track = {}

    track.name = self.guidanceSteeringTrackNameElement:getText()
    track.strategy = self.guidanceSteeringStrategyElement:getState()
    track.method = self.guidanceSteeringStrategyMethodElement:getState()

    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        local data = vehicle:getGuidanceData()

        if not data.isCreated then
            self:setWarningMessage(self.i18n:getText("guidanceSteering_tooltip_trackIsNotCreated"))
            return nil
        end

        track.farmId = self:getFarmId()
        track.guidanceData = {}
        track.guidanceData.width = data.width
        track.guidanceData.offsetWidth = data.offsetWidth
        track.guidanceData.snapDirection = data.snapDirection
        track.guidanceData.driveTarget = data.driveTarget
    end

    return track
end

--- Track creation

function GuidanceSteeringStrategyFrame:onClickSetPointA()
    local vehicle = self.ui:getVehicle()

    if vehicle == nil then
        return
    end

    local spec = vehicle.spec_globalPositioningSystem
    if not spec.lineStrategy:getIsABDirectionPossible() then
        -- First request reset to make sure the current track is clear
        spec.multiActionEvent:reset()

        -- Simulate event invoked:
        -- 1 Reset
        -- 2 Point A
        for i = 1, 2 do
            spec.multiActionEvent:invoked()
        end

        vehicle:updateGuidanceData(nil, false, true)
        vehicle:interactWithGuidanceStrategy()
    end
end

function GuidanceSteeringStrategyFrame:onClickSetPointB()
    local vehicle = self.ui:getVehicle()

    if vehicle == nil then
        return
    end

    local spec = vehicle.spec_globalPositioningSystem
    if spec.lineStrategy:getIsABDirectionPossible() then
        -- Make sure the multi action event isn't doing anything in the meantime.
        spec.multiActionEvent:reset()

        -- Simulate event invoked:
        -- 1 Reset
        -- 2 Point A
        -- 3 Point B
        for i = 1, 3 do
            spec.multiActionEvent:invoked()
        end

        vehicle:interactWithGuidanceStrategy()
        GlobalPositioningSystem.computeGuidanceDirection(vehicle)
    end
end

function GuidanceSteeringStrategyFrame:onStrategyChanged(method)
    self:loadStrategy(method - 1)
    self:displayMethodElements()
end

--- Functions

---Called by the GuidanceSteering class
function GuidanceSteeringStrategyFrame:onTrackChanged(trackId)
    self:buildList()
end

function GuidanceSteeringStrategyFrame:loadTrack(trackId)
    local track = self.guidanceSteering:getTrack(trackId)

    local vehicle = self.ui:getVehicle()

    if vehicle ~= nil then
        local data = vehicle:getGuidanceData()

        -- First request reset to make sure the current track is clear
        vehicle:updateGuidanceData(nil, false, true)

        if self.guidanceSteering:isTrackValid(trackId) then
            data.width = track.guidanceData.width
            data.offsetWidth = track.guidanceData.offsetWidth
            data.snapDirection = track.guidanceData.snapDirection
            data.driveTarget = track.guidanceData.driveTarget

            -- Now we send a creation event
            vehicle:updateGuidanceData(data, true, false)

            vehicle:setGuidanceStrategy(track.strategy - 1)
        end
    end
end

function GuidanceSteeringStrategyFrame:saveTrack(trackId, track)
    g_client:getServerConnection():sendEvent(TrackSaveEvent:new(trackId, track))
end

function GuidanceSteeringStrategyFrame:deleteTrack(trackId)
    g_client:getServerConnection():sendEvent(TrackDeleteEvent:new(trackId))
end

function GuidanceSteeringStrategyFrame:loadStrategy(method)
    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        if method ~= nil then
            vehicle:setGuidanceStrategy(method)
        end
    end
end

function GuidanceSteeringStrategyFrame:setWarningMessage(message)
    g_gui:showInfoDialog({
        text = message,
        okText = self.i18n:getText("button_ok")
    })
end

function GuidanceSteeringStrategyFrame:onDisplayElementsChanged(element)
    self:displayTrackElements(element)
    self:displayMethodElements()
end

function GuidanceSteeringStrategyFrame:displayTrackElements(element)
    local track = self.guidanceSteering:getTrack(element.trackId)

    if track ~= nil then
        self.guidanceSteeringTrackNameElement:setText(track.name)
        self.guidanceSteeringStrategyElement:setState(track.strategy)
        self.guidanceSteeringStrategyMethodElement:setState(track.method)
    end
end

function GuidanceSteeringStrategyFrame:displayMethodElements()
    local method = self.guidanceSteeringStrategyMethodElement:getState() - 1

    if method == ABStrategy.AB then
        self.guidanceSteeringPointAButton:setVisible(true)
        self.guidanceSteeringPointBButton:setVisible(true)
    elseif method == ABStrategy.A_AUTO_B or method == ABStrategy.A_PLUS_HEADING then
        self.guidanceSteeringPointAButton:setVisible(true)
        self.guidanceSteeringPointBButton:setVisible(false)
    end
end

GuidanceSteeringStrategyFrame.UVS = {
    REMOVE_TRACK = { 780, 0, 65, 65 },
    CREATE_TRACK = { 780, 65, 65, 65 },
    SAVE_TRACK = { 845, 65, 65, 65 },
    ROTATE_TRACK = { 325, 65, 65, 65 },
}

GuidanceSteeringStrategyFrame.L10N_SYMBOL = {}
