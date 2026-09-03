--start of MacroCommander.lua (Box 1 of 14)
-- ==========================================
-- NOTE: \031 is the ASCII Unit Separator.
-- It replaces spaces in macro names safely.
-- It avoids character index mismatches.
-- ==========================================

local MainFrame, ConfigFrame
local textWidthFrame = CreateFrame("Frame")
local textWidthTester = textWidthFrame
    :CreateFontString(nil, "BACKGROUND", 
    "GameFontNormal")

_G["BINDING_HEADER_MC_HEADER"] = 
    "|cFFFFFFFFMacro Commander|r"
_G["BINDING_NAME_MC_TOGGLE_BAR"] = 
    "|cFF00FF00Toggle Main Bar Visibility|r"

local MC = LibStub("AceAddon-3.0")
    :NewAddon("MacroCommander", 
    "AceConsole-3.0")

local L = {
    Skin = {
        bgFile = "Interface\\DialogFrame\\"
            .. "UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\"
            .. "UI-DialogBox-Border",
        tile = true, tileSize = 32, 
        edgeSize = 16,
        insets = { left = 4, right = 4, 
            top = 4, bottom = 4 }
    }
}

local function GetDefaultDB()
    return {
        profile = {
            main_pct_x = 0.5,
            main_pct_y = 0.5,
            config_x = 100, config_y = 0,
            buttonHeight = 25,
            alpha = 1.0,
            scale = 1.0,
            locked = false,
            visible = true,
            buttons = {
                { name = "Default", 
                  macro = "Macro" }
            }
        }
    }
end
--end of MacroCommander.lua (Box 1 of 14)
--start of MacroCommander.lua (Box 2 of 14)
-- ==========================================
-- Reset layout positions back to coordinate
-- midpoints on the monitor layout.
-- ==========================================

local function ResetWindowPositions()
    local db = MC.db.profile
    db.main_pct_x = 0.5
    db.main_pct_y = 0.5
    db.config_x = 100
    db.config_y = 0
    
    local sW, sH = UIParent:GetWidth(), 
        UIParent:GetHeight()
    local scale = MainFrame:GetScale() or 1.0
    MainFrame:ClearAllPoints()
    MainFrame:SetPoint("CENTER", UIParent, 
        "BOTTOMLEFT", 
        (sW * db.main_pct_x) / scale, 
        (sH * db.main_pct_y) / scale)
    
    if ConfigFrame then
        ConfigFrame:ClearAllPoints()
        ConfigFrame:SetPoint("CENTER", 
            UIParent, "CENTER", 
            db.config_x, db.config_y)
    end
    print("|cFF00FF00MC: Positions reset"
        .. " to center virtual anchor.|r")
end

function MC:RefreshUI()
    if InCombatLockdown() then return end
    
    -- Sync current data layout references with the active profile variables space
    local db = self.db.profile
    
    MainFrame:SetAlpha(db.alpha or 1.0)
    MainFrame:SetScale(db.scale or 1.0)
--end of MacroCommander.lua (Box 2 of 14)
--start of MacroCommander.lua (Box 3 of 14)
-- ==========================================
-- Rebuild interface canvas framework and
-- calculate longest text width parameters.
-- ==========================================

    local db = self.db.profile
    MainFrame:SetBackdrop(L.Skin)
    MainFrame:SetBackdropColor(1, 1, 1, 1)
    if ConfigFrame then 
        ConfigFrame:SetBackdrop(L.Skin) 
        ConfigFrame:SetBackdropColor(1, 1, 
            1, 1)
    end
    
    local maxTextWidth = 70 
    for idx, btnData in ipairs(db.buttons) do
        if not btnData.name or 
            btnData.name == "" or 
            btnData.name == " " then
            btnData.name = 
                "[Error: Bad Name]"
        end
        textWidthTester:SetText(btnData.name)
        local w = textWidthTester
            :GetStringWidth()
        if w > maxTextWidth then 
            maxTextWidth = w 
        end
    end
    local finalWidth = maxTextWidth + 24
    MainFrame:SetWidth(finalWidth)

    if MainFrame.buttons then
        for _, oldBtn in 
            ipairs(MainFrame.buttons) do 
            oldBtn:Hide() 
        end
    end
    MainFrame.buttons = {}
    local totalHeight = 28
