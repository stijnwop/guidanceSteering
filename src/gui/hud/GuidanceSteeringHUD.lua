---
-- GuidanceSteeringHUD
--
-- HUD for GuidanceSteering
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringHUD
GuidanceSteeringHUD = {}

local GuidanceSteeringHUD_mt = Class(GuidanceSteeringHUD)

---Creates a new instance of the GuidanceSteeringHUD.
---@return GuidanceSteeringHUD
function GuidanceSteeringHUD:new(mission, speedMeterDisplay, i18n, uiFilename)
    local instance = setmetatable({}, GuidanceSteeringHUD_mt)

    instance.speedMeterDisplay = speedMeterDisplay
    instance.i18n = i18n
    instance.uiFilename = uiFilename

    instance.vehicle = nil
    instance.receiverIconIsActive = false
    instance.steeringIconIsActive = false
    instance.laneText = "0"

    SpeedMeterDisplay.storeScaledValues = Utils.appendedFunction(SpeedMeterDisplay.storeScaledValues, GuidanceSteeringHUD.speedMeterDisplay_storeScaledValues)
    SpeedMeterDisplay.draw = Utils.appendedFunction(SpeedMeterDisplay.draw, GuidanceSteeringHUD.speedMeterDisplay_draw)

    return instance
end

function GuidanceSteeringHUD:delete()
    if self.stateBox ~= nil then
        self.stateBox:delete()
    end
end

function GuidanceSteeringHUD:load()
    self:createElements()
    self:setVehicle(nil)
end

--- Create the elements for the HUD.
function GuidanceSteeringHUD:createElements()
    local rightX = 1 - g_safeFrameOffsetX -- right of screen.
    local topRightX, topRightY = SpeedMeterDisplay.getBackgroundPosition(1)
    local marginWidth, marginHeight = self.speedMeterDisplay:scalePixelToScreenVector(GuidanceSteeringHUD.SIZE.BOX_MARGIN)

    local y = self:createBox(self.uiFilename, rightX, topRightY - marginHeight) - marginHeight
end

--- Create the box with the HUD icons.
function GuidanceSteeringHUD:createBox(hudAtlasPath, x, y)
    local boxWidth, boxHeight = self.speedMeterDisplay:scalePixelToScreenVector(GuidanceSteeringHUD.SIZE.BOX)
    local posX = x - boxWidth * 0.5

    local iconWidth, iconHeight = self.speedMeterDisplay:scalePixelToScreenVector(GuidanceSteeringHUD.SIZE.ICON)

    local boxOverlay = Overlay:new(nil, posX, y, boxWidth, boxHeight)
    local boxElement = HUDElement:new(boxOverlay)
    self.stateBox = boxElement
    self.stateBox:setVisible(true)
    self.speedMeterDisplay:addChild(boxElement)

    self.steeringIcon = self:createIcon(hudAtlasPath, posX, y, iconWidth, iconHeight, GuidanceSteeringHUD.UV.STEERING_WHEEL_DISABLED)

    self.stateBox:addChild(self.steeringIcon)
    self.steeringIcon:setVisible(true)

    y = y + iconHeight

    local separator = self:createHorizontalSeparator(g_baseHUDFilename, posX, y)
    self.stateBox:addChild(separator)

    self.receiverIcon = self:createIcon(hudAtlasPath, posX, y, iconWidth, iconHeight, GuidanceSteeringHUD.UV.RECEIVER)

    self.stateBox:addChild(self.receiverIcon)
    self.receiverIcon:setColor(unpack(GuidanceSteeringHUD.COLOR.INACTIVE))
    self.receiverIcon:setVisible(true)

    y = y + iconHeight

    separator = self:createHorizontalSeparator(g_baseHUDFilename, posX, y)
    self.stateBox:addChild(separator)

    self.laneIcon = self:createIcon(hudAtlasPath, posX, y, iconWidth, iconHeight, GuidanceSteeringHUD.UV.LANE)

    self.stateBox:addChild(self.laneIcon)
    self.laneIcon:setVisible(true)

    return x - boxWidth
end

--- Create icon for the HUD.
function GuidanceSteeringHUD:createIcon(imagePath, baseX, baseY, width, height, uvs)
    local iconOverlay = Overlay:new(imagePath, baseX, baseY, width, height)
    iconOverlay:setUVs(getNormalizedUVs(uvs))
    local element = HUDElement:new(iconOverlay)

    element:setVisible(false)

    return element
end

--- Create a horizontal separator.
function GuidanceSteeringHUD:createHorizontalSeparator(hudAtlasPath, baseX, baseY)
    local posX, posY = getNormalizedScreenValues(unpack(GuidanceSteeringHUD.POSITION.SEPARATOR))
    local width, height = getNormalizedScreenValues(unpack(GuidanceSteeringHUD.SIZE.SEPARATOR))
    local separatorOverlay = Overlay:new(hudAtlasPath, baseX + posX, baseY + posY, width, height)
    separatorOverlay:setUVs(getNormalizedUVs(SpeedMeterDisplay.UV.SEPARATOR))
    separatorOverlay:setColor(unpack(SpeedMeterDisplay.COLOR.SEPARATOR))

    return HUDElement:new(separatorOverlay)
end

