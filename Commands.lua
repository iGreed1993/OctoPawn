-------------------------------------------------
-- OctoPawn Commands.lua
-------------------------------------------------
SLASH_OCTOPAWN1 = "/op"
SlashCmdList["OCTOPAWN"] = function(msg)
    msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"))
    if msg == "help" or msg == "?" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op|r - Score the hovered item only")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op compare|r - Toggle equip compare")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op spec|r - Role / spec picker")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op reset|r - Reset weights to role defaults")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op help|r - This help")
        return
    end
    if msg == "compare" then
        if not OctoPawnDB then OctoPawnDB = {} end
        if OctoPawnDB.compareEnabled == false then
            OctoPawnDB.compareEnabled = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Compare enabled.|r")
        else
            OctoPawnDB.compareEnabled = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Compare disabled.|r")
        end
        if OctoPawn_RefreshCompareButton then OctoPawn_RefreshCompareButton() end
        return
    end
    if msg == "spec" then
        if OctoPawn_ShowRolePicker then OctoPawn_ShowRolePicker() end
        return
    end
    if msg == "reset" then
        local role = OctoPawnDB and OctoPawnDB.role
        if role and OctoPawn_ApplyRole then
            OctoPawn_ApplyRole(role, false)
        else
            local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
            if not OctoPawnDB then OctoPawnDB = {} end
            OctoPawnDB.weights = {}
            for stat, value in pairs(defaults) do OctoPawnDB.weights[stat] = value end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Weights reset to defaults.|r")
        end
        return
    end
    if not GameTooltip or not GameTooltip:IsShown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Hover an item first.|r")
        return
    end
    local score, results = OctoPawn_ScoreTooltip(GameTooltip)
    local name = OctoPawn_TooltipItemName and OctoPawn_TooltipItemName(GameTooltip) or "Item"
    OctoPawn_PrintBreakdown(name, score, results)
end
print("|cFF00FF00OctoPawn|r commands loaded")
