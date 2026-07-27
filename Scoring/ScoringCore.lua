-------------------------------------------------
-- OctoPawn Scoring/ScoringCore.lua
-------------------------------------------------

-- Built-in soft caps (shown in Advanced; overridden by OctoPawnDB.dr)
local DEFAULT_DR = {
    HIT                 = { softCap = 6,  postScale = 0.35 },
    ["SPELL HIT"]       = { softCap = 10, postScale = 0.30 },
    CRIT                = { softCap = 25, postScale = 0.40 },
    ["SPELL CRIT"]      = { softCap = 25, postScale = 0.40 },
    ["RANGED CRIT"]     = { softCap = 25, postScale = 0.40 },
    ["HOLY CRIT"]       = { softCap = 25, postScale = 0.40 },
    DEFENSE             = { softCap = 25, postScale = 0.35 },
    DODGE               = { softCap = 25, postScale = 0.40 },
    PARRY               = { softCap = 20, postScale = 0.40 },
    BLOCK               = { softCap = 25, postScale = 0.40 },
    HASTE               = { softCap = 20, postScale = 0.45 },
    ["RANGED HASTE"]    = { softCap = 20, postScale = 0.45 },
    ["SPELL PENETRATION"] = { softCap = 20, postScale = 0.40 },
    ["ARMOR PENETRATION"] = { softCap = 30, postScale = 0.45 },
}

-- Expose for Advanced UI
function OctoPawn_GetDefaultDR()
    return DEFAULT_DR
end

function OctoPawn_GetDR(stat)
    if OctoPawnDB and OctoPawnDB.dr and OctoPawnDB.dr[stat] then
        local d = OctoPawnDB.dr[stat]
        -- softCap 0 means player explicitly disabled DR for this stat
        if d.softCap ~= nil and tonumber(d.softCap) == 0 then
            return nil
        end
        return d
    end
    return DEFAULT_DR[stat]
end

local function EffectiveValue(stat, value)
    if not value then return 0 end
    local dr = OctoPawn_GetDR(stat)
    if not dr or not dr.softCap then
        return value
    end
    local soft = tonumber(dr.softCap) or 0
    if soft <= 0 then return value end
    local post = tonumber(dr.postScale)
    if not post then post = 0.5 end
    if value <= soft then
        return value
    end
    return soft + (value - soft) * post
end

function OctoPawn_ScoreTooltip(tooltip, overrideWeights)
    local weights = overrideWeights
    if not weights then
        weights = (OctoPawnDB and OctoPawnDB.weights) or (OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights()) or {}
    end
    local patterns = OctoPawn_StatPatterns or {}
    local totals = {}
    local pastDPS = false
    local numLines = tooltip:NumLines()
    local i
    for i = 1, numLines do
        local lineObj = getglobal(tooltip:GetName() .. "TextLeft" .. i)
        if lineObj then
            local line = lineObj:GetText()
            if line then
                local upper = string.upper(line)
                local isChanceOnHit = string.find(upper, "CHANCE ON HIT") ~= nil
                if not (OctoPawn_IsSetBonusLine and OctoPawn_IsSetBonusLine(upper)) then
                    if string.find(upper, "DAMAGE PER SECOND") or string.find(upper, "DPS") then pastDPS = true end
                    if pastDPS or not string.find(upper, "DAMAGE") or string.find(upper, "PER SECOND") or string.find(upper, "SPELLS") then
                        if not string.find(upper, "REQUIRES") and not string.find(upper, "SOULBOUND") and
                           not string.find(upper, "UNIQUE") and not string.find(upper, "LEVEL") and
                           not string.find(upper, "BIND") and not string.find(upper, "MADE BY") then
                            local matchedThisLine = {}
                            local _, entry
                            for _, entry in ipairs(patterns) do
                                if string.find(upper, entry.pattern) and not matchedThisLine[entry.stat] then
                                    local skip = false
                                    if entry.stat == "HIT" and isChanceOnHit then skip = true
                                    elseif entry.stat == "HIT" and string.find(upper, "SPELL") then skip = true
                                    elseif isChanceOnHit and (entry.stat == "HIT" or entry.stat == "CRIT"
                                        or entry.stat == "STRENGTH" or entry.stat == "AGILITY"
                                        or entry.stat == "STAMINA" or entry.stat == "INTELLECT"
                                        or entry.stat == "SPIRIT" or entry.stat == "ARMOR") then
                                        skip = true
                                    elseif (entry.stat == "SPELL DAMAGE" or entry.stat == "SPELL POWER") then
                                        if matchedThisLine["NATURE DAMAGE"] or matchedThisLine["FIRE DAMAGE"]
                                            or matchedThisLine["FROST DAMAGE"] or matchedThisLine["SHADOW DAMAGE"]
                                            or matchedThisLine["ARCANE DAMAGE"] or matchedThisLine["HOLY DAMAGE"] then
                                            skip = true
                                        end
                                    end
                                    if not skip then
                                        local num = OctoPawn_ExtractNumberNearStat and OctoPawn_ExtractNumberNearStat(line, upper, entry.pattern)
                                        if not num then
                                            local _, _, captured = string.find(line, "([%+%-]?%d+%.?%d*)")
                                            if captured then num = tonumber(captured) end
                                        end
                                        if not num and entry.stat == "LIFESTEAL" then
                                            local _, _, captured = string.find(line, "([%+%-]?%d+)%s*%%")
                                            if captured then num = tonumber(captured) end
                                        end
                                        if num then
                                            matchedThisLine[entry.stat] = true
                                            totals[entry.stat] = (totals[entry.stat] or 0) + num
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local results = {}
    local totalScore = 0
    for stat, value in pairs(totals) do
        local weight = weights[stat] or 1.0
        local effective = EffectiveValue(stat, value)
        local contribution = effective * weight
        totalScore = totalScore + contribution
        table.insert(results, {
            stat = stat,
            value = value,
            effective = effective,
            weight = weight,
            score = contribution,
        })
    end
    return totalScore, results
