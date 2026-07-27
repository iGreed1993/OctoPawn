-------------------------------------------------
-- OctoPawn UI/Config.lua
-------------------------------------------------
local editBoxes = {}
local orderedBoxes = {}
local createdFrames = {}
local configFrame, scrollFrame, scrollChild, title
local rolePickerFrame
local compareBtn
local advancedFrame
local advRows = {}

local function UpdateMinimapButtonPosition()
    if not OctoPawnMinimapBtn then return end
    local angle = 200
    if OctoPawnDB and OctoPawnDB.minimapPos then angle = OctoPawnDB.minimapPos end
    local rad = math.rad(angle)
    OctoPawnMinimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * 80, math.sin(rad) * 80)
end

local function CreateMinimapButton()
    if OctoPawnMinimapBtn then return end
    local btn = CreateFrame("Button", "OctoPawnMinimapBtn", Minimap)
    btn:SetWidth(31); btn:SetHeight(31)
    btn:SetFrameStrata("MEDIUM"); btn:SetFrameLevel(8)
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("TOPLEFT", 6, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gem_03"); btn.icon = icon
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53); overlay:SetHeight(53); overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnDragStart", function()
        this:SetScript("OnUpdate", function()
            local mx, my = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            mx, my = mx / scale, my / scale
            local angle = math.deg(math.atan2(my - cy, mx - cx))
            if angle < 0 then angle = angle + 360 end
            if not OctoPawnDB then OctoPawnDB = {} end
            OctoPawnDB.minimapPos = angle
            UpdateMinimapButtonPosition()
        end)
    end)
    btn:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnClick", function()
        if arg1 == "LeftButton" then ToggleConfigFrame() end
    end)
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("OctoPawn", 0, 1, 0)
        local role = (OctoPawnDB and OctoPawnDB.role) or "none"
        GameTooltip:AddLine("Role: " .. role, 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Left-click: Open config", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UpdateMinimapButtonPosition()
end
CreateMinimapButton()
local delayFrame = CreateFrame("Frame")
delayFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
delayFrame:SetScript("OnEvent", function()
    CreateMinimapButton()
    UpdateMinimapButtonPosition()
end)

configFrame = CreateFrame("Frame", nil, UIParent)
configFrame:SetWidth(420); configFrame:SetHeight(480)
configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
})
configFrame:Hide()
configFrame:EnableMouse(true)
configFrame:SetMovable(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", function() this:StartMoving() end)
configFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", configFrame, "TOP", 0, -18)
title:SetText("OctoPawn")
local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)
scrollFrame = CreateFrame("ScrollFrame", "OctoPawnScrollFrame", configFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -150, 60)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function()
    local current = this:GetVerticalScroll()
    local maxScroll = this:GetVerticalScrollRange()
    local scrollStep = 28
    if arg1 > 0 then
        local newPos = current - scrollStep
        if newPos < 0 then newPos = 0 end
        this:SetVerticalScroll(newPos)
    else
        local newPos = current + scrollStep
        if newPos > maxScroll then newPos = maxScroll end
        this:SetVerticalScroll(newPos)
    end
end)
scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250); scrollChild:SetHeight(1600)
scrollFrame:SetScrollChild(scrollChild)

local function UpdateCompareButtonText()
    if not compareBtn then return end
    if OctoPawnDB and OctoPawnDB.compareEnabled == false then
        compareBtn:SetText("Compare: OFF")
    else
        compareBtn:SetText("Compare: ON")
    end
end

local function MakeCmdButton(label, yOffset, onClick)
    local b = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    b:SetWidth(105); b:SetHeight(26)
    b:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -18, yOffset)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

MakeCmdButton("Spec", -55, function()
    OctoPawn_ShowRolePicker()
end)
compareBtn = MakeCmdButton("Compare: ON", -88, function()
    if not OctoPawnDB then OctoPawnDB = {} end
    if OctoPawnDB.compareEnabled == false then
        OctoPawnDB.compareEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Item compare ON|r")
    else
        OctoPawnDB.compareEnabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Item compare OFF|r")
    end
    UpdateCompareButtonText()
end)
MakeCmdButton("Reset", -121, function()
    if not OctoPawnDB then OctoPawnDB = {} end
    OctoPawnDB.weights = {}
    OctoPawnDB.role = nil
    OctoPawnDB.useCustom = false
    if OctoPawn_WipeConfigUI then OctoPawn_WipeConfigUI() end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Weights cleared. Choose a role.|r")
    if OctoPawn_ShowRolePicker then OctoPawn_ShowRolePicker() end
end)
MakeCmdButton("Help", -154, function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: /op /op compare /op spec /op reset /op help|r")
end)
MakeCmdButton("Advanced", -187, function()
    if ToggleAdvancedFrame then ToggleAdvancedFrame() end
end)

