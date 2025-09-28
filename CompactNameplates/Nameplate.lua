local ADDON_NAME, addon = ...

local MAX_AURA_FRAMES = 5
local LARGE_AURA_SIZE = 21
local SMALL_AURA_SIZE = 17
local AURA_SPACING = 3

local Nameplate = {}
addon.Nameplate = Nameplate

local function IsMouseover(nameplate)
    local default = nameplate:GetParent()
    return UnitExists("mouseover") and default.highlight:IsShown()
end

local function GetUnitID(nameplate)
    return (Nameplate:IsTarget(nameplate) and "target") or (IsMouseover(nameplate) and "mouseover") or nil
end

local function UnitNameAbbrev(unitName, maxLength)
    if #unitName <= maxLength then
        return unitName
    end

    local firstWord, rest = strsplit(" ", unitName, 2)
    local abbrev = ""

    while rest do
        abbrev = abbrev .. firstWord:sub(1, 1) .. "."
        unitName = abbrev .. " " .. rest
        if #unitName <= maxLength then
            return unitName
        end
        firstWord, rest = strsplit(" ", rest, 2)
    end

    return unitName:sub(1, maxLength)
end

local function GetUnitName(nameplate)
    local default = nameplate:GetParent()
    return UnitNameAbbrev(default.unitName:GetText(), 22)
end

local function GetUnitLevel(nameplate)
    local default = nameplate:GetParent()
    return default.skullIcon:IsShown() and "??" or default.unitLevel:GetText()
end

local function GetUnitHealth(nameplate)
    local default = nameplate:GetParent()
    local _, unitHealth = default.healthBar:GetMinMaxValues()
    return unitHealth
end

local nameplatesByGUID = {}

local function SetGUID(nameplate, unitGUID)
    if not unitGUID then
        return
    end
    nameplatesByGUID[unitGUID] = nameplate
    nameplate.unitGUID = unitGUID
end

local function ClearGUID(nameplate)
    if not nameplate.unitGUID then
        return
    end
    nameplatesByGUID[nameplate.unitGUID] = nil
    nameplate.unitGUID = nil
end

local function OnShow(nameplate)
    local default = nameplate:GetParent()
    local unitName = GetUnitName(nameplate)
    local unitHealth = GetUnitHealth(nameplate)
    local unitLevel = GetUnitLevel(nameplate)

    nameplate.healthBar:SetMinMaxValues(0, unitHealth)
    nameplate.healthBar:SetValue(default.healthBar:GetValue())
    nameplate.healthBar:SetStatusBarColor(default.healthBar:GetStatusBarColor())
    nameplate.healthBar.unitName:SetText(unitName)
    nameplate.healthBar.unitLevel:SetText(unitLevel)

    -- Assign a best-guess GUID to this nameplate (based on name+health).
    -- This may be overwritten later when the unit is actually targeted.
    local unitGUID = addon.Units:GetGUID(unitName, unitHealth)

    -- Only assign if there is not already a nameplate out there with this GUID
    if not Nameplate:Get(unitGUID) then
        SetGUID(nameplate, unitGUID)
    end

    -- Update auras based on this new GUID
    Nameplate:UpdateAuras(nameplate)
end

local function OnHide(nameplate)
    -- Clear GUID so recycled frames don't carry stale data
    ClearGUID(nameplate)

    -- Hide all aura frames
    Nameplate:UpdateAuras(nameplate)
end

local function OnUpdate(nameplate, elapsed)
    local default = nameplate:GetParent()
    nameplate.raidIcon:SetTexCoord(default.raidIcon:GetTexCoord())
    nameplate.raidIcon:SetShown(default.raidIcon:IsShown())

    local unitID = GetUnitID(nameplate)
    local unitGUID = unitID and UnitGUID(unitID)

    -- DEBUG: Populate auraInfo during runtime
    if unitID then
        addon.Auras:Refresh(unitID)
        Nameplate:UpdateAuras(nameplate)
    end

    -- Update GUID if a new one is found
    if unitGUID and unitGUID ~= nameplate.unitGUID then
        local conflict = Nameplate:Get(unitGUID)
        if conflict then
            -- Another nameplate already has this GUID assigned.
            -- This can occur due to our best-guess GUID assignment.
            -- Clear the old reference so the GUID can be correctly reassigned.
            ClearGUID(conflict)
        end

        SetGUID(nameplate, unitGUID)

        -- Store lookup info for reassignments later
        local unitName = GetUnitName(nameplate)
        local unitHealth = GetUnitHealth(nameplate)
        addon.Units:SetGUID(unitGUID, unitName, unitHealth)

        -- Refresh auras in case they changed before the nameplate was linked to the unit
        -- addon.Auras:Refresh(unitID)
        Nameplate:UpdateAuras(nameplate)
    end
