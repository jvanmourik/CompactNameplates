local ADDON_NAME, addon = ...

local Settings = {}
addon.Settings = Settings

local CVAR_DEFAULTS = {
    nameplateZ = 1.0,
    nameplateIntersectOpacity = 0.1,
    nameplateIntersectUseCamera = 1,
    nameplateFadeIn = 0,
}

function Settings:ApplyDefaults()
    for cvar, value in pairs(CVAR_DEFAULTS) do
        SetCVar(cvar, value)
    end
end