function OctoPawn_RefreshCompareButton() UpdateCompareButtonText() end

-- Advanced soft-cap UI defined after helpers
local function EnsureAdvancedFrame()
    if advancedFrame then return end
    advancedFrame = CreateFrame("Frame", "OctoPawnAdvancedFrame", UIParent)
    advancedFrame:SetWidth(460); advancedFrame:SetHeight(420)
    advancedFrame:SetPoint("CENTER", 40, 20)
    advancedFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
    })
    advancedFrame:SetFrameStrata("DIALOG")
    advancedFrame:EnableMouse(true)
    advancedFrame:SetMovable(true)
    advancedFrame:RegisterForDrag("LeftButton")
    advancedFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    advancedFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    advancedFrame:Hide()
    local at = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    at:SetPoint("TOP", 0, -14); at:SetText("Advanced — Soft Caps")
    local close = CreateFrame("Button", nil, advancedFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    local hint = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", at, "BOTTOM", 0, -4)
    hint:SetText("Empty Soft Cap = no DR. Post Scale default 0.5")

    local hdr1 = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr1:SetPoint("TOPLEFT", advancedFrame, "TOPLEFT", 24, -48)
    hdr1:SetText("Stat")
    local hdr2 = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr2:SetPoint("TOPLEFT", advancedFrame, "TOPLEFT", 200, -48)
    hdr2:SetText("Soft Cap")
    local hdr3 = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr3:SetPoint("TOPLEFT", advancedFrame, "TOPLEFT", 300, -48)
    hdr3:SetText("Post Scale")
    advancedFrame.scroll = CreateFrame("ScrollFrame", "OctoPawnAdvScroll", advancedFrame, "UIPanelScrollFrameTemplate")
    advancedFrame.scroll:SetPoint("TOPLEFT", 16, -64)
    advancedFrame.scroll:SetPoint("BOTTOMRIGHT", -36, 50)
    advancedFrame.child = CreateFrame("Frame", nil, advancedFrame.scroll)
    advancedFrame.child:SetWidth(400); advancedFrame.child:SetHeight(2000)
    advancedFrame.scroll:SetScrollChild(advancedFrame.child)
    local save = CreateFrame("Button", nil, advancedFrame, "UIPanelButtonTemplate")
    save:SetWidth(120); save:SetHeight(26); save:SetPoint("BOTTOM", -70, 16)
    save:SetText("Save Soft Caps")
    save:SetScript("OnClick", function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.dr = {}
        local defaults = OctoPawn_GetDefaultDR and OctoPawn_GetDefaultDR() or {}
        local _, row
        for _, row in ipairs(advRows) do
            local softVal = tonumber(row.soft:GetText()) or 0
            local postVal = tonumber(row.post:GetText())
            if not postVal then postVal = 0.5 end
            if softVal > 0 then
                -- custom / enabled DR
                OctoPawnDB.dr[row.stat] = { softCap = softVal, postScale = postVal }
            elseif defaults[row.stat] then
                -- soft 0 on a built-in stat = explicitly disable that default DR
                OctoPawnDB.dr[row.stat] = { softCap = 0, postScale = postVal }
            end
            -- soft 0 and no built-in = leave unset (linear)
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Soft caps saved.|r")
    end)
    local clear = CreateFrame("Button", nil, advancedFrame, "UIPanelButtonTemplate")
    clear:SetWidth(100); clear:SetHeight(26); clear:SetPoint("BOTTOM", 70, 16)
    clear:SetText("Clear All")
    clear:SetScript("OnClick", function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.dr = {}
        local _, row
        for _, row in ipairs(advRows) do row.soft:SetText(""); row.post:SetText("") end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Soft caps cleared.|r")
    end)
end

local function BuildAdvancedRows()
    EnsureAdvancedFrame()
    local _, row
    for _, row in ipairs(advRows) do
        if row.frame then row.frame:Hide(); row.frame:SetParent(nil) end
    end
    advRows = {}
    local weights = (OctoPawnDB and OctoPawnDB.weights) or {}
    local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
    local statsMap = {}
    for s in pairs(weights) do statsMap[s] = true end
    for s in pairs(defaults) do statsMap[s] = true end
    -- If still empty, pull every stat from all class/role tables
    if not next(statsMap) and defaultWeights then
        for _, classTable in pairs(defaultWeights) do
            if type(classTable) == "table" then
                for k, v in pairs(classTable) do
                    if type(v) == "table" then
                        for s in pairs(v) do statsMap[s] = true end
                    else
                        statsMap[k] = true
                    end
                end
            end
        end
    end
    local stats = {}
    for s in pairs(statsMap) do table.insert(stats, s) end
    table.sort(stats)
    local y = -4
    local i, stat
    for i, stat in ipairs(stats) do
        local f = CreateFrame("Frame", nil, advancedFrame.child)
        f:SetWidth(380); f:SetHeight(24)
        f:SetPoint("TOPLEFT", advancedFrame.child, "TOPLEFT", 4, y)
        local lab = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("LEFT", 2, 0); lab:SetWidth(170); lab:SetJustifyH("LEFT"); lab:SetText(stat)
        local soft = CreateFrame("EditBox", nil, f)
        soft:SetWidth(70); soft:SetHeight(18); soft:SetPoint("LEFT", 180, 0)
        soft:SetAutoFocus(false); soft:SetFontObject("GameFontHighlight"); soft:SetJustifyH("CENTER")
        soft:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12 })
        soft:SetBackdropColor(0.1, 0.1, 0.1, 0.9); soft:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        local post = CreateFrame("EditBox", nil, f)
        post:SetWidth(70); post:SetHeight(18); post:SetPoint("LEFT", 280, 0)
        post:SetAutoFocus(false); post:SetFontObject("GameFontHighlight"); post:SetJustifyH("CENTER")
        post:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12 })
        post:SetBackdropColor(0.1, 0.1, 0.1, 0.9); post:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        -- Player override, else built-in default DR, else 0
        local dr = nil
        if OctoPawn_GetDR then
            dr = OctoPawn_GetDR(stat)
        elseif OctoPawnDB and OctoPawnDB.dr and OctoPawnDB.dr[stat] then
            dr = OctoPawnDB.dr[stat]
        end
        -- If player explicitly set 0, GetDR returns nil — show 0
        if OctoPawnDB and OctoPawnDB.dr and OctoPawnDB.dr[stat] and tonumber(OctoPawnDB.dr[stat].softCap) == 0 then
            soft:SetText("0")
            post:SetText(tostring(OctoPawnDB.dr[stat].postScale or 0))
        elseif dr and dr.softCap then
            soft:SetText(tostring(dr.softCap))
            post:SetText(tostring(dr.postScale or 0.5))
        else
            soft:SetText("0")
            post:SetText("0")
        end
        table.insert(advRows, { frame = f, stat = stat, soft = soft, post = post })
        y = y - 26
    end
    advancedFrame.child:SetHeight(math.max(200, -y + 20))
