GuidanceSteeringSettingsFrame = {}
local GuidanceSteeringSettingsFrame_mt = Class(GuidanceSteeringSettingsFrame, TabbedMenuFrameElement)

GuidanceSteeringSettingsFrame.CONTROLS = {
    CONTAINER = "container",
    SHOW_LINES = "guidanceSteeringShowLinesElement",
    SNAP_TERRAIN_ANGLE = "guidanceSteeringSnapAngleElement",
    ENABLE_STEERING = "guidanceSteeringEnableSteeringElement",
    WIDTH = "guidanceSteeringWidthElement",
    WIDTH_INCREMENT = "guidanceSteeringWidthInCrementElement",
    AUTO_WIDTH_BUTTON = "guidanceSteeringWidthButton",
}
GuidanceSteeringSettingsFrame.INCREMENTS = {
    [1] = 0.01,
    [2] = 0.05,
    [3] = 0.1,
    [4] = 0.5,
    [5] = 1,
}

function GuidanceSteeringSettingsFrame:new(i18n)
    local self = TabbedMenuFrameElement:new(nil, GuidanceSteeringSettingsFrame_mt)

    self.i18n = i18n
    self.vehicle = nil

    self.currentWidth = 0
    self.currentWidth = 0
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
        self.guidanceSteeringWidthElement:setTexts({ data.width })
        self.currentWidth = data.width

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

            spec.showGuidanceLines = showGuidanceLines
            spec.guidanceSteeringIsActive = guidanceSteeringIsActive
            spec.guidanceTerrainAngleIsActive = guidanceTerrainAngleIsActive

            data.width = self.currentWidth

            -- todo: sync and call data change
        end

        self.allowSave = false
    end
end

function GuidanceSteeringSettingsFrame:onClickAutoWidth()
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