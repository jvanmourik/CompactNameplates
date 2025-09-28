local ADDON_NAME, addon = ...
local FRAME_LEVEL_SPACING = 3 -- allows children to occupy intermediate frame levels without risk of overlapping incorrectly

local frame = CreateFrame("Frame")
local texture = frame:CreateTexture()

-- Extend Blizzard object methods
local function SetShown(self, show)
    if show then
        self:Show()
    else
        self:Hide()
    end
end

getmetatable(frame).__index.SetShown = SetShown
getmetatable(texture).__index.SetShown = SetShown

local function IsNameplate(frame)
    local healthBorder = select(2, frame:GetRegions())
    return healthBorder and healthBorder:GetObjectType() == "Texture" and
           healthBorder:GetTexture() == [[Interface\Tooltips\Nameplate-Border]]
end

local function OnLoad()
    addon.Config:ApplyDefaults()
end

local nameplates = {}
local numChildren = 0

local function OnUpdate(elapsed)
    -- Hijack default nameplates
    local currentNumChildren = WorldFrame:GetNumChildren()
    for i = numChildren + 1, currentNumChildren do
        local child = select(i, WorldFrame:GetChildren())
        if IsNameplate(child) then
            -- Save references for easier access
            child.healthBar, child.castBar = child:GetChildren()
            child.threatGlow, child.healthBarBorder, child.castBarBorder,
            child.castBarShieldBorder, child.spellIcon, child.highlight,
            child.unitName, child.unitLevel, child.skullIcon, child.raidIcon, 
            child.eliteIcon = child:GetRegions()

            -- Hide or neutralize textures and text
            child.healthBar:Hide()
            child.castBar:SetStatusBarTexture(nil)
            child.threatGlow:SetTexCoord(0, 0, 0, 0)
            child.healthBarBorder:SetTexture(nil)
            child.castBarBorder:SetTexture(nil)
            child.castBarShieldBorder:SetTexture(nil)
            child.spellIcon:SetWidth(0.1)
            child.highlight:SetTexture(nil)
            child.unitName:SetWidth(0.1)
            child.unitLevel:SetWidth(0.1)
            child.skullIcon:SetTexture(nil)
            child.raidIcon:SetTexture(nil)
            child.eliteIcon:SetTexture(nil)
            
            -- Attach custom nameplate to Blizzard's default nameplates
            table.insert(nameplates, addon.Nameplate:Create(child))
        end
    end
    numChildren = currentNumChildren

    -- Sort nameplates by depth
    table.sort(nameplates, function(a, b)
        return a:GetEffectiveDepth() > b:GetEffectiveDepth()
    end)

    for i, nameplate in ipairs(nameplates) do
         -- Ensure target is on top
        local frameLevel = (addon.Nameplate:IsTarget(nameplate)
        and 1000 or 10) * i * FRAME_LEVEL_SPACING

        nameplate:SetFrameLevel(frameLevel)
        nameplate:SetScale(UIParent:GetScale())
    end
end

local eventHandlers = {}

local function OnEvent(event, ...)
    if eventHandlers[event] then
        eventHandlers[event](addon, ...)
    end
end

local function RegisterEvent(event, handler)
    eventHandlers[event] = handler
    frame:RegisterEvent(event)
end

local function UnregisterEvent(event)
    eventHandlers[event] = nil
    frame:UnregisterEvent(event)
end

frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", OnUpdate)

RegisterEvent("ADDON_LOADED", function(name)
    if name == ADDON_NAME then
        OnLoad()
        UnregisterEvent("ADDON_LOADED")
    end
end)

RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...)
    local subevent = select(2, ...)
    if subevent == "SPELL_AURA_APPLIED" then
        addon.Auras:OnApply(...)
    elseif subevent == "SPELL_AURA_REMOVED" then
        addon.Auras:OnRemove(...)
    end
end)