end

function ToggleAdvancedFrame()
    EnsureAdvancedFrame()
    if advancedFrame:IsShown() then advancedFrame:Hide()
    else BuildAdvancedRows(); advancedFrame:Show() end
end

local function WipeEditBoxes()
    for _, frame in ipairs(createdFrames) do frame:Hide(); frame:SetParent(nil) end
    createdFrames = {}; editBoxes = {}; orderedBoxes = {}
    if scrollChild then scrollChild:Hide(); scrollChild:SetParent(nil) end
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(250); scrollChild:SetHeight(1600)
    scrollFrame:SetScrollChild(scrollChild)
end
function OctoPawn_WipeConfigUI()
    WipeEditBoxes()
    if configFrame and configFrame:IsShown() then configFrame:Hide() end
end

local function SaveWeights()
    if not OctoPawnDB then OctoPawnDB = {} end
    if not OctoPawnDB.weights then OctoPawnDB.weights = {} end
    if not OctoPawnDB.customWeights then OctoPawnDB.customWeights = {} end
    local role = OctoPawnDB.role
    if not role then
        for stat, box in pairs(editBoxes) do OctoPawnDB.weights[stat] = tonumber(box:GetText()) or 1.0 end
        return
    end
    OctoPawnDB.customWeights[role] = {}
    for stat, box in pairs(editBoxes) do
        local val = tonumber(box:GetText()) or 1.0
        OctoPawnDB.weights[stat] = val
        OctoPawnDB.customWeights[role][stat] = val
    end
    OctoPawnDB.useCustom = true
