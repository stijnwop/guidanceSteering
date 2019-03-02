GuidanceSteeringSettingsFrame = {}
local GuidanceSteeringSettingsFrame_mt = Class(GuidanceSteeringSettingsFrame, TabbedMenuFrameElement)

GuidanceSteeringSettingsFrame.CONTROLS = {
    CONTAINER = "container",
    SHOW_LINES = "guidanceSteeringShowLinesElement",
    SNAP_TERRAIN_ANGLE = "guidanceSteeringSnapAngleElement",
    ENABLE_STEERING = "guidanceSteeringEnableSteeringElement",
    WIDTH = "guidanceSteeringWidthElement",
    OFFSET = "guidanceSteeringOffsetWidthElement",
    WIDTH_INCREMENT = "guidanceSteeringWidthInCrementElement",
    AUTO_WIDTH_BUTTON = "guidanceSteeringWidthButton",
    CHANGE_WIDTH_BUTTON = "guidanceSteeringChangeWidthButton",
    CHANGE_OFFSET_BUTTON = "guidanceSteeringChangeOffsetWidthButton",
    RESET_OFFSET_BUTTON = "guidanceSteeringResetOffsetWidthButton",
}
GuidanceSteeringSettingsFrame.INCREMENTS = {
    0.01,
    0.05,
    0.1,
    0.5,
    1,
    -1,
    -0.5,
    -0.1,
    -0.05,
    -0.01,
}

function GuidanceSteeringSettingsFrame:new(i18n)
    local self = TabbedMenuFrameElement:new(nil, GuidanceSteeringSettingsFrame_mt)

    self.i18n = i18n

    self.currentWidth = 0
    self.currentOffset = 0
    self.currentWidthIncrement = 0

    self.allowSave = false

    self:registerControls(GuidanceSteeringSettingsFrame.CONTROLS)

    return self
end

function GuidanceSteeringSettingsFrame:copyAttributes(src)
    GuidanceSteeringSettingsFrame:superClass().copyAttributes(self, src)

    self.i18n = src.i18n
end

function GuidanceSteeringSettingsFrame:initialize()
    local increments = {}

    for _, v in ipairs(GuidanceSteeringSettingsFrame.INCREMENTS) do
        table.insert(increments, v)
    end

    self.guidanceSteeringWidthInCrementElement:setTexts(increments)
end

function GuidanceSteeringSettingsFrame:onFrameOpen()
    GuidanceSteeringSettingsFrame:superClass().onFrameOpen(self)

    local vehicle = g_guidanceSteering.ui:getVehicle()
    if vehicle ~= nil then
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        local data = spec.guidanceData

        self.guidanceSteeringShowLinesElement:setIsChecked(spec.showGuidanceLines)
        self.guidanceSteeringSnapAngleElement:setIsChecked(spec.guidanceTerrainAngleIsActive)
        self.guidanceSteeringEnableSteeringElement:setIsChecked(spec.guidanceSteeringIsActive)
        self.currentWidth = data.width
        self.currentOffset = data.offsetWidth
        self.guidanceSteeringWidthElement:setText(tostring(self.currentWidth))
        self.guidanceSteeringOffsetWidthElement:setText(tostring(self.currentOffset))

        self.allowSave = true
    end
end

function GuidanceSteeringSettingsFrame:onFrameClose()
    GuidanceSteeringSettingsFrame:superClass().onFrameClose(self)

    if self.allowSave then
        local vehicle = g_guidanceSteering.ui:getVehicle()
        if vehicle ~= nil then
            local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
            local data = spec.guidanceData

            local showGuidanceLines = self.guidanceSteeringShowLinesElement:getIsChecked()
            local guidanceSteeringIsActive = self.guidanceSteeringEnableSteeringElement:getIsChecked()
            local guidanceTerrainAngleIsActive = self.guidanceSteeringSnapAngleElement:getIsChecked()
            local state = self.guidanceSteeringWidthInCrementElement:getState()
            local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state]

            -- Todo: cleanup later
            if guidanceSteeringIsActive and not data.isCreated then
                g_currentMission:showBlinkingWarning(g_i18n:getText("guidanceSteering_warning_createTrackFirst"), 4000)
            else
                spec.lastInputValues.guidanceSteeringIsActive = guidanceSteeringIsActive
            end

            spec.lastInputValues.showGuidanceLines = showGuidanceLines
            spec.lastInputValues.guidanceTerrainAngleIsActive = guidanceTerrainAngleIsActive
            spec.lastInputValues.widthIncrement = math.abs(increment)

            if data.width ~= self.currentWidth or data.offsetWidth ~= self.currentOffset then
                data.width = self.currentWidth
                data.offsetWidth = self.currentOffset

                vehicle:updateGuidanceData(data, false, false)
            end
        end

        self.allowSave = false
    end
end

function GuidanceSteeringSettingsFrame:onClickAutoWidth()
    local vehicle = g_guidanceSteering.ui:getVehicle()

    if vehicle ~= nil then
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        local width, offset = GlobalPositioningSystem.getActualWorkWidth(spec.guidanceNode, vehicle)
        self.currentWidth = width
        self.currentOffset = offset
        self.guidanceSteeringWidthElement:setText(tostring(self.currentWidth))
    end
end

function GuidanceSteeringSettingsFrame:onClickChangeWidth()
    local state = self.guidanceSteeringWidthInCrementElement:getState()
    local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state]

    self.currentWidth = math.max(self.currentWidth + increment, 0)
    self.guidanceSteeringWidthElement:setText(tostring(self.currentWidth))
end

function GuidanceSteeringSettingsFrame:onClickResetOffsetWidth()
    self.currentOffset = 0
    self.guidanceSteeringOffsetWidthElement:setText(tostring(self.currentOffset))
end

function GuidanceSteeringSettingsFrame:onClickChangeOffsetWidth()
    local state = self.guidanceSteeringWidthInCrementElement:getState()
    local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state]

    local threshold = self.currentWidth * 0.5
    self.currentOffset = MathUtil.clamp(self.currentOffset + increment, -threshold, threshold)
    self.guidanceSteeringOffsetWidthElement:setText(tostring(self.currentOffset))
end

--- Get the frame's main content element's screen size.
function GuidanceSteeringSettingsFrame:getMainElementSize()
    return self.container.size
end

--- Get the frame's main content element's screen position.
function GuidanceSteeringSettingsFrame:getMainElementPosition()
    return self.container.absPosition
end

function GuidanceSteeringSettingsFrame:updateToolTipBoxVisibility(box)
    local hasText = box.text ~= nil and box.text ~= ""
    box:setVisible(hasText)
end

GuidanceSteeringSettingsFrame.L10N_SYMBOL = {}
