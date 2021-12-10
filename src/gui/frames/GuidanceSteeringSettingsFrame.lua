---
-- GuidanceSteeringStrategyFrame
--
-- Frame to handle the settings and to modify the current guidance data.
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringSettingsFrame
GuidanceSteeringSettingsFrame = {}

local GuidanceSteeringSettingsFrame_mt = Class(GuidanceSteeringSettingsFrame, TabbedMenuFrameElement)

GuidanceSteeringSettingsFrame.CONTROLS = {
    WIDTH_DISPLAY = "widthDisplay",
    WIDTH_PLUS = "guidanceSteeringMinusButton",
    WIDTH_MINUS = "guidanceSteeringPlusButton",
    WIDTH_RESET = "guidanceSteeringResetWidthButton",
    WIDTH_INCREMENT = "guidanceSteeringWidthIncrementElement",
    WIDTH_TEXT = "guidanceSteeringWidthText",

    OFFSET_DISPLAY = "offsetDisplay",
    OFFSET_PLUS = "guidanceSteeringMinusOffsetButton",
    OFFSET_MINUS = "guidanceSteeringPlusOffsetButton",
    OFFSET_RESET = "guidanceSteeringResetOffsetButton",
    OFFSET_INCREMENT = "guidanceSteeringOffsetIncrementElement",
    OFFSET_TEXT = "guidanceSteeringOffsetWidthText",

    HEADLAND_DISPLAY = "headlandDisplay",
    HEADLAND_MODE = "guidanceSteeringHeadlandModeElement",
    HEADLAND_DISTANCE = "guidanceSteeringHeadlandDistanceElement",

    TOGGLE_SHOW_LINES = "guidanceSteeringShowLinesElement",
    OFFSET_LINES = "guidanceSteeringLinesOffsetElement",
    TOGGLE_SNAP_TERRAIN_ANGLE = "guidanceSteeringSnapAngleElement",
    TOGGLE_ENABLE_STEERING = "guidanceSteeringEnableSteeringElement",
    TOGGLE_AUTO_INVERT_OFFSET = "guidanceSteeringAutoInvertOffsetElement",

    CONTAINER = "container",
    BOX_LAYOUT_SETTINGS = "boxLayoutSettings",
}

GuidanceSteeringSettingsFrame.INCREMENTS = { 0.01, 0.05, 0.1, 0.5, 1 }

---Creates a new instance of the GuidanceSteeringSettingsFrame.
---@return GuidanceSteeringSettingsFrame
function GuidanceSteeringSettingsFrame.new(ui, i18n)
    local self = TabbedMenuFrameElement.new(nil, GuidanceSteeringSettingsFrame_mt)

    self.ui = ui
    self.i18n = i18n

    self.currentGuidanceWidth = 0
    self.currentWidthIncrement = 0

    self.currentGuidanceOffset = 0
    self.currentOffsetIncrement = 0

    self.allowSave = false

    self:registerControls(GuidanceSteeringSettingsFrame.CONTROLS)

    return self
end

function GuidanceSteeringSettingsFrame:copyAttributes(src)
    GuidanceSteeringSettingsFrame:superClass().copyAttributes(self, src)

    self.ui = src.ui
    self.i18n = src.i18n
end

function GuidanceSteeringSettingsFrame:initialize()
    local headlandModes = {}
    for _, mode in pairs(OnHeadlandState.MODES) do
        table.insert(headlandModes, self.i18n:getText(("guidanceSteering_headland_mode_%d"):format(mode - 1)))
    end

    self.guidanceSteeringHeadlandModeElement:setTexts(headlandModes)

    local initialUnit = self:getFormattedUnitLength(0)
    self.guidanceSteeringHeadlandDistanceElement:setText(tostring(0))
    self.guidanceSteeringWidthText:setText(initialUnit)
    self.guidanceSteeringOffsetWidthText:setText(initialUnit)

    self:build()
end

