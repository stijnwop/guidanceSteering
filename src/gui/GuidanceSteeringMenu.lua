---
-- GuidanceSteeringMenu
--
-- The main menu for GuidanceSteering.
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringMenu
GuidanceSteeringMenu = {}

local GuidanceSteeringMenu_mt = Class(GuidanceSteeringMenu, TabbedMenu)

GuidanceSteeringMenu.CONTROLS = {
    PAGE_SETTINGS = "pageSettings",
    PAGE_STRATEGY = "pageStrategy",
    DIALOG_BACKGROUND = "dialogBackground",
}

---Creates a new instance of the GuidanceSteeringMenu.
---@return GuidanceSteeringMenu
function GuidanceSteeringMenu:new(messageCenter, i18n, inputManager)
    local self = TabbedMenu:new(nil, GuidanceSteeringMenu_mt, messageCenter, i18n, inputManager)

    self.i18n = i18n

    self:registerControls(GuidanceSteeringMenu.CONTROLS)

    return self
end

function GuidanceSteeringMenu:onGuiSetupFinished()
    GuidanceSteeringMenu:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack) -- store to be able to apply it always when assigning menu button info

    if g_screenWidth >= 2560 and g_screenHeight >= 1080 then
        self.dialogBackground:applyProfile("guidanceSteeringDialogBgWide")
        self.header:applyProfile("guidanceSteeringMenuHeaderWide")
        self.pageSelector:applyProfile("guidanceSteeringHeaderSelectorWide")
        self.pagingTabList:applyProfile("guidanceSteeringPagingTabListWide")
    end

    self.pageSettings:initialize()
    self.pageStrategy:initialize()

    self:setupPages()
end

function GuidanceSteeringMenu:setupPages()
    local alwaysVisiblePredicate = self:makeIsAlwaysVisiblePredicate()

    local orderedPages = {
        { self.pageSettings, alwaysVisiblePredicate, g_baseUIFilename, GuidanceSteeringMenu.TAB_UV.SETTINGS },
        { self.pageStrategy, alwaysVisiblePredicate, g_guidanceSteering.ui.uiFilename, GuidanceSteeringMenu.TAB_UV.STRATEGY },
    }

    for i, pageDef in ipairs(orderedPages) do
        local page, predicate, uiFilename, iconUVs = unpack(pageDef)
        self:registerPage(page, i, predicate)

        local normalizedUVs = getNormalizedUVs(iconUVs)
        self:addPageTab(page, uiFilename, normalizedUVs) -- use the global here because the value changes with resolution settings
    end
end

function GuidanceSteeringMenu:onOpen()
    GuidanceSteeringMenu:superClass().onOpen(self)

    self.inputDisableTime = 200
end

--- Define default properties and retrieval collections for menu buttons.
function GuidanceSteeringMenu:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback

    self.defaultMenuButtonInfo = {
        { inputAction = InputAction.MENU_BACK, text = self.l10n:getText(GuidanceSteeringMenu.L10N_SYMBOL.BUTTON_BACK), callback = onButtonBackFunction },
    }

    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]

    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
    }
end

function GuidanceSteeringMenu:makeIsAlwaysVisiblePredicate()
    return function()
        return true
    end
end

--- Page tab UV coordinates for display elements.
GuidanceSteeringMenu.TAB_UV = {
    SETTINGS = { 0, 209, 65, 65 },
    STRATEGY = { 845, 0, 65, 65 },
}

GuidanceSteeringMenu.L10N_SYMBOL = {
    BUTTON_BACK = "button_back",
}