--end of MacroCommander.lua (Box 3 of 14)
--start of MacroCommander.lua (Box 4 of 14)
-- ==========================================
-- Populate active custom macro layout row
-- buttons into secure environment frames.
-- ==========================================

    local db = self.db.profile
    for i, btnData in ipairs(db.buttons) do
        local btn = CreateFrame("Button", 
            "MC_ActionBarBtn" .. i, 
            MainFrame, 
            "SecureActionButtonTemplate,"
            .. "UIPanelButtonTemplate")
        btn:SetSize(finalWidth - 10, 
            db.buttonHeight)
        btn:SetPoint("TOP", MainFrame, 
            "TOP", 0, -18 - ((i - 1) * 
            db.buttonHeight))
        btn:SetText(btnData.name)
        
        local normalText = btn:GetFontString()
        if normalText then 
            normalText:SetTextColor(0.85, 
                0.85, 0.85) 
        end
        
        local activeMacro = string.gsub(
            btnData.macro or "Macro", 
            "\031", " ")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macro", 
            activeMacro)
        
        table.insert(MainFrame.buttons, btn)
        totalHeight = totalHeight + 
            db.buttonHeight
    end
    MainFrame:SetHeight(totalHeight)
    
    local sW, sH = UIParent:GetWidth(), 
        UIParent:GetHeight()
    local scale = MainFrame:GetScale() or 1.0
    MainFrame:ClearAllPoints()
    MainFrame:SetPoint("CENTER", UIParent, 
        "BOTTOMLEFT", 
        (sW * db.main_pct_x) / scale, 
        (sH * db.main_pct_y) / scale)
    
    if db.visible then 
        MainFrame:Show() 
    else 
        MainFrame:Hide() 
    end
end
--end of MacroCommander.lua (Box 4 of 14)
--start of MacroCommander.lua (Box 5 of 14)
-- ==========================================
-- Finish window placement recalculations and
-- construct configuration base backdrop.
-- ==========================================

local function CreateConfigFrame(
    refreshCallback)
    local db = MC.db.profile
    local statusText
    local UpdateUnsavedStatus
    local CaptureCommitted
    local committed = {}
    local cfg = CreateFrame("Frame", 
        "MC_ConfigFrame", UIParent)
    cfg:SetSize(320, 410) 
    cfg:SetPoint("CENTER", UIParent, 
        "CENTER", db.config_x, db.config_y)
    
    cfg:SetMovable(true)
    cfg:EnableMouse(true)
    cfg:RegisterForDrag("LeftButton")
    cfg:SetScript("OnDragStart", 
        cfg.StartMoving)
    cfg:SetScript("OnDragStop", 
        function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        MC.db.profile.config_x = x
        MC.db.profile.config_y = y
    end)
    cfg:Hide()

    local title = cfg:CreateFontString(nil, 
        "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", cfg, "TOP", 0, 
        -12)
    title:SetText("MC Configurations")
    title:SetTextColor(1.0, 0.82, 0.0)
--end of MacroCommander.lua (Box 5 of 14)
--start of MacroCommander.lua (Box 6 of 14)
-- ==========================================
-- Setup mouse motion frame tracking anchors
-- and draw initial large configuration titles.
-- ==========================================

    local selectedIndex = 1
    
    -- Up/down sit in the droplist's empty left padding. The 2px
    -- gap between them is centered on the droplist midline.
    local upBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    upBtn:SetSize(16, 16)
    upBtn:SetText("^")

    local downBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    downBtn:SetSize(16, 16)
    downBtn:SetPoint("TOPLEFT", upBtn, "BOTTOMLEFT", 0, -2)
    downBtn:SetText("v")

    local dropdown = CreateFrame("Frame", 
        "MC_ButtonDropdown", cfg, 
        "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", cfg, 
        "TOPLEFT", 10, -42)
    UIDropDownMenu_SetWidth(dropdown, 130)
    upBtn:SetPoint("RIGHT", dropdown, 
        "LEFT", 16, 9)

    local renameBox = CreateFrame("EditBox", 
        "MC_RenameBox", cfg, 
        "InputBoxTemplate")
    renameBox:SetSize(108, 20)
    renameBox:SetPoint("LEFT", dropdown, 
        "RIGHT", -6, 2)
    renameBox:SetAutoFocus(false)
    renameBox:SetScript("OnEnterPressed", 
        function(self) self:ClearFocus() 
    end)