end

local function GetScanTooltip()
    if not OctoPawnScanTooltip then
        OctoPawnScanTooltip = CreateFrame("GameTooltip", "OctoPawnScanTooltip", nil, "GameTooltipTemplate")
        OctoPawnScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return OctoPawnScanTooltip
end

function OctoPawn_GetScanTooltip()
    return GetScanTooltip()
end

function OctoPawn_ScoreUnitEquipped(unit, weights)
    if not unit or not UnitExists(unit) then return 0 end
    local tip = GetScanTooltip()
    local total = 0
    local slot
    for slot = 1, 19 do
        if GetInventoryItemLink(unit, slot) then
            tip:SetOwner(UIParent, "ANCHOR_NONE")
            tip:ClearLines()
            tip.octoPawnScored = nil
            tip:SetInventoryItem(unit, slot)
            tip:Show()
            local score = OctoPawn_ScoreTooltip(tip, weights)
            tip:Hide()
            if score then total = total + score end
        end
    end
    return total
end

function OctoPawn_TooltipItemName(tip)
    local fs = getglobal(tip:GetName() .. "TextLeft1")
    if fs then
        local t = fs:GetText()
        if t and t ~= "" then return t end
    end
    return "Unknown item"
end

function OctoPawn_PrintBreakdown(title, score, results)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00----- " .. title .. " -----|r")
    if not results or table.getn(results) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900No scored stats.|r")
        return
    end
    local _, r
    for _, r in ipairs(results) do
        if r.effective and r.effective ~= r.value then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFFFFFFFF%s|r: %.1f (eff %.1f) × %.2f = |cFF00FF00%.1f|r",
                r.stat, r.value, r.effective, r.weight, r.score
            ))
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFFFFFFFF%s|r: %.1f × %.2f = |cFF00FF00%.1f|r",
                r.stat, r.value, r.weight, r.score
            ))
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Total: " .. string.format("%.1f", score) .. "|r")
end

local function AddScoreToTooltip(tooltip)
    if not tooltip or tooltip.octoPawnScored then return end
    tooltip.octoPawnScored = true
    local score, results = OctoPawn_ScoreTooltip(tooltip)
    if not results or table.getn(results) == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("|cFF00FF00OP Score: " .. string.format("%.1f", score) .. "|r")
    if OctoPawn_ShowComparison then OctoPawn_ShowComparison(tooltip, score) end
    tooltip:Show()
end

local oldOnHide = GameTooltip:GetScript("OnHide")
GameTooltip:SetScript("OnHide", function()
    this.octoPawnScored = nil
    if oldOnHide then oldOnHide() end
end)

local function hook(method, after)
    local orig = GameTooltip[method]
    if not orig then return end
    GameTooltip[method] = function(self, a1, a2, a3, a4, a5)
        self.octoPawnScored = nil
        local result = orig(self, a1, a2, a3, a4, a5)
        if after then after(self, a1, a2) end
        AddScoreToTooltip(self)
        return result
    end
end

hook("SetBagItem", function(self, bag, slot)
    self.itemLink = GetContainerItemLink(bag, slot)
end)
hook("SetInventoryItem", function(self, unit, slot)
    self.itemLink = GetInventoryItemLink(unit, slot)
end)
if GameTooltip.SetHyperlink then
    hook("SetHyperlink", function(self, link) self.itemLink = link end)
end
if GameTooltip.SetAuctionItem then
    hook("SetAuctionItem", function(self, type, index)
        if GetAuctionItemLink then self.itemLink = GetAuctionItemLink(type, index) end
    end)
end
if GameTooltip.SetAuctionSellItem then hook("SetAuctionSellItem") end
if GameTooltip.SetLootRollItem then hook("SetLootRollItem") end
if GameTooltip.SetQuestItem then hook("SetQuestItem") end
if GameTooltip.SetQuestLogItem then hook("SetQuestLogItem") end

print("|cFF00FF00OctoPawn|r scoring core loaded")
