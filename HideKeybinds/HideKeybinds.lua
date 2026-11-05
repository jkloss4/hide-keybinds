-- Hide Keybinds: hides the keybind text on the action bars' buttons, bar by bar, with a key that shows it again
-- while held. Only the text's alpha changes, so it works in combat and Blizzard's own code keeps setting the text
-- (and the range dot's red/white color) as usual.

local _, ns = ...

local DEFAULTS = {
    enabled = true,
    hideRangeDot = false,
    bars = {},
}

-- Each bar as Edit Mode names it, with its buttons (name prefix and count). Bars a client doesn't have are left out
-- of the options.
local BARS = {
    { key = "bar1", label = "Action Bar 1", buttons = { { "ActionButton", 12 } } },
    { key = "bar2", label = "Action Bar 2", buttons = { { "MultiBarBottomLeftButton", 12 } } },
    { key = "bar3", label = "Action Bar 3", buttons = { { "MultiBarBottomRightButton", 12 } } },
    { key = "bar4", label = "Action Bar 4", buttons = { { "MultiBarRightButton", 12 } } },
    { key = "bar5", label = "Action Bar 5", buttons = { { "MultiBarLeftButton", 12 } } },
    { key = "bar6", label = "Action Bar 6", buttons = { { "MultiBar5Button", 12 } } },
    { key = "bar7", label = "Action Bar 7", buttons = { { "MultiBar6Button", 12 } } },
    { key = "bar8", label = "Action Bar 8", buttons = { { "MultiBar7Button", 12 } } },
    { key = "pet", label = "Pet Bar", buttons = { { "PetActionButton", 10 } } },
    { key = "stance", label = "Stance Bar", buttons = { { "StanceButton", 10 } } },
    { key = "totem", label = "Totem Bar", buttons = { { "MultiCastActionButton", 12 } } },
    { key = "vehicle", label = "Vehicle and Possess Bars",
        buttons = { { "OverrideActionBarButton", 6 }, { "PossessButton", 2 } } },
    { key = "extra", label = "Extra Action Button", buttons = { { "ExtraActionButton", 1 } } },
}

local function DB()
    return HideKeybindsDB
end

-- Every bar starts hidden; a bar the player turns off is saved as false.
local function BarHidden(key)
    return DB().bars[key] ~= false
end

local function HotKeyOf(button)
    return button.HotKey or _G[button:GetName() .. "HotKey"]
end

-- The bar's buttons that exist on this client (and have keybind text).
local function Buttons(bar)
    local list = {}
    for _, group in ipairs(bar.buttons) do
        local prefix, count = group[1], group[2]
        for i = 1, count do
            local button = _G[prefix .. i]
            if button and HotKeyOf(button) then
                list[#list + 1] = button
            end
        end
    end
    return list
end

local function BarExists(bar)
    return #Buttons(bar) > 0
end

-- Held down: the binding below (or the options page's key) shows every keybind until it's let go.
local peeking = false

-- A button without a keybind shows Blizzard's range dot in the same text: it turns red when the target is out of
-- range for that button's action.
local function IsRangeDot(hotKey)
    local text = hotKey:GetText()
    return text == nil or text == "" or text == RANGE_INDICATOR
end

local function UpdateBar(bar)
    local hideBar = DB().enabled and BarHidden(bar.key) and not peeking
    for _, button in ipairs(Buttons(bar)) do
        local hotKey = HotKeyOf(button)
        local hide = hideBar and (DB().hideRangeDot or not IsRangeDot(hotKey))
        hotKey:SetAlpha(hide and 0 or 1)
    end
end

local function UpdateAll()
    if not DB() then return end
    for _, bar in ipairs(BARS) do UpdateBar(bar) end
end

-- Called by the key binding (Bindings.xml) with "down" and "up".
function HideKeybinds_Peek(keystate)
    local held = keystate == "down"
    if held ~= peeking then
        peeking = held
        UpdateAll()
    end
end

BINDING_HEADER_HIDEKEYBINDS = "Hide Keybinds"
BINDING_NAME_HIDEKEYBINDS_PEEK = "Show Keybinds While Held"
local PEEK_ACTION = "HIDEKEYBINDS_PEEK"

---------------------------------------------------------------------------
-- Options page (Options > AddOns > Hide Keybinds), drawn in Blizzard's settings style by SettingsKit
---------------------------------------------------------------------------
local Kit = ns.SettingsKit

local page = Kit.NewPage("Hide Keybinds", {
    onDefaults = function()
        HideKeybindsDB = CopyTable(DEFAULTS)
        UpdateAll()
    end,
})

local function Enabled()
    return DB().enabled
end

local needsEnabled = {
    indent = true,
    enabled = Enabled,
    disabledTooltip = "Turn on Hide Keybinds first.",
}

page:Header("General")
page:Checkbox("Hide Keybinds",
    function() return DB().enabled end,
    function(value)
        DB().enabled = value
        UpdateAll()
        page:Refresh()
    end,
    "Hide the keybind text on the action bars chosen below. Turn this off to show every keybind again.")
page:Checkbox("Hide the Range Dot",
    function() return DB().hideRangeDot end,
    function(value)
        DB().hideRangeDot = value
        UpdateAll()
    end,
    "Buttons without a keybind show a small dot where the keybind would be. It turns red when your target is out "
        .. "of range for that button. Turn this on to hide the dot too.", needsEnabled)

-- The hold-to-show key: click the button, then press a key (with Shift, Ctrl or Alt if wanted). Escape cancels;
-- right-click clears it. It's the same binding as Keybindings > AddOns > Hide Keybinds.
local function PeekKeyText()
    local key = GetBindingKey(PEEK_ACTION)
    return key and GetBindingText(key) or (NOT_BOUND or "Not Bound")
end

local keyRow = page:ButtonRow("Show Keybinds While Held", PeekKeyText(), function() end,
    "Choose a key that shows every keybind while you hold it down. Click, then press the key (with Shift, Ctrl or "
        .. "Alt if you like). Escape cancels; right-click clears the key. It's also in Options > Keybindings > "
        .. "AddOns.")
local keyButton = keyRow.Button
local listening = false

local function StopListening()
    listening = false
    keyButton:EnableKeyboard(false)
    keyButton:UnlockHighlight()
    keyButton:SetText(PeekKeyText())
end

local function SetPeekKey(key)
    if InCombatLockdown() then
        print("|cffffd100Hide Keybinds:|r key bindings can't be changed in combat.")
        return
    end
    -- the key's old action loses it, as on Blizzard's Keybindings page; say so
    local old = key and GetBindingAction(key)
    if old and old ~= "" and old ~= PEEK_ACTION then
        print(("|cffffd100Hide Keybinds:|r %s was bound to %s; it now shows keybinds while held.")
            :format(GetBindingText(key), GetBindingName(old)))
    end
    -- one key at a time: clear the old ones first
    local key1, key2 = GetBindingKey(PEEK_ACTION)
    if key1 then SetBinding(key1) end
    if key2 then SetBinding(key2) end
    if key then SetBinding(key, PEEK_ACTION) end
    SaveBindings(GetCurrentBindingSet())
end

local function OnBindingInput(input)
    if input == "ESCAPE" then
        StopListening()
        return
    end
    if IsKeyPressIgnoredForBinding(input) or IsMetaKey(input) then
        return -- keep listening until the real key comes with its Shift/Ctrl/Alt
    end
    SetPeekKey(CreateKeyChordStringUsingMetaKeyState(input))
    StopListening()
end

keyButton:RegisterForClicks("AnyUp")
keyButton:SetScript("OnClick", function(self, button)
    if listening then
        -- left and right click are the button's own; other mouse buttons can be the key
        if button ~= "LeftButton" and button ~= "RightButton" then
            OnBindingInput(GetConvertedKeyOrButton(button))
        else
            StopListening()
        end
        return
    end
    if button == "RightButton" then
        SetPeekKey(nil)
        self:SetText(PeekKeyText())
        return
    end
    if InCombatLockdown() then return end
    listening = true
    self:SetText("Press a Key")
    self:LockHighlight()
    self:EnableKeyboard(true)
    self:SetPropagateKeyboardInput(false)
end)
keyButton:SetScript("OnKeyDown", function(_, key)
    if listening then OnBindingInput(key) end
end)
keyButton:SetScript("OnHide", function()
    if listening then StopListening() end
end)
page:OnRefresh(function()
    if not listening then keyButton:SetText(PeekKeyText()) end
end)

page:Header("Action Bars")
for _, bar in ipairs(BARS) do
    if BarExists(bar) then
        page:Checkbox(bar.label,
            function() return BarHidden(bar.key) end,
            function(value)
                DB().bars[bar.key] = value
                UpdateBar(bar)
            end,
            ("Hide the keybinds on the %s."):format(bar.label), needsEnabled)
    end
end
Kit.Register(page)

SLASH_HIDEKEYBINDS1 = "/hidekeybinds"
SlashCmdList.HIDEKEYBINDS = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "on" or msg == "off" then
        DB().enabled = msg == "on"
        UpdateAll()
        page:Refresh()
        print(("|cffffd100Hide Keybinds:|r %s."):format(msg))
    else
        Kit.Open(page)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UPDATE_BINDINGS")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= "HideKeybinds" then return end
        HideKeybindsDB = HideKeybindsDB or {}
        for key, value in pairs(DEFAULTS) do
            if HideKeybindsDB[key] == nil then
                HideKeybindsDB[key] = type(value) == "table" and CopyTable(value) or value
            end
        end
    elseif event == "UPDATE_BINDINGS" then
        -- a button gaining or losing a keybind swaps its text with the range dot: Blizzard's buttons update theirs on
        -- this same event, so look once they have
        C_Timer.After(0, UpdateAll)
        if page.frame:IsShown() and not listening then keyButton:SetText(PeekKeyText()) end
    else
        UpdateAll()
    end
end)