--end of MacroCommander.lua (Box 6 of 14)
--start of MacroCommander.lua (Box 7 of 14)
-- ==========================================
-- Create contextual update triggers when dropdown
-- list selection values shift targets.
-- ==========================================

    local macroNameLabel = cfg
        :CreateFontString(nil, "OVERLAY", 
        "GameFontHighlightSmall")
    macroNameLabel:SetText("Macro name")

    local macroInputBox = CreateFrame(
        "EditBox", "MC_MacroInputBox", cfg, 
        "InputBoxTemplate")
    macroInputBox:SetSize(110, 20) 
    macroInputBox:SetPoint("LEFT", 
        macroNameLabel, "RIGHT", 8, -1)
    macroInputBox:SetAutoFocus(false)
    macroInputBox:SetScript(
        "OnEnterPressed", function(self) 
        self:ClearFocus() 
    end)

    local function Dropdown_OnClick(self)
        selectedIndex = self.value
        local pDB = MC.db.profile
        UIDropDownMenu_SetSelectedValue(
            dropdown, selectedIndex)
        _G[dropdown:GetName() .. "Text"]
            :SetText(pDB.buttons[
            selectedIndex].name)
        renameBox:SetText(pDB.buttons[
            selectedIndex].name)
        
        local activeMacro = string.gsub(
            pDB.buttons[selectedIndex].macro 
            or "Macro", "\031", " ")
        macroInputBox:SetText(activeMacro)
    end
--end of MacroCommander.lua (Box 7 of 14)
--start of MacroCommander.lua (Box 8 of 14)
-- ==========================================
-- Draw primary data table array templates
-- when initializing control setups.
-- ==========================================

    local function InitializeDropdown()
        local info = 
            UIDropDownMenu_CreateInfo()
        local pDB = MC.db.profile
        for i, btnData in ipairs(
            pDB.buttons) do
            info.text = btnData.name or 
                "[Error: Bad Name]"
            info.value = i
            info.func = Dropdown_OnClick
            info.checked = (i == 
                selectedIndex)
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(dropdown, 
        InitializeDropdown)
    UIDropDownMenu_SetSelectedValue(
        dropdown, 1)
    _G[dropdown:GetName() .. "Text"]
        :SetText(db.buttons and 
        db.buttons[selectedIndex].name 
        or "Default")
    renameBox:SetText(db.buttons and 
        db.buttons[selectedIndex].name 
        or "Default")
--end of MacroCommander.lua (Box 8 of 14)
--start of MacroCommander.lua (Box 9 of 14)
-- ==========================================
-- Define reference record insertions for 
-- expanding custom control node layouts.
-- ==========================================

    local initialMacro = string.gsub(
        db.buttons and db.buttons[
        selectedIndex].macro or "Macro", 
        "\031", " ")
    macroInputBox:SetText(initialMacro)

    local addBtn = CreateFrame("Button", 
        nil, cfg, "UIPanelButtonTemplate")
    addBtn:SetSize(20, 20)
    addBtn:SetPoint("TOPLEFT", downBtn, 
        "BOTTOMLEFT", 0, -6)
    addBtn:SetText("+")

    addBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        local pDB = MC.db.profile
        local nextID = #pDB.buttons + 1
        table.insert(pDB.buttons, 
            { name = "unnamed", 
              macro = "Macro" })
        selectedIndex = nextID
        UIDropDownMenu_Initialize(dropdown, 
            InitializeDropdown)
        UIDropDownMenu_SetSelectedValue(
            dropdown, selectedIndex)
        _G[dropdown:GetName() .. "Text"]
            :SetText("unnamed")
        renameBox:SetText("unnamed")
        macroInputBox:SetText("Macro")
        refreshCallback()
    end)
