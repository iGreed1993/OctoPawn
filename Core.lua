-------------------------------------------------
-- OctoPawn Core.lua
-------------------------------------------------
OctoPawnDB = OctoPawnDB or nil

function OctoPawn_GetClass()
    local _, class = UnitClass("player")
    return class
end

function OctoPawn_GetDefaultWeights()
    local class = OctoPawn_GetClass()
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return {} end
    local role = OctoPawnDB and OctoPawnDB.role
    local base
    if role and classTable[role] then base = classTable[role]
    elseif classTable.Default then base = classTable.Default
    else
        for _, weights in pairs(classTable) do base = weights; break end
    end
    if not base then return {} end
    -- optional advanced overrides
    if OctoPawnDB and OctoPawnDB.defaultOverrides and role then
        local over = OctoPawnDB.defaultOverrides[class] and OctoPawnDB.defaultOverrides[class][role]
        if over and OctoPawn_Merge then
            return OctoPawn_Merge(base, over)
        end
    end
    return base
end

function OctoPawn_GetDefaultsForClass(class)
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return {} end
    if classTable.Default then return classTable.Default end
    for _, weights in pairs(classTable) do return weights end
    return {}
end

function OctoPawn_GetRolesForClass(class)
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return { "Default" } end
    local roles = {}
    for role in pairs(classTable) do table.insert(roles, role) end
    if table.getn(roles) == 0 then return { "Default" } end
    table.sort(roles)
    return roles
end

function OctoPawn_ApplyRole(role, isCustom)
    local class = OctoPawn_GetClass()
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: No defaults for " .. tostring(class) .. "|r")
        return
    end
    local source = classTable[role]
    if not source then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Unknown role " .. tostring(role) .. "|r")
        return
    end
    if not OctoPawnDB then OctoPawnDB = {} end
    if not OctoPawnDB.customWeights then OctoPawnDB.customWeights = {} end
    OctoPawnDB.role = role
    OctoPawnDB.weights = {}
    if isCustom and OctoPawnDB.customWeights[role] then
        OctoPawnDB.useCustom = true
        for stat, value in pairs(OctoPawnDB.customWeights[role]) do
            OctoPawnDB.weights[stat] = value
        end
    else
        OctoPawnDB.useCustom = nil
        local weights = source
        if OctoPawnDB.defaultOverrides and OctoPawnDB.defaultOverrides[class] and OctoPawnDB.defaultOverrides[class][role] then
            if OctoPawn_Merge then
                weights = OctoPawn_Merge(source, OctoPawnDB.defaultOverrides[class][role])
            end
        end
        for stat, value in pairs(weights) do
            OctoPawnDB.weights[stat] = value
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Using " .. role .. (isCustom and " (custom)" or "") .. " weights.|r")
    if OctoPawn_UpdatePlayerPaperScore then OctoPawn_UpdatePlayerPaperScore() end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if arg1 ~= "OctoPawn" then return end
        if type(OctoPawnDB) ~= "table" then OctoPawnDB = {} end
        if type(OctoPawnDB.weights) ~= "table" then OctoPawnDB.weights = {} end
        if type(OctoPawnDB.customWeights) ~= "table" then OctoPawnDB.customWeights = {} end
        if type(OctoPawnDB.inspectRole) ~= "table" then OctoPawnDB.inspectRole = {} end
        if type(OctoPawnDB.dr) ~= "table" then OctoPawnDB.dr = {} end
        if type(OctoPawnDB.defaultOverrides) ~= "table" then OctoPawnDB.defaultOverrides = {} end
        if OctoPawnDB.role then
            local role = OctoPawnDB.role
            if OctoPawnDB.useCustom and OctoPawnDB.customWeights[role] then
                for stat, value in pairs(OctoPawnDB.customWeights[role]) do
                    if OctoPawnDB.weights[stat] == nil then OctoPawnDB.weights[stat] = value end
                end
            end
            local defaults = OctoPawn_GetDefaultWeights()
            for stat, value in pairs(defaults) do
                if OctoPawnDB.weights[stat] == nil then OctoPawnDB.weights[stat] = value end
            end
        end
        local cls = OctoPawn_GetClass and OctoPawn_GetClass()
        local nRoles = 0
        if cls and defaultWeights and defaultWeights[cls] then
            for _ in pairs(defaultWeights[cls]) do nRoles = nRoles + 1 end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: DB ready. Class=" .. tostring(cls) .. " roles=" .. nRoles .. "|r")
        if OctoPawn_OnDBReady then OctoPawn_OnDBReady() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        this:UnregisterEvent("PLAYER_ENTERING_WORLD")
        local needsPicker = false
        if not OctoPawnDB.role then needsPicker = true
        else
            local n = 0
            for _ in pairs(OctoPawnDB.weights or {}) do n = n + 1; break end
            if n == 0 then needsPicker = true end
        end
        if needsPicker then
            if OctoPawn_ShowRolePicker then
                local ok, err = pcall(OctoPawn_ShowRolePicker)
                if not ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn role picker error: " .. tostring(err) .. "|r")
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Role picker missing (UI not loaded?).|r")
            end
        end
    end
end)

print("|cFF00FF00OctoPawn|r core loaded")
