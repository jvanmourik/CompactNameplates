local ADDON_NAME, addon = ...

local Units = {}
addon.Units = Units

local unitGUIDs = {}

function Units:GetGUID(name, health)
    return unitGUIDs[name .. health]
end

function Units:SetGUID(guid, name, health)
    unitGUIDs[name .. health] = guid
end