--end of MacroCommander.lua (Box 9 of 14)
--start of MacroCommander.lua (Box 10 of 14)
-- ==========================================
-- Configure up and down button movements to
-- reorder action rows inside profile tables.
-- ==========================================

    local remBtn = CreateFrame("Button", 
        nil, cfg, "UIPanelButtonTemplate")
    remBtn:SetSize(20, 20)
    remBtn:SetPoint("LEFT", addBtn, 
        "RIGHT", 4, 0)
    remBtn:SetText("-")
    macroInputBox:ClearAllPoints()
    macroInputBox:SetSize(108, 20)
    macroInputBox:SetPoint("TOPLEFT", 
        renameBox, "BOTTOMLEFT", 0, -14)
    macroNameLabel:ClearAllPoints()
    macroNameLabel:SetPoint("LEFT", remBtn, 
        "RIGHT", 6, 0)
    macroNameLabel:SetPoint("RIGHT", 
        macroInputBox, "LEFT", -6, 0)
    macroNameLabel:SetJustifyH("LEFT")

    local function RefreshSelectionEditor()
        local pDB = MC.db.profile
        local btn = pDB.buttons[selectedIndex]
        UIDropDownMenu_Initialize(dropdown, 
            InitializeDropdown)
        UIDropDownMenu_SetSelectedValue(
            dropdown, selectedIndex)
        _G[dropdown:GetName() .. "Text"]
            :SetText(btn.name)
        renameBox:SetText(btn.name)
        local activeMacro = string.gsub(
            btn.macro or "Macro", "\031", " ")
        macroInputBox:SetText(activeMacro)
        refreshCallback()
    end

    local function SwapButtonContents(i, j)
        local pDB = MC.db.profile
        local a = pDB.buttons[i]
        local b = pDB.buttons[j]
        a.name, b.name = b.name, a.name
        a.macro, b.macro = b.macro, a.macro
    end

    upBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        local pDB = MC.db.profile
        
        if selectedIndex == 1 then
            statusText:SetText("|cFFFF0000"
                .. "First button cannot"
                .. " be moved|r")
            return
        end
        
        if selectedIndex == 2 then
            SwapButtonContents(1, 2)
            RefreshSelectionEditor()
            return
        end
        
        local temp = pDB.buttons[selectedIndex]
        pDB.buttons[selectedIndex] = 
            pDB.buttons[selectedIndex - 1]
        pDB.buttons[selectedIndex - 1] = temp
        
        selectedIndex = selectedIndex - 1
        RefreshSelectionEditor()
    end)
--end of MacroCommander.lua (Box 10 of 14)
--start of MacroCommander.lua (Box 11 of 14)
-- ==========================================
-- Configure dialog template queries to secure
-- validation verification indicators.
-- ==========================================

    downBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        local pDB = MC.db.profile
        
        if selectedIndex == 1 then
            if #pDB.buttons < 2 then
                statusText:SetText("|cFFFF7F00"
                    .. "Already at bottom|r")
                return
            end
            SwapButtonContents(1, 2)
            RefreshSelectionEditor()
            return
        end
        
        if selectedIndex == #pDB.buttons then
            statusText:SetText("|cFFFF7F00"
                .. "Already at bottom|r")
            return
        end
        
        local temp = pDB.buttons[selectedIndex]
        pDB.buttons[selectedIndex] = 
            pDB.buttons[selectedIndex + 1]
        pDB.buttons[selectedIndex + 1] = temp
        
        selectedIndex = selectedIndex + 1
        RefreshSelectionEditor()
    end)
--end of MacroCommander.lua (Box 11 of 14)
--start of MacroCommander.lua (Box 12 of 14)
-- ==========================================
-- Draw scaling slider parameters and slider
-- tracking mechanics labels.
-- ==========================================

    StaticPopupDialogs[
        "MC_CONFIRM_DELETE"] = {
        text = "Are you sure you want to "
            .. "delete this command button "
            .. "selection reference template"
            .. " configuration?",
        button1 = "Yes", button2 = "No",
        OnAccept = function()
            if InCombatLockdown() then 
                return 
            end
            local pDB = MC.db.profile
            table.remove(pDB.buttons, 
                selectedIndex)
            selectedIndex = 1
            UIDropDownMenu_Initialize(
                dropdown, 
                InitializeDropdown)
            UIDropDownMenu_SetSelectedValue(
                dropdown, 1)
            _G[dropdown:GetName() .. "Text"]
                :SetText(pDB.buttons and 
                pDB.buttons[selectedIndex]
                .name or "Default")
            if pDB.buttons and 
                pDB.buttons[
                selectedIndex] then
                renameBox:SetText(
                    pDB.buttons[
                    selectedIndex].name 
                    or "Default")
                local activeMacro = 
                    string.gsub(pDB.buttons[
                    selectedIndex].macro 
                    or "Macro", "\031", " ")
                macroInputBox:SetText(
                    activeMacro)
            end
            refreshCallback()
        end,
        timeout = 0, whileDead = true, 
        hideOnEscape = true,
    }
