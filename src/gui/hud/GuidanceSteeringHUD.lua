GuidanceSteeringHUD = {}

local GuidanceSteeringHUD_mt = Class(GuidanceSteeringHUD)


function GuidanceSteeringHUD:new(mission, gameInfoDisplay, i18n)
    local instance = setmetatable({}, GuidanceSteeringHUD_mt)

    instance.gameInfoDisplay = gameInfoDisplay
    instance.i18n = i18n

    --    SpeedMeterDisplay.draw = Utils.appendedFunction(SpeedMeterDisplay.draw, GuidanceSteeringHUD.speedMeterDisplay_draw)

    return instance
end

function GuidanceSteeringHUD:delete()
end

function GuidanceSteeringHUD:load()
end

function GuidanceSteeringHUD:createBox(hudAtlasPath, rightX, topRightY)
end


function GuidanceSteeringHUD:toggle(vis)
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
