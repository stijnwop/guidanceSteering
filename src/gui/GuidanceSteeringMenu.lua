GuidanceSteeringMenu = {}
local GuidanceSteeringMenu_mt = Class(GuidanceSteeringMenu, TabbedMenu)

GuidanceSteeringMenu.CONTROLS = {
    PAGE_SETTINGS = "pageSettings",
    PAGE_STRATEGY = "pageStrategy",
}

local NO_CALLBACK = function() end

function GuidanceSteeringMenu:new(messageCenter, i18n, inputManager)
    local self = TabbedMenu:new(nil, GuidanceSteeringMenu_mt, messageCenter, i18n, inputManager)

    self.i18n = i18n

    self.performBackgroundBlur = true

    self:registerControls(GuidanceSteeringMenu.CONTROLS)

    return self
end

function GuidanceSteeringMenu:onGuiSetupFinished()
    GuidanceSteeringMenu:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack) -- store to be able to apply it always when assigning menu button info

    self.pageSettings:initialize()
    self.pageStrategy:initialize()

    self:setupPages()
end

function GuidanceSteeringMenu:setupPages()
    local predicate = self:makeIsAlwaysVisiblePredicate()

    local orderedPages = {
        -- default pages, their enabling state predicate functions and tab icon UVs in order
        { self.pageSettings, predicate, GuidanceSteeringMenu.TAB_UV.SETTINGS },
        { self.pageStrategy, predicate, GuidanceSteeringMenu.TAB_UV.STRATEGY },
    }

    for i, pageDef in ipairs(orderedPages) do
        local page, predicate, iconUVs = unpack(pageDef)
        self:registerPage(page, i, predicate)

        local normalizedUVs = getNormalizedUVs(iconUVs)
        self:addPageTab(page, g_baseUIFilename, normalizedUVs) -- use the global here because the value changes with resolution settings
    end
end

------------------------------------------------------------------------------------------------------------------------
-- Setting up
------------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------------
-- Predicates for showing pages
------------------------------------------------------------------------------------------------------------------------
function GuidanceSteeringMenu:makeIsAlwaysVisiblePredicate()
    return function()
        return true
    end
end

--- Page tab UV coordinates for display elements.
GuidanceSteeringMenu.TAB_UV = {
    SETTINGS = { 0, 209, 65, 65 },
    STRATEGY = { 65, 209, 65, 65 },
}

GuidanceSteeringMenu.L10N_SYMBOL = {
    BUTTON_BACK = "button_back",
}
