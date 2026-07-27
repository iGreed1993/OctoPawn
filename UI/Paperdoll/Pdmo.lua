-------------------------------------------------
-- OctoPawn UI/Paperdoll/Pdmo.lua
-------------------------------------------------
local function ResolveTooltipUnit()
    if UnitExists("mouseover") and UnitIsPlayer("mouseover") then
        return "mouseover"
    end
    local tipName = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
    if not tipName then return nil end
    local function nameMatch(unit)
        if not UnitExists(unit) then return false end
        local n = UnitName(unit)
        local p = UnitPVPName and UnitPVPName(unit)
        return (n and n == tipName) or (p and p == tipName)
    end
    if nameMatch("player") then return "player" end
    if nameMatch("target") then return "target" end
    local i
    for i = 1, 4 do
        if nameMatch("party" .. i) then return "party" .. i end
    end
    for i = 1, 40 do
        if nameMatch("raid" .. i) then return "raid" .. i end
    end
    return nil
end

local function AddUnitOPScoreFromShow()
    if GameTooltip.octoPawnUnitScored then return end
    local unit = ResolveTooltipUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local total = 0
    if UnitIsUnit(unit, "player") then
        total = OctoPawn_ScorePlayer and OctoPawn_ScorePlayer() or 0
    else
        local _, class = UnitClass(unit)
        local role = OctoPawn_GetInspectRole and OctoPawn_GetInspectRole(class)
        local weights = OctoPawn_GetWeightsForClassRole and OctoPawn_GetWeightsForClassRole(class, role) or {}
        total = OctoPawn_ScoreUnitQuiet and OctoPawn_ScoreUnitQuiet(unit, weights) or 0
    end

    GameTooltip.octoPawnUnitScored = true
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(OctoPawn_FormatScore and OctoPawn_FormatScore(total) or ("OP Score: " .. total))
    GameTooltip:Show()
end

do
    local oldTipHide = GameTooltip:GetScript("OnHide")
    GameTooltip:SetScript("OnHide", function()
        this.octoPawnUnitScored = nil
        if oldTipHide then oldTipHide() end
    end)
end

local opTipWatcher = CreateFrame("Frame", nil, GameTooltip)
opTipWatcher:SetScript("OnShow", function()
    pcall(AddUnitOPScoreFromShow)
end)

print("|cFF00FF00OctoPawn|r paperdoll mouseover loaded")
