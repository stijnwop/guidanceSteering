---
-- GuidanceSteeringUI
--
-- The handler class for the GuidanceSteering UI.
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringUI
GuidanceSteeringUI = {}

local GuidanceSteeringUI_mt = Class(GuidanceSteeringUI)

---Creates a new instance of the GuidanceSteeringUI.
---@return GuidanceSteeringUI
function GuidanceSteeringUI:new(mission, i18n, modDirectory, gui, inputManager, messageCenter)
    local self = setmetatable({}, GuidanceSteeringUI_mt)

    self.mission = mission
    self.i18n = i18n
    self.modDirectory = modDirectory
    self.gui = gui
    self.inputManager = inputManager
    self.messageCenter = messageCenter
    self.isClient = mission:getIsClient()

    self.uiFilename = Utils.getFilename("resources/guidanceSteering_1080p.png", modDirectory)

    self.hud = GuidanceSteeringHUD:new(mission, mission.hud.speedMeter, i18n, self.uiFilename)

    self.vehicle = nil

    return self
end

function GuidanceSteeringUI:delete()
    if self.isClient then
        self.hud:delete()

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

---Loads the menus.
function GuidanceSteeringUI:loadMenu()
    local settingsFrame = GuidanceSteeringSettingsFrame.new(self, self.i18n)
    local strategyFrame = GuidanceSteeringStrategyFrame.new(self, self.i18n)

    self.menu = GuidanceSteeringMenu.new(self.messageCenter, self.i18n, self.inputManager)

    local root = Utils.getFilename("resources/gui/", self.modDirectory)
    self.gui:loadGui(root .. "GuidanceSteeringSettingsFrame.xml", "GuidanceSteeringSettingsFrame", settingsFrame, true)
    self.gui:loadGui(root .. "GuidanceSteeringStrategyFrame.xml", "GuidanceSteeringStrategyFrame", strategyFrame, true)
    self.gui:loadGui(root .. "GuidanceSteeringMenu.xml", "GuidanceSteeringMenu", self.menu)
end

---Unloads and removes the menus.
function GuidanceSteeringUI:unloadMenu()
    --self.menu:delete()
end

---Action event to toggle the menu.
function GuidanceSteeringUI:onToggleUI()
    if not self.mission.isSynchronizingWithPlayers then
        self.gui:showGui("GuidanceSteeringMenu")
    end
end

---Set the current vehicle on the UI.
function GuidanceSteeringUI:setVehicle(vehicle)
    self.vehicle = vehicle
    self.hud:setVehicle(vehicle)
end

---Get the current vehicle.
function GuidanceSteeringUI:getVehicle()
    return self.vehicle
end

function GuidanceSteeringUI:draw()
end
