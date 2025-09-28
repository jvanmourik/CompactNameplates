local ADDON_NAME, addon = ...

local Auras = {}
addon.Auras = Auras

-- [spellID] = {name, duration, type, dispelType}
local auraInfo = {
    -- Shaman
    [3600]	= {"Earthbind", 5, "DEBUFF", "Magic"},
    [8185]	= {"Fire Resistance", nil, "BUFF"},
    [10534]	= {"Fire Resistance", nil, "BUFF"},
    [10535]	= {"Fire Resistance", nil, "BUFF"},
    [24464]	= {"Fire Resistance", nil, "BUFF"},
    [8050]	= {"Flame Shock", 12, "DEBUFF", "Magic"},
    [8052]	= {"Flame Shock", 12, "DEBUFF", "Magic"},
    [8053]	= {"Flame Shock", 12, "DEBUFF", "Magic"},
    [10447]	= {"Flame Shock", 12, "DEBUFF", "Magic"},
    [10448]	= {"Flame Shock", 12, "DEBUFF", "Magic"},
    [29228]	= {"Flame Shock", 12, "DEBUFF", "Magic"},
    [16257]	= {"Flurry", 15, "BUFF"},
    [16277]	= {"Flurry", 15, "BUFF"},
    [16278]	= {"Flurry", 15, "BUFF"},
    [16279]	= {"Flurry", 15, "BUFF"},
    [16280]	= {"Flurry", 15, "BUFF"},
    [43339]	= {"Focused", 15, "BUFF", "Magic"},
    [8182]	= {"Frost Resistance", nil, "BUFF"},
    [10476]	= {"Frost Resistance", nil, "BUFF"},
    [10477]	= {"Frost Resistance", nil, "BUFF"},
    [8056]	= {"Frost Shock", 8, "DEBUFF", "Magic"},
    [8058]	= {"Frost Shock", 8, "DEBUFF", "Magic"},
    [10472]	= {"Frost Shock", 8, "DEBUFF", "Magic"},
    [10473]	= {"Frost Shock", 8, "DEBUFF", "Magic"},
    [8034]	= {"Frostbrand Attack", 8, "DEBUFF"},
    [8037]	= {"Frostbrand Attack", 8, "DEBUFF"},
    [10458]	= {"Frostbrand Attack", 8, "DEBUFF"},
    [16352]	= {"Frostbrand Attack", 8, "DEBUFF"},
    [16353]	= {"Frostbrand Attack", 8, "DEBUFF"},
    [8836]	= {"Grace of Air", nil, "BUFF"},
    [10626]	= {"Grace of Air", nil, "BUFF"},
    [25360]	= {"Grace of Air", nil, "BUFF"},
    [8178]  = {"Grounding Totem Effect", nil, "BUFF"},
    [5672]	= {"Healing Stream", nil, "BUFF"},
    [6371]	= {"Healing Stream", nil, "BUFF"},
    [6372]	= {"Healing Stream", nil, "BUFF"},
    [10460]	= {"Healing Stream", nil, "BUFF"},
    [10461]	= {"Healing Stream", nil, "BUFF"},
    [324]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [325]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [905]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [945]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [8134]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [10431]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [10432]	= {"Lightning Shield", 600, "BUFF", "Magic"},
    [5677]	= {"Mana Spring", nil, "BUFF"},
    [10491]	= {"Mana Spring", nil, "BUFF"},
    [10493]	= {"Mana Spring", nil, "BUFF"},
    [10494]	= {"Mana Spring", nil, "BUFF"},
    [16191]	= {"Mana Tide", nil, "BUFF"},
    [17355]	= {"Mana Tide", nil, "BUFF"},
    [17360]	= {"Mana Tide", nil, "BUFF"},
    [10596]	= {"Nature Resistance", nil, "BUFF"},
    [10598]	= {"Nature Resistance", nil, "BUFF"},
    [10599]	= {"Nature Resistance", nil, "BUFF"},
    [84647]	= {"Primal Wielding", 4.5, "BUFF"},
    [8072]	= {"Stoneskin", nil, "BUFF"},
    [8156]	= {"Stoneskin", nil, "BUFF"},
    [8157]	= {"Stoneskin", nil, "BUFF"},
    [10403]	= {"Stoneskin", nil, "BUFF"},
    [10404]	= {"Stoneskin", nil, "BUFF"},
    [10405]	= {"Stoneskin", nil, "BUFF"},
    [17364]	= {"Stormstrike", 12, "DEBUFF", "Magic"},
    [8076]	= {"Strength of Earth", nil, "BUFF"},
    [8162]	= {"Strength of Earth", nil, "BUFF"},
    [8163]	= {"Strength of Earth", nil, "BUFF"},
    [10441]	= {"Strength of Earth", nil, "BUFF"},
    [25362]	= {"Strength of Earth", nil, "BUFF"},
    [25909]	= {"Tranquil Air", nil, "BUFF"},
    [131]	= {"Water Breathing", 600, "BUFF", "Magic"},
    [546]	= {"Water Walking", 600, "BUFF", "Magic"},
}

local aurasByGUID = {}

function Auras:Get(unitGUID, slot)
    local auras = aurasByGUID[unitGUID]
    if auras then
        local aura = auras[slot]
        if aura then
            return unpack(aura)
        end
    end
end

function Auras:Add(unitGUID, spellID, duration, expirationTime)
    local auras = aurasByGUID[unitGUID]
    if not auras then
        auras = {}
        aurasByGUID[unitGUID] = auras
    end

    return table.insert(auras, {spellID, duration, expirationTime})
end

function Auras:Remove(unitGUID, spellID)
    local auras = aurasByGUID[unitGUID]
    if auras then
        for i, aura in ipairs(auras) do
            if aura[1] == spellID then
                table.remove(auras, i)
            end
        end 
    end
end

-- Fully refresh all auras for unit by querying the game directly
function Auras:Refresh(unitID)
    local unitGUID = UnitGUID(unitID)
    aurasByGUID[unitGUID] = nil

    local i = 1
    while true do
        local name, _, _, _, dispelType, duration, expirationTime, _, _, _, spellID = UnitAura(unitID, i, "HARMFUL")
        if not spellID then return end

        -- DEBUG: Populate auraInfo during runtime
        auraInfo[spellID] = {name, duration, "DEBUFF", dispelType}

        self:Add(unitGUID, spellID, duration, expirationTime)
        i = i + 1
    end
end

-- timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType
function Auras:OnApply(_, _, _, _, _, unitGUID, _, _, spellID)
    local auraInfo = auraInfo[spellID]
    if not auraInfo then return end

    local name, duration, type, dispelType = unpack(auraInfo)
    self:Add(unitGUID, spellID, duration, GetTime() + duration)

    local nameplate = addon.Nameplate:Get(unitGUID)
    if nameplate then
        addon.Nameplate:UpdateAuras(nameplate)
    end
end

function Auras:OnRemove(_, _, _, _, _, unitGUID, _, _, spellID)
    self:Remove(unitGUID, spellID)

    local nameplate = addon.Nameplate:Get(unitGUID)
    if nameplate then
        addon.Nameplate:UpdateAuras(nameplate)
    end
end