--end of MacroCommander.lua (Box 12 of 14)
--start of MacroCommander.lua (Box 13 of 14)
-- ==========================================
-- Configure custom profile management dropdown
-- elements to copy or clear setups.
-- ==========================================

    remBtn:SetScript("OnClick", function()
        if selectedIndex == 1 then
            print("|cFFFF0000MC: First "
                .. "button cannot be deleted,"
                .. " only have it's values"
                .. " changed.|r")
            return
        end
        StaticPopup_Show(
            "MC_CONFIRM_DELETE")
    end)

    local hSlider = CreateFrame("Slider", 
        "MC_HeightSlider", cfg, 
        "OptionsSliderTemplate")
    hSlider:SetPoint("TOPLEFT", addBtn, 
        "BOTTOMLEFT", 0, -22)
    hSlider:SetMinMaxValues(10, 50)
    hSlider:SetValueStep(1)
    hSlider:SetValue(db.buttonHeight)
    _G[hSlider:GetName() .. "Text"]
        :SetText("Button Height: " 
        .. db.buttonHeight)
    _G[hSlider:GetName() .. "Low"]
        :SetText("10")
    _G[hSlider:GetName() .. "High"]
        :SetText("50")
    hSlider:SetScript("OnValueChanged", 
        function(self, value)
        MC.db.profile.buttonHeight = value
        _G[self:GetName() .. "Text"]
            :SetText("Button Height: " 
            .. value)
        refreshCallback()
        if UpdateUnsavedStatus then
            UpdateUnsavedStatus()
        end
    end)

    local aSlider = CreateFrame("Slider", 
        "MC_AlphaSlider", cfg, 
        "OptionsSliderTemplate")
    aSlider:SetPoint("TOPLEFT", hSlider, 
        "BOTTOMLEFT", 0, -25)
    aSlider:SetMinMaxValues(0.1, 1.0)
    aSlider:SetValueStep(0.05)
    aSlider:SetValue(db.alpha or 1.0)
    _G[aSlider:GetName() .. "Text"]
        :SetText("Bar Opacity: " 
        .. string.format("%.2f", db.alpha or 1.0))
    _G[aSlider:GetName() .. "Low"]
        :SetText("0.1")
    _G[aSlider:GetName() .. "High"]
        :SetText("1.0")
    aSlider:SetScript("OnValueChanged", 
        function(self, value)
        MC.db.profile.alpha = value
        _G[self:GetName() .. "Text"]
            :SetText("Bar Opacity: " 
            .. string.format("%.2f", value))
        refreshCallback()
        if UpdateUnsavedStatus then
            UpdateUnsavedStatus()
        end
    end)

    local scaleLabel = cfg
        :CreateFontString(nil, "OVERLAY", 
        "GameFontNormalSmall")
    scaleLabel:SetPoint("TOPLEFT", aSlider, 
        "BOTTOMLEFT", 0, -20)
    scaleLabel:SetText("Button Window Scale %"
        .. " (25 - 100):")

    local scaleBox = CreateFrame("EditBox", 
        "MC_ScaleFieldBox", cfg, 
        "InputBoxTemplate")
    scaleBox:SetSize(45, 20)
    scaleBox:SetPoint("LEFT", scaleLabel, 
        "RIGHT", 10, 0)
    scaleBox:SetMaxLetters(3)
    scaleBox:SetNumeric(true)
    scaleBox:SetAutoFocus(false)
    scaleBox:SetText(tostring(math.floor(
        (db.scale or 1.0) * 100)))
    scaleBox:SetScript("OnEnterPressed", 
        function(self) self:ClearFocus() 
    end)

    local lockCheck = CreateFrame(
        "CheckButton", "MC_LockCheck", cfg, 
        "UICheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", 
        scaleLabel, "BOTTOMLEFT", -4, -12)
    lockCheck:SetChecked(db.locked)
    lockCheck:SetScript("OnClick", 
        function(self)
        MC.db.profile.locked = self:GetChecked()
        if UpdateUnsavedStatus then
            UpdateUnsavedStatus()
        end
    end)

    CaptureCommitted = function()
        local pDB = MC.db.profile
        committed.height = math.floor(
            (pDB.buttonHeight or 25) + 0.5)
        committed.alpha = tonumber(
            string.format("%.2f", 
            pDB.alpha or 1.0))
        committed.scale = math.floor(
            (pDB.scale or 1.0) * 100)
        committed.locked = 
            pDB.locked and true or false
    end

    UpdateUnsavedStatus = function()
        if not statusText then return end
        local pDB = MC.db.profile
        local btn = pDB.buttons and 
            pDB.buttons[selectedIndex]
        local dirty = false
        if btn then
            local nameNow = renameBox:GetText() 
                or ""
            if nameNow ~= (btn.name or "") then
                dirty = true
            end
            local macroNow = 
                macroInputBox:GetText() or ""
            local savedMacro = string.gsub(
                btn.macro or "Macro", 
                "\031", " ")
            if macroNow ~= savedMacro then
                dirty = true
            end
        end
        local scaleNow = tonumber(
            scaleBox:GetText() or "100") or 100
        if scaleNow ~= committed.scale then
            dirty = true
        end
        local heightNow = math.floor(
            (hSlider:GetValue() or 25) + 0.5)
        if heightNow ~= committed.height then
            dirty = true
        end
        local alphaNow = tonumber(
            string.format("%.2f", 
            aSlider:GetValue() or 1.0))
        if alphaNow ~= committed.alpha then
            dirty = true
        end
        local lockNow = lockCheck:GetChecked() 
            and true or false
        if lockNow ~= committed.locked then
            dirty = true
        end
        if dirty then
            statusText:SetText("|cFFFF7F00"
                .. "Unsaved changes detected|r")
        else
            local cur = statusText:GetText() 
                or ""
            if string.find(cur, 
                "Unsaved changes detected") then
                statusText:SetText("")
            end
        end
    end
    CaptureCommitted()
    renameBox:SetScript("OnTextChanged", 
        UpdateUnsavedStatus)
    macroInputBox:SetScript("OnTextChanged", 
        UpdateUnsavedStatus)
    scaleBox:SetScript("OnTextChanged", 
        UpdateUnsavedStatus)

    local lockText = _G[lockCheck:GetName() 
        .. "Text"]
    lockText:SetDrawLayer("OVERLAY")
    lockText:SetText(
        "Lock Main Window Position")

    local pLabel = cfg:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall")
    pLabel:SetPoint("TOPLEFT", lockCheck, 
        "BOTTOMLEFT", 4, -14)
    pLabel:SetText("Profile Management")

    local selectedProf = "Default"
    local pDropdown = CreateFrame("Frame", 
        "MC_ProfileDropdown", cfg, 
        "UIDropDownMenuTemplate")
    pDropdown:SetPoint("TOPLEFT", lockCheck, 
        "BOTTOMLEFT", -12, -26)
    UIDropDownMenu_SetWidth(pDropdown, 120)

    local function ProfDropdown_OnClick(self)
        selectedProf = self.value
        UIDropDownMenu_SetSelectedValue(
            pDropdown, selectedProf)
        _G[pDropdown:GetName() .. "Text"]
            :SetText(selectedProf)
    end

    local function InitProfDropdown()
        local info = 
            UIDropDownMenu_CreateInfo()
        local profiles = MC.db:GetProfiles()
        local activeProfile = MC.db:GetCurrentProfile()
        
        info.text = "Addon Factory Default"
        info.value = "Addon Factory Default"
        info.func = ProfDropdown_OnClick
        info.checked = (selectedProf == "Addon Factory Default")
        UIDropDownMenu_AddButton(info)
        
        for _, pName in ipairs(profiles) do
            info.text = pName
            info.value = pName
            info.func = ProfDropdown_OnClick
            info.checked = (pName == activeProfile)
            UIDropDownMenu_AddButton(info)
        end
    end

    local loadPBtn = CreateFrame("Button", 
        nil, cfg, "UIPanelButtonTemplate")
    loadPBtn:SetSize(45, 20)
    loadPBtn:SetPoint("LEFT", pDropdown, 
        "RIGHT", -10, 3)
    loadPBtn:SetText("Load")
    loadPBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        if selectedProf == "Addon Factory Default" then
            MC.db:ResetProfile()
            ResetWindowPositions()
        else
            MC.db:CopyProfile(selectedProf)
            local checkName = string.lower(selectedProf)
            if checkName == "default" or string.find(checkName, "default") then
                MC.db.profile.main_pct_x = 0.5
                MC.db.profile.main_pct_y = 0.5
            end
        end
        ReloadUI()
    end)
