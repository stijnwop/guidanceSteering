GuidanceSteeringUI = {}

local GuidanceSteeringUI_mt = Class(GuidanceSteeringUI)

function GuidanceSteeringUI:new(mission, i18n, modDirectory, gui, inputManager, messageCenter, settingsModel)
    local instance = setmetatable({}, GuidanceSteeringUI_mt)

    instance.mission = mission
    instance.i18n = i18n
    instance.modDirectory = modDirectory
    instance.gui = gui
    instance.inputManager = inputManager
    instance.messageCenter = messageCenter
    instance.settingsModel = settingsModel
    instance.isClient = mission:getIsClient()
    instance.hud = GuidanceSteeringHUD:new(mission, mission.hud.speedMeter, i18n)
    instance.vehicle = nil

    return instance
end

function GuidanceSteeringUI:delete()
    if self.isClient then
        self.hud:delete()

        self:unregisterActionEvents()
        self:unloadMenu()
    end
end

function GuidanceSteeringUI:load()
    if self.isClient then

        self.gui:loadProfiles(Utils.getFilename("resources/gui/guiProfiles.xml", self.modDirectory))

        self.hud:load()

        self:loadMenu()
    end
end

function GuidanceSteeringUI:onMissionStart()
--    if self.isClient then
        self:registerActionEvents()
--    end
end

function GuidanceSteeringUI:loadMenu()
    self.settingsFrame = GuidanceSteeringSettingsFrame:new(self.i18n, self.settingsModel)
    self.strategyFrame = GuidanceSteeringStrategyFrame:new(self.i18n)
--
    self.menu = GuidanceSteeringMenu:new(self.messageCenter, self.i18n, self.inputManager)

    local root = Utils.getFilename("resources/gui/", self.modDirectory)
    self.gui:loadGui(root .. "GuidanceSteeringSettingsFrame.xml", "GuidanceSteeringSettingsFrame", self.settingsFrame, true)
    self.gui:loadGui(root .. "GuidanceSteeringStrategyFrame.xml", "GuidanceSteeringStrategyFrame", self.strategyFrame, true)
    self.gui:loadGui(root .. "GuidanceSteeringMenu.xml", "GuidanceSteeringMenu", self.menu)
end

function GuidanceSteeringUI:unloadMenu()
    self.gui:unloadGui("GuidanceSteeringSettingsFrame")
    self.gui:unloadGui("GuidanceSteeringStrategyFrame")
    self.gui:unloadGui("GuidanceSteeringMenu")

    self.menu:delete()
end

function GuidanceSteeringUI:registerActionEvents()
--    local _, eventId = self.inputManager:registerActionEvent(InputAction.GS_SHOW_UI, self, self.onToggleUI, false, true, false, true)
--    self.inputManager:setActionEventTextVisibility(eventId, true)
--
--    self.openMenuEvent = eventId
end

function GuidanceSteeringUI:unregisterActionEvents()
--    self.inputManager:removeActionEvent(self.openMenuEvent)
end

function GuidanceSteeringUI:onToggleUI()
    if not self.mission.isSynchronizingWithPlayers then
        g_gui:changeScreen(nil, GuidanceSteeringMenu)
    end
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