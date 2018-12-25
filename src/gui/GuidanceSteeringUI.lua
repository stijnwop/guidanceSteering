GuidanceSteeringUI = {}

local GuidanceSteeringUI_mt = Class(GuidanceSteeringUI)

function GuidanceSteeringUI:new(mission, i18n, modDirectory, inputManager)
    local instance = setmetatable({}, GuidanceSteeringUI_mt)

    instance.i18n = i18n
    instance.modDirectory = modDirectory
    instance.inputManager = inputManager
    instance.isClient = mission:getIsClient()
    instance.hud = GuidanceSteeringHUD:new(mission, mission.hud.speedMeter, i18n)
    instance.vehicle = nil

    return instance
end

function GuidanceSteeringUI:delete()
    if self.isClient then
        self.hud:delete()

        self:unregisterActionEvents()
    end
end

function GuidanceSteeringUI:load()
    if self.isClient then
        self.hud:load()
    end
end

function GuidanceSteeringUI:onMissionStart()
    if self.isClient then
        self:registerActionEvents()
    end
end

function GuidanceSteeringUI:registerActionEvents()
    local _, eventId = self.inputManager:registerActionEvent(InputAction.GS_SHOW_UI, self, self.onToggleUI, false, true, false, true)
    self.inputManager:setActionEventTextVisibility(eventId, true)

    self.openMenuEvent = eventId
end

function GuidanceSteeringUI:unregisterActionEvents()
    self.inputManager:removeActionEvent(self.openMenuEvent)
end

function GuidanceSteeringUI:onToggleUI()
end

function GuidanceSteeringUI:dataChanged(data)
    self.hud:setWidthText(data.width)
end

function GuidanceSteeringUI:setVehicle(vehicle)
    self.vehicle = vehicle

    self.hud:toggle(vehicle ~= nil)

end

function GuidanceSteeringUI:getVehicle()
    return self.vehicle
end

function GuidanceSteeringUI:draw()
    if self.vehicle ~= nil then
--        self.hud:draw()
    end
end