--end of MacroCommander.lua (Box 13 of 14)
--start of MacroCommander.lua (Box 14 of 14)
-- ==========================================
-- Apply interface dimensions and trigger main UI
-- engine updates cleanly.
-- ==========================================

    local delPBtn = CreateFrame("Button", 
        nil, cfg, "UIPanelButtonTemplate")
    delPBtn:SetSize(45, 20)
    delPBtn:SetPoint("LEFT", loadPBtn, 
        "RIGHT", 4, 0)
    delPBtn:SetText("Del")

    delPBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        local current = MC.db:GetCurrentProfile()
        if selectedProf == "Addon Factory Default" then
            print("|cFFFF0000MC: Cannot delete the hardcoded safety profile!|r")
            return
        end
        if selectedProf == current or selectedProf == "Default" then
            print("|cFFFF0000MC: Cannot delete active or base default profile.|r")
            return
        end
        MC.db:DeleteProfile(selectedProf)
        selectedProf = current
        UIDropDownMenu_Initialize(pDropdown, InitProfDropdown)
        UIDropDownMenu_SetSelectedValue(pDropdown, selectedProf)
        _G[pDropdown:GetName() .. "Text"]:SetText(selectedProf)
    end)

    cfg:SetScript("OnShow", function()
        local activeProfName = MC.db:GetCurrentProfile()
        selectedProf = activeProfName
        UIDropDownMenu_Initialize(pDropdown, InitProfDropdown)
        UIDropDownMenu_SetSelectedValue(pDropdown, selectedProf)
        _G[pDropdown:GetName() .. "Text"]:SetText(activeProfName)
        UpdateUnsavedStatus()
    end)

    statusText = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", cfg, "BOTTOM", 0, 45)
    statusText:SetText("")

    local creditText = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    creditText:SetPoint("TOPRIGHT", cfg, "BOTTOMRIGHT", -12, 16)
    creditText:SetText("Co-Developed with GoogleAI")
    creditText:SetTextColor(0.45, 0.45, 0.45, 0.6)

    local saveBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    saveBtn:SetSize(95, 22)
    saveBtn:SetPoint("BOTTOMLEFT", cfg, "BOTTOM", -105, 16)
    saveBtn:SetText("Save Changes")
    saveBtn:SetScript("OnClick", function()
        local pDB = MC.db.profile
        local rawMacro = macroInputBox:GetText() or "Macro"
        if rawMacro == "" or rawMacro == " " then rawMacro = "Macro" end
        local targetMacro = string.gsub(rawMacro, " ", "\031")
        local searchToken = string.lower(rawMacro)
        local genCounts, charCounts = 0, 0
        for i = 1, 36 do
            local mName = GetMacroInfo(i)
            if mName and string.lower(mName) == searchToken then genCounts = genCounts + 1 end
        end
        for i = 37, 54 do
            local mName = GetMacroInfo(i)
            if mName and string.lower(mName) == searchToken then charCounts = charCounts + 1 end
        end
        if genCounts > 1 or charCounts > 1 then
            statusText:SetText("|cFFFF7F00Duplicate macro name detected|r")
            local t = 0
            cfg:SetScript("OnUpdate", function(self, elapsed)
                t = t + elapsed
                if t > 3 then
                    self:SetScript("OnUpdate", nil)
                    UpdateUnsavedStatus()
                end
            end)
            return
        end
        local currentText = renameBox:GetText()
        if currentText and currentText ~= "" and currentText ~= " " then
            pDB.buttons[selectedIndex].name = currentText
        else
            pDB.buttons[selectedIndex].name = "Default"
            renameBox:SetText("Default")
        end
        pDB.buttons[selectedIndex].macro = targetMacro
        macroInputBox:SetText(rawMacro)
        local targetScaleNum = tonumber(scaleBox:GetText() or "100") or 100
        if targetScaleNum < 25 then targetScaleNum = 25 end
        if targetScaleNum > 100 then targetScaleNum = 100 end
        pDB.scale = targetScaleNum / 100
        scaleBox:SetText(tostring(targetScaleNum))
        pDB.buttonHeight = math.floor(
            (hSlider:GetValue() or 25) + 0.5)
        pDB.alpha = tonumber(string.format(
            "%.2f", aSlider:GetValue() or 1.0))
        pDB.locked = lockCheck:GetChecked() 
            and true or false
        CaptureCommitted()
        UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
        _G[dropdown:GetName() .. "Text"]:SetText(pDB.buttons[selectedIndex].name)
        refreshCallback()
        if IsShiftKeyDown() then ReloadUI() else
            statusText:SetText("|cFF00FF00Settings applied!|r")
            local t = 0
            cfg:SetScript("OnUpdate", function(self, elapsed)
                t = t + elapsed
                if t > 3 then
                    self:SetScript("OnUpdate", nil)
                    UpdateUnsavedStatus()
                end
            end)
        end
    end)

    local closeBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    closeBtn:SetSize(95, 22)
    closeBtn:SetPoint("BOTTOMLEFT", cfg, "BOTTOM", 10, 16)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() statusText:SetText(""); cfg:Hide() end)
    return cfg
