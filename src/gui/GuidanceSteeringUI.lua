GuidanceSteeringUI = {}

local GuidanceSteeringUI_mt = Class(GuidanceSteeringUI)

function GuidanceSteeringUI:new(mission, i18n, modDirectory, gui, inputManager, messageCenter, settingsModel)
    local self = setmetatable({}, GuidanceSteeringUI_mt)

    self.mission = mission
    self.i18n = i18n
    self.modDirectory = modDirectory
    self.gui = gui
    self.inputManager = inputManager
    self.messageCenter = messageCenter
    self.settingsModel = settingsModel
    self.isClient = mission:getIsClient()
    --instance.hud = GuidanceSteeringHUD:new(mission, mission.hud.speedMeter, i18n)
    self.vehicle = nil

    return self
end

function GuidanceSteeringUI:delete()
    if self.isClient then
        --self.hud:delete()

        self:unloadMenu()
    end
end

function GuidanceSteeringUI:load()
    if self.isClient then
        self.gui:loadProfiles(Utils.getFilename("resources/gui/guiProfiles.xml", self.modDirectory))

        --self.hud:load()

        self:loadMenu()
    end
end

function GuidanceSteeringUI:loadMenu()
    local settingsFrame = GuidanceSteeringSettingsFrame:new(self.i18n, self.settingsModel)
    local strategyFrame = GuidanceSteeringStrategyFrame:new(self.i18n)
    --
    self.menu = GuidanceSteeringMenu:new(self.messageCenter, self.i18n, self.inputManager)

    local root = Utils.getFilename("resources/gui/", self.modDirectory)
    self.gui:loadGui(root .. "GuidanceSteeringSettingsFrame.xml", "GuidanceSteeringSettingsFrame", settingsFrame, true)
    self.gui:loadGui(root .. "GuidanceSteeringStrategyFrame.xml", "GuidanceSteeringStrategyFrame", strategyFrame, true)
    self.gui:loadGui(root .. "GuidanceSteeringMenu.xml", "GuidanceSteeringMenu", self.menu)
end

function GuidanceSteeringUI:unloadMenu()
    --self.gui:unloadGui("GuidanceSteeringSettingsFrame")
    --self.gui:unloadGui("GuidanceSteeringStrategyFrame")
    --self.gui:unloadGui("GuidanceSteeringMenu")

    self.menu:delete()
end

function GuidanceSteeringUI:onToggleUI()
    if not self.mission.isSynchronizingWithPlayers then
        g_gui:showGui("GuidanceSteeringMenu")
        --g_gui:changeScreen(nil, GuidanceSteeringMenu)
    end
end

function GuidanceSteeringUI:dataChanged(data)
    --self.hud:setWidthText(data.width)
end

function GuidanceSteeringUI:setVehicle(vehicle)
    self.vehicle = vehicle
    --self.hud:toggle(vehicle ~= nil)
end

function GuidanceSteeringUI:getVehicle()
    return self.vehicle
end

function GuidanceSteeringUI:draw()
    if self.vehicle ~= nil then
        --        self.hud:draw()
    end
end