end

local function BuildEditBoxes()
    local playerClass = OctoPawn_GetClass and OctoPawn_GetClass() or "?"
    local role = (OctoPawnDB and OctoPawnDB.role) or "Default"
    local suffix = (OctoPawnDB and OctoPawnDB.useCustom) and " (custom)" or ""
    title:SetText("OctoPawn - " .. playerClass .. " (" .. role .. suffix .. ")")
    if next(editBoxes) ~= nil then
        local saved = (OctoPawnDB and OctoPawnDB.weights) or {}
        local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
        for stat, box in pairs(editBoxes) do
            local value = saved[stat]; if value == nil then value = defaults[stat] or 1.0 end
            box:SetText(tostring(value))
        end
        UpdateCompareButtonText(); return
    end
    local saved = (OctoPawnDB and OctoPawnDB.weights) or {}
    local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
    local allStats = {}
    for stat in pairs(defaults) do allStats[stat] = true end
    for stat in pairs(saved) do allStats[stat] = true end
    local sortedStats = {}
    for stat in pairs(allStats) do table.insert(sortedStats, stat) end
    table.sort(sortedStats, function(a, b)
        local va = saved[a]; if va == nil then va = defaults[a] or 0 end
        local vb = saved[b]; if vb == nil then vb = defaults[b] or 0 end
        if va ~= vb then return va > vb end
        return a < b
    end)
    local y = -10
    for _, stat in ipairs(sortedStats) do
        local value = saved[stat]; if value == nil then value = defaults[stat] or 1.0 end
        local box = CreateFrame("EditBox", nil, scrollChild)
        box:SetWidth(70); box:SetHeight(20); box:SetAutoFocus(false)
        box:SetFontObject("GameFontHighlight"); box:SetText(tostring(value)); box:SetJustifyH("CENTER")
        box:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        box:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12 })
        box:SetBackdropColor(0.1, 0.1, 0.1, 0.9); box:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        box:SetScript("OnTextChanged", function()
            local text = this:GetText() or ""
            local clean = string.gsub(text, "[^0-9%.%-]", "")
            if clean ~= text then this:SetText(clean) end
        end)
        local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", box, "RIGHT", 12, 0); label:SetText(stat)
        editBoxes[stat] = box
        table.insert(orderedBoxes, box)
        table.insert(createdFrames, box); table.insert(createdFrames, label)
        y = y - 28
    end
    local function FocusNextBox(current)
        current:HighlightText(0, 0)
        for i, box in ipairs(orderedBoxes) do
            if box == current then
                local nextIndex = i + 1
                if nextIndex > table.getn(orderedBoxes) then nextIndex = 1 end
                local nextBox = orderedBoxes[nextIndex]
                nextBox:SetFocus(); nextBox:HighlightText()
                local _, _, _, _, yOfs = nextBox:GetPoint()
                local targetScroll = -(yOfs or 0) - 10
                if targetScroll < 0 then targetScroll = 0 end
                local maxScroll = scrollFrame:GetVerticalScrollRange()
                if targetScroll > maxScroll then targetScroll = maxScroll end
                scrollFrame:SetVerticalScroll(targetScroll)
                return
            end
        end
    end
    for _, box in ipairs(orderedBoxes) do
        box:SetScript("OnTabPressed", function() FocusNextBox(this) end)
        box:SetScript("OnEnterPressed", function() FocusNextBox(this) end)
    end
    UpdateCompareButtonText()
end

local saveBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
saveBtn:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 20)
saveBtn:SetWidth(120); saveBtn:SetHeight(28); saveBtn:SetText("Save Weights")
saveBtn:SetScript("OnClick", function()
    SaveWeights(); WipeEditBoxes(); BuildEditBoxes(); scrollFrame:SetVerticalScroll(0)
    local role = (OctoPawnDB and OctoPawnDB.role) or "current"
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Saved as " .. role .. " (custom).|r")
end)
configFrame:SetScript("OnHide", function() SaveWeights() end)