end

local function InitMainFrame()
    local db = MC.db.profile
    MainFrame = CreateFrame("Frame", "MC_MainFrame", UIParent)
    MainFrame:SetSize(100, 40)
    local sW, sH = UIParent:GetWidth(), UIParent:GetHeight()
    local scale = db.scale or 1.0
    MainFrame:SetScale(scale)
    MainFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (sW * db.main_pct_x) / scale, (sH * db.main_pct_y) / scale)
    MainFrame:SetMovable(true)
    MainFrame:EnableMouse(true)
    MainFrame:RegisterForDrag("LeftButton")
    local frameTitle = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frameTitle:SetPoint("TOP", MainFrame, "TOP", 0, -6)
    frameTitle:SetText("Commander")
    frameTitle:SetTextColor(1.0, 0.82, 0.0)
    MainFrame:SetScript("OnDragStart", function(self) if not MC.db.profile.locked then self:StartMoving() end end)
    MainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local sW, sH = UIParent:GetWidth(), UIParent:GetHeight()
        local centerX, centerY = self:GetCenter()
        local currentScale = self:GetScale() or 1.0
        MC.db.profile.main_pct_x = (centerX * currentScale) / sW
        MC.db.profile.main_pct_y = (centerY * currentScale) / sH
    end)
end