function GuidanceSteeringHUD:storeScaledValues()
    if self.stateBox == nil then
        return
    end

    local boxPosX, boxPosY = self.stateBox:getPosition()
    local boxWidth, boxHeight = self.stateBox:getWidth(), self.stateBox:getHeight()
    local textOffX, textOffY = self.speedMeterDisplay:scalePixelToScreenVector(GuidanceSteeringHUD.POSITION.LANE_TEXT)

    self.laneTextPositionX = boxPosX + boxWidth + textOffX
    self.laneTextPositionY = boxPosY + boxHeight + textOffY
    self.laneTextSize = self.speedMeterDisplay:scalePixelToScreenHeight(GuidanceSteeringHUD.TEXT_SIZE.LANE)

    self.angleTextPositionX = self.laneTextPositionX
    self.angleTextPositionY = self.laneTextPositionY + textOffY * 2
end

--- Sets the current vehicle to display on the HUD.
function GuidanceSteeringHUD:setVehicle(vehicle)
    self.vehicle = vehicle
    if self.stateBox ~= nil then
        self.stateBox:setVisible(vehicle ~= nil)
    end
end

--- Gets the lane text depending on the direction.
function GuidanceSteeringHUD:getLaneText(laneNumber)
    local lane = math.abs(laneNumber)
    if laneNumber < 0 then
        return ("-%s"):format(lane)
    elseif laneNumber > 0 then
        return ("+%s"):format(lane)
    end
    return ("%s"):format(lane)
end

function GuidanceSteeringHUD:drawText()
    if self.speedMeterDisplay.isVehicleDrawSafe and self.stateBox:getVisible() then
        local spec = self.vehicle.spec_globalPositioningSystem
        local data = spec.guidanceData

        self.laneText = self:getLaneText(data.currentLane)
        if self.steeringIconIsActive ~= spec.guidanceSteeringIsActive then
            self.steeringIconIsActive = spec.guidanceSteeringIsActive
            local uvs = spec.guidanceSteeringIsActive and GuidanceSteeringHUD.UV.STEERING_WHEEL_ENABLED or GuidanceSteeringHUD.UV.STEERING_WHEEL_DISABLED
            local color = spec.guidanceSteeringIsActive and GuidanceSteeringHUD.COLOR.ACTIVE or GuidanceSteeringHUD.COLOR.INACTIVE
            self.steeringIcon:setUVs(getNormalizedUVs(uvs))
            self.steeringIcon:setColor(unpack(color))
        end

        if self.receiverIconIsActive ~= spec.guidanceIsActive then
            self.receiverIconIsActive = spec.guidanceIsActive
            local color = spec.guidanceIsActive and GuidanceSteeringHUD.COLOR.ACTIVE or GuidanceSteeringHUD.COLOR.INACTIVE
            self.receiverIcon:setColor(unpack(color))
        end

        self:drawLaneText()
        self:drawDirectionAngleText(spec.guidanceNode)

        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end

function GuidanceSteeringHUD:drawLaneText()
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(unpack(GuidanceSteeringHUD.TEXT_COLOR.LANE))

    if self.laneTextPositionX ~= nil then
        renderText(self.laneTextPositionX, self.laneTextPositionY, self.laneTextSize, self.laneText)
    end
end

function GuidanceSteeringHUD:drawDirectionAngleText(node)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(unpack(GuidanceSteeringHUD.TEXT_COLOR.LANE))

    local dirX, _, dirZ = localDirectionToWorld(node, 0, 0, 1)
    local angleRad = math.abs(MathUtil.getYRotationFromDirection(dirX, dirZ) - math.pi)
    if self.angleTextPositionX ~= nil then
        renderText(self.angleTextPositionX, self.angleTextPositionY, self.laneTextSize, tostring(MathUtil.round(math.deg(angleRad), 1)) .. "°")
    end
end

function GuidanceSteeringHUD.speedMeterDisplay_storeScaledValues(speedMeterDisplay)
    g_guidanceSteering.ui.hud:storeScaledValues()
end

function GuidanceSteeringHUD.speedMeterDisplay_draw(speedMeterDisplay)
    g_guidanceSteering.ui.hud:drawText()
end

GuidanceSteeringHUD.SIZE = {
    BOX = { 54, 162 },
    BOX_MARGIN = { 11, 44 },
    ICON = { 54, 54 },
    SEPARATOR = { 54, 1 },
}
GuidanceSteeringHUD.UV = {
    STEERING_WHEEL_ENABLED = { 650, 0, 65, 65 },
    STEERING_WHEEL_DISABLED = { 715, 0, 65, 65 },
    RECEIVER = { 650, 65, 65, 65 },
    LANE = { 715, 65, 65, 65 },
}

GuidanceSteeringHUD.POSITION = {
    WIDTH_TEXT = { 30, -62.5 },
    WIDTH_ICON = { 20, 25 },
    SEPARATOR = { 0, 0 },
    LANE_TEXT = { -8, -20 }
}

GuidanceSteeringHUD.TEXT_COLOR = {
    LANE = { 1, 1, 1, 1 }
}

GuidanceSteeringHUD.COLOR = {
    INACTIVE = { 1, 1, 1, 0.75 },
    ACTIVE = { 0.0953, 1, 0.0685, 0.75 }
}

GuidanceSteeringHUD.TEXT_SIZE = {
    LANE = 14
}