function ToggleConfigFrame()
    if configFrame:IsShown() then configFrame:Hide()
    else BuildEditBoxes(); UpdateCompareButtonText(); configFrame:Show() end
end

function OctoPawn_ShowRolePicker()
    if not rolePickerFrame then
        rolePickerFrame = CreateFrame("Frame", "OctoPawnRolePicker", UIParent)
        rolePickerFrame:SetWidth(280)
        rolePickerFrame:SetHeight(320)
        rolePickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        rolePickerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        rolePickerFrame:SetFrameStrata("DIALOG")
        rolePickerFrame:EnableMouse(true)
        rolePickerFrame:SetMovable(true)
        rolePickerFrame:RegisterForDrag("LeftButton")
        rolePickerFrame:SetScript("OnDragStart", function() this:StartMoving() end)
        rolePickerFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        local pickerTitle = rolePickerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        pickerTitle:SetPoint("TOP", rolePickerFrame, "TOP", 0, -18)
        pickerTitle:SetText("Choose Role")
        rolePickerFrame.title = pickerTitle
        rolePickerFrame.buttons = {}
    end

    if rolePickerFrame.buttons then
        local bi
        for bi = 1, table.getn(rolePickerFrame.buttons) do
            local b = rolePickerFrame.buttons[bi]
            if b then b:Hide(); b:SetParent(nil) end
        end
    end
    rolePickerFrame.buttons = {}

    local class = nil
    if OctoPawn_GetClass then class = OctoPawn_GetClass() end
    if not class then
        local _, c = UnitClass("player")
        class = c or "WARRIOR"
    end

    local roles = {}
    if OctoPawn_GetRolesForClass then
        local ok, result = pcall(OctoPawn_GetRolesForClass, class)
        if ok and type(result) == "table" then roles = result end
    end
    if table.getn(roles) == 0 and defaultWeights and defaultWeights[class] then
        for r, v in pairs(defaultWeights[class]) do
            if type(v) == "table" then table.insert(roles, r) end
        end
        table.sort(roles)
    end
    if table.getn(roles) == 0 then
        table.insert(roles, "Default")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: No roles for " .. tostring(class) .. ". Check Defaults load.|r")
    end

    rolePickerFrame.title:SetText("OctoPawn - " .. tostring(class))

    local y = -60
    local buttonCount = 0
    local ri
    for ri = 1, table.getn(roles) do
        local role = roles[ri]
        local btn = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
        btn:SetWidth(200)
        btn:SetHeight(28)
        btn:SetPoint("TOP", rolePickerFrame, "TOP", 0, y)
        btn:SetText(role)
        btn.roleName = role
        btn:SetScript("OnClick", function()
            if OctoPawn_ApplyRole then OctoPawn_ApplyRole(this.roleName, false) end
            rolePickerFrame:Hide()
            if OctoPawn_WipeConfigUI then
                -- only wipe boxes, keep frame
            end
            WipeEditBoxes()
            if configFrame and configFrame:IsShown() then BuildEditBoxes() end
        end)
        table.insert(rolePickerFrame.buttons, btn)
        y = y - 32
        buttonCount = buttonCount + 1

        if OctoPawnDB and OctoPawnDB.customWeights and OctoPawnDB.customWeights[role] then
            local cbtn = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
            cbtn:SetWidth(200)
            cbtn:SetHeight(28)
            cbtn:SetPoint("TOP", rolePickerFrame, "TOP", 0, y)
            cbtn:SetText(role .. " (custom)")
            cbtn.roleName = role
            cbtn:SetScript("OnClick", function()
                if OctoPawn_ApplyRole then OctoPawn_ApplyRole(this.roleName, true) end
                rolePickerFrame:Hide()
                WipeEditBoxes()
                if configFrame and configFrame:IsShown() then BuildEditBoxes() end
            end)
            table.insert(rolePickerFrame.buttons, cbtn)
            y = y - 32
            buttonCount = buttonCount + 1
        end
    end

    local height = 80 + (buttonCount * 32)
    if height < 160 then height = 160 end
    if height > 500 then height = 500 end
    rolePickerFrame:SetHeight(height)
    rolePickerFrame:Show()
end

function OctoPawn_OnDBReady() end
print("|cFF00FF00OctoPawn|r UI loaded")
