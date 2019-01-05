
GuidanceSteeringStrategyFrame = {}
local GuidanceSteeringStrategyFrame_mt = Class(GuidanceSteeringStrategyFrame, TabbedMenuFrameElement)

GuidanceSteeringStrategyFrame.CONTROLS = {
    CONTAINER = "container",
}

function GuidanceSteeringStrategyFrame:new(i18n)
    local self = TabbedMenuFrameElement:new(nil, GuidanceSteeringStrategyFrame_mt)

    self.i18n = i18n

    self:registerControls(GuidanceSteeringStrategyFrame.CONTROLS)

    return self
end

function GuidanceSteeringStrategyFrame:copyAttributes(src)
    GuidanceSteeringStrategyFrame:superClass().copyAttributes(self, src)

    self.i18n = src.i18n
end

function GuidanceSteeringStrategyFrame:initialize()
end

function GuidanceSteeringStrategyFrame:onFrameOpen()
    GuidanceSteeringStrategyFrame:superClass().onFrameOpen(self)
end

---Get the frame's main content element's screen size.
function GuidanceSteeringStrategyFrame:getMainElementSize()
    return self.container.size
end

---Get the frame's main content element's screen position.
function GuidanceSteeringStrategyFrame:getMainElementPosition()
    return self.container.absPosition
end

GuidanceSteeringStrategyFrame.L10N_SYMBOL = {
}