end

local function HealthBar_OnValueChanged(nameplate, value)
    nameplate.healthBar:SetValue(value)
end

local function CastBar_OnShow(nameplate)
    local default = nameplate:GetParent()
    nameplate.castBar:SetMinMaxValues(default.castBar:GetMinMaxValues())
    nameplate.castBar:SetValue(default.castBar:GetValue())
    nameplate.castBar:Show()
end

local function CastBar_OnHide(nameplate)
    nameplate.castBar:Hide()
end

local function CastBar_OnValueChanged(nameplate, value)
    local default = nameplate:GetParent()
    nameplate.castBar:SetValue(value)
    nameplate.castBar.spellName:SetText(UnitCastingInfo("target"))
    nameplate.castBar.targetName:SetText(UnitName("targettarget"))
    nameplate.castBar.spellIcon:SetTexture(default.spellIcon:GetTexture())
end

local function AuraFrame_OnUpdate(self, elapsed)
    local duration = self.duration;
    if self.timeLeft then
        duration:SetFormattedText(SecondsToTimeAbbrev(self.timeLeft))
        if self.timeLeft < BUFF_DURATION_WARNING_TIME then
            duration:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        else
            duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        end
        self.timeLeft = max(self.timeLeft - elapsed, 0)
        duration:Show()
    else
        duration:Hide()
    end
end

local function AuraFrame_SetTimer(self, expirationTime)
    if not self.timeLeft then
        self:SetScript("OnUpdate", AuraFrame_OnUpdate)
    end
    self.timeLeft = expirationTime - GetTime()
end

function Nameplate:UpdateAuras(nameplate)
    local unitID = GetUnitID(nameplate)
    if unitID then
        addon.Auras:Refresh(unitID)
    end

    local offset = 0

    local time = GetTime()
    local frames = {nameplate.auras:GetChildren()}

    for i, frame in ipairs(frames) do
        local spellID, duration, expirationTime = addon.Auras:Get(nameplate.unitGUID, i)
        if spellID then
            local _, _, spellIcon = GetSpellInfo(spellID)

            frame.icon:SetTexture(spellIcon)
            -- frame.count:SetText(count)
            -- frame.count:SetShown(count > 1)

            AuraFrame_SetTimer(frame, expirationTime)

            -- Add space after the previous aura
            if i > 1 then
                offset = offset + AURA_SPACING
            end

            frame:ClearAllPoints()
            frame:SetPoint("LEFT", nameplate.auras, "LEFT", offset, 0)
            frame:Show()

            -- Move past this aura's width
            offset = offset + frame:GetWidth()
        else
            frame:Hide()
        end
    end

    -- Resize container
    nameplate.auras:SetWidth(offset)
end

function Nameplate:IsTarget(nameplate)
    local default = nameplate:GetParent()
    return UnitExists("target") and default:GetAlpha() == 1
end

function Nameplate:Get(unitGUID)
    return nameplatesByGUID[unitGUID]
end

function Nameplate:Create(default)
    local nameplate = CreateFrame("Frame", nil, default, "NameplateFrameTemplate")

    -- -- Create aura frames
    for i = 1, MAX_AURA_FRAMES do
        CreateFrame("Frame", nil, nameplate.auras, "NameplateAuraFrameTemplate")
    end

    -- Hook default nameplate scripts
    default:HookScript("OnShow", function(self)
        OnShow(nameplate)
    end)
    default:HookScript("OnHide", function(self)
        OnHide(nameplate)
    end)
    default:HookScript("OnUpdate", function(self)
        OnUpdate(nameplate)
    end)
    default.healthBar:HookScript("OnValueChanged", function(self, value)
        HealthBar_OnValueChanged(nameplate, value)
    end)
    default.castBar:HookScript("OnShow", function()
        CastBar_OnShow(nameplate)
    end)
    default.castBar:HookScript("OnHide", function()
        CastBar_OnHide(nameplate)
    end)
    default.castBar:HookScript("OnValueChanged", function(self, value)
        CastBar_OnValueChanged(nameplate, value)
    end)

    OnShow(nameplate)

    return nameplate
end