GuidanceSteeringSettingsFrame = {}
local GuidanceSteeringSettingsFrame_mt = Class(GuidanceSteeringSettingsFrame, TabbedMenuFrameElement)

GuidanceSteeringSettingsFrame.CONTROLS = {
    CONTAINER = "container",
    SHOW_LINES = "guidanceSteeringShowLinesElement",
    SNAP_TERRAIN_ANGLE = "guidanceSteeringSnapAngleElement",
    ENABLE_STEERING = "guidanceSteeringEnableSteeringElement",
    WIDTH = "guidanceSteeringWidthElement",
    AUTO_WIDTH_BUTTON = "guidanceSteeringWidthButton",
}

function GuidanceSteeringSettingsFrame:new(i18n)
    local self = TabbedMenuFrameElement:new(nil, GuidanceSteeringSettingsFrame_mt)

    self.i18n = i18n
    self.vehicle = nil

    self:registerControls(GuidanceSteeringSettingsFrame.CONTROLS)

    return self
end

function GuidanceSteeringSettingsFrame:copyAttributes(src)
    GuidanceSteeringSettingsFrame:superClass().copyAttributes(self, src)

    self.i18n = src.i18n
end

function GuidanceSteeringSettingsFrame:initialize()
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
        self.guidanceSteeringWidthElement:setState(data.width)
    end
end


function GuidanceSteeringSettingsFrame:onFrameClose()
    GuidanceSteeringSettingsFrame:superClass().onFrameClose(self)

    local vehicle = g_guidanceSteering.ui:getVehicle()
    if vehicle ~= nil then
        local spec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        local data = spec.guidanceData

        local width = self.guidanceSteeringWidthElement:getState()
        local showGuidanceLines = self.guidanceSteeringShowLinesElement:getIsChecked()
        local guidanceSteeringIsActive = self.guidanceSteeringEnableSteeringElement:getIsChecked()
        local guidanceTerrainAngleIsActive = self.guidanceSteeringSnapAngleElement:getIsChecked()

        spec.showGuidanceLines = showGuidanceLines
        spec.guidanceSteeringIsActive = guidanceSteeringIsActive
        spec.guidanceTerrainAngleIsActive = guidanceTerrainAngleIsActive

        data.width = width

        -- todo: sync and call data change
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