function GuidanceSteeringSettingsFrame:onFrameOpen()
    GuidanceSteeringSettingsFrame:superClass().onFrameOpen(self)

    local increments = {}
    for _, increment in pairs(GuidanceSteeringSettingsFrame.INCREMENTS) do
        table.insert(increments, tostring(self:getUnitLength(increment)))
    end

    self.guidanceSteeringWidthIncrementElement:setTexts(increments)
    self.guidanceSteeringOffsetIncrementElement:setTexts(increments)

    local offsets = stream({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }):map(function(offset)
        return tostring(offset * GuidanceSteering.GROUND_CLEARANCE_OFFSET)
    end)
    self.offsets = offsets:toList()
    self.guidanceSteeringLinesOffsetElement:setTexts(self.offsets)

    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        local spec = vehicle.spec_globalPositioningSystem
        local data = spec.guidanceData

        self.guidanceSteeringShowLinesElement:setIsChecked(g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled())
        self.guidanceSteeringSnapAngleElement:setIsChecked(g_currentMission.guidanceSteering:isTerrainAngleSnapEnabled())
        self.guidanceSteeringEnableSteeringElement:setIsChecked(spec.guidanceSteeringIsActive)
        self.guidanceSteeringAutoInvertOffsetElement:setIsChecked(spec.autoInvertOffset)

        self.currentGuidanceWidth = data.width
        self.currentGuidanceOffset = data.offsetWidth
        self.guidanceSteeringWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceWidth))
        self.guidanceSteeringOffsetWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceOffset))

        local currentHeadlandActDistance = spec.headlandActDistance
        self.guidanceSteeringHeadlandModeElement:setState(spec.headlandMode)
        self.guidanceSteeringHeadlandDistanceElement:setText(tostring(currentHeadlandActDistance))

        self.allowSave = true
    end

    self.boxLayoutSettings:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayoutSettings)
        self:setSoundSuppressed(false)
    end
end

function GuidanceSteeringSettingsFrame:onFrameClose()
    GuidanceSteeringSettingsFrame:superClass().onFrameClose(self)

    if self.allowSave then
        -- Client only
        g_currentMission.guidanceSteering:setIsShowGuidanceLinesEnabled(self.guidanceSteeringShowLinesElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsTerrainAngleSnapEnabled(self.guidanceSteeringSnapAngleElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsGuidanceEnabled(self.guidanceSteeringEnableSteeringElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsAutoInvertOffsetEnabled(self.guidanceSteeringAutoInvertOffsetElement:getIsChecked())
        g_currentMission.guidanceSteering:setLineOffset(tonumber(self.offsets[self.guidanceSteeringLinesOffsetElement:getState()]))

        local vehicle = self.ui:getVehicle()
        if vehicle ~= nil then
            local spec = vehicle.spec_globalPositioningSystem
            local data = spec.guidanceData

            local state = self.guidanceSteeringWidthIncrementElement:getState()
            local headlandMode = self.guidanceSteeringHeadlandModeElement:getState()
            local headlandActDistance = tonumber(self.guidanceSteeringHeadlandDistanceElement:getText()) or 0
            local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state]

            -- Todo: cleanup later
            local guidanceSteeringIsActive = g_currentMission.guidanceSteering:isGuidanceEnabled()
            if guidanceSteeringIsActive and not data.isCreated then
                g_currentMission:showBlinkingWarning(self.i18n:getText("guidanceSteering_warning_createTrackFirst"), 4000)
            else
                spec.lastInputValues.guidanceSteeringIsActive = guidanceSteeringIsActive
            end

            spec.lastInputValues.autoInvertOffset = g_currentMission.guidanceSteering:isAutoInvertOffsetEnabled()
            spec.lastInputValues.widthIncrement = math.abs(increment)

            if spec.headlandMode ~= headlandMode or spec.headlandActDistance ~= headlandActDistance then
                spec.headlandMode = headlandMode
                spec.headlandActDistance = headlandActDistance
                -- Update other clients
                g_client:getServerConnection():sendEvent(HeadlandModeChangedEvent:new(vehicle, headlandMode, headlandActDistance))
            end

            if data.width ~= nil and data.width ~= self.currentGuidanceWidth
                or data.offsetWidth ~= nil and data.offsetWidth ~= self.currentGuidanceOffset then
                data.width = self.currentGuidanceWidth
                data.offsetWidth = self.currentGuidanceOffset

                vehicle:updateGuidanceData(data, false, false)
            end
        end

        self.allowSave = false
    end
end

function GuidanceSteeringSettingsFrame:updateToolTipBoxVisibility(box)
    local hasText = box.text ~= nil and box.text ~= ""
    box:setVisible(hasText)
end

function GuidanceSteeringSettingsFrame:build()
    local uiFilename = self.ui.uiFilename

    self.widthDisplay:setImageFilename(uiFilename)
    self.widthDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.WIDTH_DISPLAY)))

    self.offsetDisplay:setImageFilename(uiFilename)
    self.offsetDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.OFFSET_DISPLAY)))

    -- Buttons
    self.guidanceSteeringPlusButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringMinusButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringResetWidthButton:setImageFilename(nil, uiFilename)

    self.guidanceSteeringPlusOffsetButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringMinusOffsetButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringResetOffsetButton:setImageFilename(nil, uiFilename)

    self.guidanceSteeringPlusButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_PLUS))
    self.guidanceSteeringMinusButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_MIN))
    self.guidanceSteeringResetWidthButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_RESET))
    --
    self.guidanceSteeringPlusOffsetButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_PLUS))
    self.guidanceSteeringMinusOffsetButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_MIN))
    self.guidanceSteeringResetOffsetButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_RESET))