function MC:OnInitialize()
    local charName = UnitName("player")
    local realmName = GetRealmName()
    self.db = LibStub("AceDB-3.0"):New("MacroCommanderDB", GetDefaultDB(), charName .. " - " .. realmName)
    local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local db_options_reg_key = "MacroCommanderProfiles"
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(db_options_reg_key, profileOptions)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(db_options_reg_key, "Profiles", "Macro Commander")
    InitMainFrame()
    ConfigFrame = CreateConfigFrame(function() MC:RefreshUI() end)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshUI")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshUI")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshUI")
    print("|cFFFFFFFFMacro Commander is now loaded - use |cFF1A9FCF/macroc help|cFFFFFFFF for commands|r")
end

function MC:OnEnable()
    self:RefreshUI()
end

local function PrintMCHelp()
    print("|cFF00FF00--- Macro Commander (MC) Help ---|r")
    print("|cFF1A9FCF/macroc|r - Opens Config")
    print("|cFF1A9FCF/macroc on/off|r - show/hides main window")
    print("|cFF1A9FCF/macroc toggle|r - toggles main window")
    print("|cFF1A9FCF/macroc resetpos|r - resets windows to center of screen")
end

SLASH_MACROC1 = "/macroc"
SlashCmdList["MACROC"] = function(msg)
    local db = MC.db.profile
    local cmd = string.gsub(msg or "", "%s+", "")
    cmd = string.lower(cmd)
    if cmd == "resetpos" then ResetWindowPositions()
    elseif cmd == "help" then PrintMCHelp()
    elseif cmd == "toggle" or cmd == "on" or cmd == "off" then 
        if cmd == "on" then MainFrame:Show(); db.visible = true
        elseif cmd == "off" then MainFrame:Hide(); db.visible = false
        else
            if MainFrame:IsShown() then MainFrame:Hide(); db.visible = false
            else MainFrame:Show(); db.visible = true end
        end
    else
        if cmd == "" then
            if ConfigFrame and ConfigFrame:IsShown() then ConfigFrame:Hide()
            elseif ConfigFrame then ConfigFrame:Show() end
        else PrintMCHelp() end
    end
end
--end of MacroCommander.lua (Box 14 of 14)
