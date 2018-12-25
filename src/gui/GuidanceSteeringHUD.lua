GuidanceSteeringHUD = {}

local GuidanceSteeringHUD_mt = Class(GuidanceSteeringHUD)


function GuidanceSteeringHUD:new(mission, gameInfoDisplay, i18n)
    local instance = setmetatable({}, GuidanceSteeringHUD_mt)

    instance.gameInfoDisplay = gameInfoDisplay
    instance.i18n = i18n
    instance.box = nil
    instance.icon = nil
    instance.boxAutoWidth = nil

    --    SpeedMeterDisplay.draw = Utils.appendedFunction(SpeedMeterDisplay.draw, GuidanceSteeringHUD.speedMeterDisplay_draw)

    return instance
end

function GuidanceSteeringHUD:delete()
    if self.box ~= nil then
        self.box:delete()
    end
end

function GuidanceSteeringHUD:load()
    self.hudAtlasPath = Utils.getFilename("resources/icons.png", g_guidanceSteering.modDirectory)

    Logger.info(self.hudAtlasPath)
    local topRightX, topRightY = SpeedMeterDisplay.getBackgroundPosition(1)
    local bottomY = topRightY - self.gameInfoDisplay:getHeight()
    local centerY = bottomY + self.gameInfoDisplay:getHeight() * 0.5
    local marginWidth, marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({ 5, 5 })

    local sepX = self.gameInfoDisplay.overlay.x
    local bottomX = topRightX + self.gameInfoDisplay:getWidth()
    local x = bottomX - self.gameInfoDisplay:getWidth() * .25

    local rightX = self:createBox(self.hudAtlasPath, x, topRightY)

    --    self.gameInfoDisplay:updateSizeAndPositions()

    self:toggle(false)
end

function GuidanceSteeringHUD:createBox(hudAtlasPath, rightX, topRightY)
    local boxWidth, boxHeight = self.gameInfoDisplay:scalePixelToScreenVector({ 350, 350 })
    local posX = rightX - boxWidth

    local boxOverlay = Overlay:new(g_baseUIFilename, posX, topRightY, boxWidth, boxHeight)

    boxOverlay:setColor(0.0075, 0.0075, 0.0075, 1)
    boxOverlay:setUVs(g_colorBgUVs)

    local boxElement = HUDElement:new(boxOverlay)
    boxElement:setAlpha(0.75)

    self.box = boxElement

    local boxAutoWidth = self:createAutoWidthBox(hudAtlasPath, posX, topRightY, boxHeight, boxWidth)
    boxElement:addChild(boxAutoWidth)
    self.boxAutoWidth = boxAutoWidth

    self.gameInfoDisplay:addChild(self.box)

    return rightX - boxWidth
end

function GuidanceSteeringHUD:createAutoWidthBox(hudAtlasPath, rightX, topRightY, boxHeight, boxWidth)
    local width = boxWidth * .5
    local height = boxHeight * .25
    local posX = rightX + (boxWidth - width)
    local posY = topRightY + (boxHeight - height)

    local overlay = Overlay:new(nil, posX, posY, width, height) -- position is set on update
    --    overlay:setColor(0, 0, 0, 1)
    --    overlay:setUVs(g_colorBgUVs)

    local element = HUDElement:new(overlay)
    element:setVisible(true)

    local iconOffX, iconOffY = self.gameInfoDisplay:scalePixelToScreenVector(GuidanceSteeringHUD.POSITION.WIDTH_ICON)
    local icon = self:createSeasonIcon(hudAtlasPath, posX + iconOffX, posY + iconOffY, height, GuidanceSteeringHUD.UV.WIDTH, GameInfoDisplay.COLOR.ICON)
    element:addChild(icon)
    self.icon = icon

    -- Set the render text scaled values
    local textOffX, textOffY = self.gameInfoDisplay:scalePixelToScreenVector(GuidanceSteeringHUD.POSITION.WIDTH_TEXT)
    local textElement = HUDTextDisplay:new(posX + textOffX, posY + height + textOffY, GuidanceSteeringHUD.TEXT_SIZE.WIDTH, RenderText.ALIGN_LEFT, GuidanceSteeringHUD.TEXT_COLOR.WIDTH, true)
    textElement:setText("8.25m")
    self.widthText = textElement
    element:addChild(textElement)
    return element
end

function GuidanceSteeringHUD:createSeasonIcon(hudAtlasPath, posX, posY, boxHeight, uvs, color)
    local width, height = self.gameInfoDisplay:scalePixelToScreenVector({ 54, 54 })
    --posY = posY + (boxHeight - height) * 0.5

    local overlay = Overlay:new(hudAtlasPath, posX, posY, width, height) -- position is set on update
    overlay:setUVs(getNormalizedUVs(uvs))

    local element = HUDElement:new(overlay)
    element:setVisible(true)

    return element
end

function GuidanceSteeringHUD:toggle(vis)
    self.box:setVisible(vis)
    --    self.icon:setVisible(vis)
end

function GuidanceSteeringHUD.speedMeterDisplay_draw(speedMeterDisplay)
    g_guidanceSteering.ui.hud:drawText()
end

function GuidanceSteeringHUD:setWidthText(width)
    --    self.widthText:setText(("%.2f m"):format(width))
end

function GuidanceSteeringHUD:drawText()
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_RIGHT)

    self:drawWidthText()
end

function GuidanceSteeringHUD:drawWidthText()
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(unpack(GuidanceSteeringHUD.TEXT_COLOR.WIDTH))

    renderText(self.widthTextPositionX, self.widthTextPositionY, self.widthTextSize, self.widthText)
end

GuidanceSteeringHUD.UV = {
    WIDTH = { 8, 8, 240, 240 },
}

GuidanceSteeringHUD.POSITION = {
    WIDTH_TEXT = { 30, -62.5 },
    WIDTH_ICON = { 20, 25 }
}

GuidanceSteeringHUD.TEXT_COLOR = {
    WIDTH = { 0, 0.379, 0.093, 1 }
}

GuidanceSteeringHUD.TEXT_SIZE = {
    WIDTH = 11
}