end

---Callbacks

function GuidanceSteeringSettingsFrame:onClickIncrementWidth()
    self:changeWidth(1)
end

function GuidanceSteeringSettingsFrame:onClickDecrementWidth()
    self:changeWidth(-1)
end

function GuidanceSteeringSettingsFrame:onClickResetWidth()
    self.currentGuidanceWidth = 0
    self.guidanceSteeringWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceWidth))
end

function GuidanceSteeringSettingsFrame:onClickAutoWidth()
    local vehicle = self.ui:getVehicle()

    if vehicle ~= nil then
        local spec = vehicle.spec_globalPositioningSystem
        local width, offset = GlobalPositioningSystem.getActualWorkWidth(spec.guidanceNode, vehicle)
        self.currentGuidanceWidth = width
        self.currentGuidanceOffset = offset
        self.guidanceSteeringWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceWidth))
        self.guidanceSteeringOffsetWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceOffset))

        self:updateOffsetUVs()
    end
end

function GuidanceSteeringSettingsFrame:changeWidth(direction)
    local state = self.guidanceSteeringWidthIncrementElement:getState()
    local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state] * direction

    self.currentGuidanceWidth = math.max(self.currentGuidanceWidth + increment, 0)
    self.guidanceSteeringWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceWidth))
end

function GuidanceSteeringSettingsFrame:onClickIncrementOffsetWidth()
    self:changeOffsetWidth(1)
end

function GuidanceSteeringSettingsFrame:onClickDecrementOffsetWidth()
    self:changeOffsetWidth(-1)
end

function GuidanceSteeringSettingsFrame:onClickInvertOffset()
    self.currentGuidanceOffset = -self.currentGuidanceOffset
    self.guidanceSteeringOffsetWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceOffset))
    self:updateOffsetUVs()
end

function GuidanceSteeringSettingsFrame:onClickResetOffsetWidth()
    self.currentGuidanceOffset = 0
    self.guidanceSteeringOffsetWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceOffset))
end

function GuidanceSteeringSettingsFrame:changeOffsetWidth(direction)
    local state = self.guidanceSteeringOffsetIncrementElement:getState()
    local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state] * direction

    local threshold = self.currentGuidanceWidth * 0.5
    self.currentGuidanceOffset = MathUtil.clamp(self.currentGuidanceOffset + increment, -threshold, threshold)
    self.guidanceSteeringOffsetWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceOffset))

    self:updateOffsetUVs()
end

function GuidanceSteeringSettingsFrame:onHeadlandDistanceChanged(_, text)
    local lastDistance = tonumber(text)
    local textLenght = utf8Strlen(text)

    if lastDistance == nil and textLenght > 0 then
        lastDistance = 0
        self.guidanceSteeringHeadlandDistanceElement:setText(tostring(lastDistance))
    end

    if lastDistance ~= nil then
        if lastDistance > OnHeadlandState.MAX_ACT_DISTANCE then
            lastDistance = OnHeadlandState.MAX_ACT_DISTANCE
            self.guidanceSteeringHeadlandDistanceElement:setText(tostring(lastDistance))
        end
    end
end

function GuidanceSteeringSettingsFrame:updateOffsetUVs()
    if self.currentGuidanceOffset < 0 then
        self.offsetDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.OFFSET_DISPLAY)))
    else
        self.offsetDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.OFFSET_DISPLAY_RIGHT)))
    end
end

function GuidanceSteeringSettingsFrame:getUnitLength(meters)
    if self.i18n.useMiles then
        return meters * 3.2808
    end

    return meters
end

function GuidanceSteeringSettingsFrame:getFormattedUnitLength(meters)
    local unitLength = self:getUnitLength(meters)
    if self.i18n.useMiles then
        return string.format("%.2f %s", unitLength, "ft")
    end

    return string.format("%.2f %s", unitLength, "m")
end

GuidanceSteeringSettingsFrame.L10N_SYMBOL = {}

GuidanceSteeringSettingsFrame.UVS = {
    WIDTH_DISPLAY = { 0, 0, 130, 130 },
    BUTTON_PLUS = { 260, 0, 65, 65 },
    BUTTON_MIN = { 260, 65, 65, 65 },
    BUTTON_RESET = { 325, 0, 65, 65 },
    OFFSET_DISPLAY = { 130, 0, 130, 130 },
    OFFSET_DISPLAY_RIGHT = { 520, 0, 130, 130 },
    HEADLAND_DISPLAY = { 390, 0, 130, 130 },
}
