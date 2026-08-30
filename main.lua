--!nonstrict

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Clean Dark Palette (Potassium / Minimalist Slate Theme)
local COLORS = {
    Canvas = Color3.fromRGB(8, 8, 10),
    Sidebar = Color3.fromRGB(12, 12, 15),
    Surface = Color3.fromRGB(16, 16, 20),
    SurfaceRaised = Color3.fromRGB(22, 22, 28),
    SurfaceHover = Color3.fromRGB(30, 30, 38),

    Border = Color3.fromRGB(40, 40, 50),
    BorderSoft = Color3.fromRGB(25, 25, 32),

    Text = Color3.fromRGB(238, 238, 242),
    TextMuted = Color3.fromRGB(150, 150, 165),
    TextDim = Color3.fromRGB(95, 95, 110),

    Accent = Color3.fromRGB(0, 110, 254),
    AccentHover = Color3.fromRGB(30, 130, 255),
    AccentSoft = Color3.fromRGB(15, 35, 65),

    Green = Color3.fromRGB(48, 195, 110),
    Amber = Color3.fromRGB(240, 175, 55),
    Red = Color3.fromRGB(240, 75, 90),

    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local ICONS = {
    Close = "rbxassetid://116396312853810",
    Sparkles = "rbxassetid://105634041692696",
    Cleaner = "rbxassetid://126010725826757",
    Team = "rbxassetid://85332511060401",
    CheckAll = "rbxassetid://101885204738917",
    Clear = "rbxassetid://111132030834422",
    Filter = "rbxassetid://83186010624431",
    Settings = "rbxassetid://109485777305919",
    Flask = "rbxassetid://115528123394259",
    Terminal = "rbxassetid://102379915564176",
    Shield = "rbxassetid://71867984579031",
    Ghost = "rbxassetid://132705178126217",
    Check = "rbxassetid://86817768619372",
    Wand = "rbxassetid://115623066336607",
    User = "rbxassetid://114567720540659",
    Macro = "rbxassetid://117978552190904",
    Record = "rbxassetid://122878673716704",
    Play = "rbxassetid://76386816441302",
    Save = "rbxassetid://122894934359450",
    Clipboard = "rbxassetid://85387882337161",
    Upload = "rbxassetid://118488857289315",
    Plus = "rbxassetid://101123124881873",
    Clock = "rbxassetid://136533241128438",
}

local RARITY_COLORS = {
    Secret = Color3.fromRGB(255, 55, 95),
    Mythic = Color3.fromRGB(180, 70, 255),
    Limited = Color3.fromRGB(0, 180, 255),
    Legendary = Color3.fromRGB(250, 175, 50),
    Epic = Color3.fromRGB(145, 90, 255),
    Rare = Color3.fromRGB(50, 140, 255),
    Unknown = COLORS.TextDim,
}

local FONT_BOLD = Font.fromName("BuilderSans", Enum.FontWeight.Bold)
local FONT_SEMIBOLD = Font.fromName("BuilderSans", Enum.FontWeight.SemiBold)
local FONT_MEDIUM = Font.fromName("BuilderSans", Enum.FontWeight.Medium)
local FONT_MONO = Font.fromName("Code", Enum.FontWeight.Medium)

local TWEEN_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_NORMAL = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local UIModule = {
    ApiVersion = 2,
    Backend = "external",
    CurrentTab = "Evolve",
    IsOpen = false,
    Connections = {},
    SelectedEvoUnits = {},
    SelectedSellUnits = {},
    SellFilters = { Rare = true, Epic = true, Legendary = false, Mythic = false },
    Callbacks = {},
    CachedEvoCandidates = {},
    CachedSellUnits = {},
    MacroProfiles = {},
    SelectedMacroProfile = nil,
    MacroNameInput = nil,
    MacroImportInput = nil,
    _SetRecordToggle = nil,
    _SetPlayToggle = nil,
    _MacroStatusValues = nil,
    _MacroWaitingLabel = nil,
    _MacroProfileSelectorLabel = nil,
    _MacroProfilesSubtitle = nil,
}

-- UI Building Helpers
local function create(className, properties, parent)
    local instance = Instance.new(className)
    if properties then
        for property, value in pairs(properties) do
            local ok, err = pcall(function()
                instance[property] = value
            end)
            if not ok then
                warn(string.format("[Garban UI create Error] Failed to set %s.%s: %s", className, tostring(property), tostring(err)))
            end
        end
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function addCorner(target, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, target)
end

local function addStroke(target, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or COLORS.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, target)
end

local function makeLabel(parent, text, size, color, font, alignment)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or COLORS.Text,
        TextSize = size or 13,
        FontFace = font or FONT_MEDIUM,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function makeIcon(parent, asset, size, color)
    return create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = asset,
        ImageColor3 = color or COLORS.Text,
        Size = UDim2.fromOffset(size or 16, size or 16),
        ScaleType = Enum.ScaleType.Fit,
    }, parent)
end

local function bindHover(button, normalColor, hoverColor, stroke, normalStroke, hoverStroke)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TWEEN_FAST, { BackgroundColor3 = hoverColor }):Play()
        if stroke and hoverStroke then
            TweenService:Create(stroke, TWEEN_FAST, { Color = hoverStroke }):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TWEEN_FAST, { BackgroundColor3 = normalColor }):Play()
        if stroke and normalStroke then
            TweenService:Create(stroke, TWEEN_FAST, { Color = normalStroke }):Play()
        end
    end)
end

local function clearGuiRows(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function countSelected(selection)
    local count = 0
    for _, selected in pairs(selection) do
        if selected then count = count + 1 end
    end
    return count
end

local function createPanel(parent, position, size, title, subtitle, iconAsset, accent)
    local panel = create("Frame", {
        Position = position,
        Size = size,
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, parent)
    addCorner(panel, 10)
    addStroke(panel, COLORS.BorderSoft, 0.1, 1)

    local iconBack = create("Frame", {
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, panel)
    addCorner(iconBack, 7)
    local icon = makeIcon(iconBack, iconAsset, 14, accent or COLORS.Accent)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    local titleLabel = makeLabel(panel, title, 13, COLORS.Text, FONT_SEMIBOLD)
    titleLabel.Position = UDim2.fromOffset(50, 9)
    titleLabel.Size = UDim2.new(1, -64, 0, 19)

    local subtitleLabel = makeLabel(panel, subtitle, 10, COLORS.TextDim, FONT_MEDIUM)
    subtitleLabel.Position = UDim2.fromOffset(50, 27)
    subtitleLabel.Size = UDim2.new(1, -64, 0, 15)

    create("Frame", {
        Position = UDim2.fromOffset(14, 52),
        Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = COLORS.BorderSoft,
        BorderSizePixel = 0,
    }, panel)

    local body = create("Frame", {
        Position = UDim2.fromOffset(14, 62),
        Size = UDim2.new(1, -28, 1, -74),
        BackgroundTransparency = 1,
    }, panel)
    return panel, body, titleLabel, subtitleLabel
end

local function createScroll(parent)
    local scroll = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Border,
        ScrollBarImageTransparency = 0.2,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
    }, parent)
    local layout = create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
    table.insert(UIModule.Connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 4)
    end))
    return scroll, layout
end

local function createActionButton(parent, text, iconAsset, color)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, parent)
    addCorner(button, 8)
    local icon = makeIcon(button, iconAsset, 15, COLORS.White)
    icon.Position = UDim2.fromOffset(14, 12)
    local label = makeLabel(button, text, 12, COLORS.White, FONT_BOLD, Enum.TextXAlignment.Center)
    label.Position = UDim2.fromOffset(36, 0)
    label.Size = UDim2.new(1, -50, 1, 0)
    bindHover(button, color, color:Lerp(COLORS.White, 0.12))
    return button, label
end

local function createMiniButton(parent, text, iconAsset, position, size)
    local button = create("TextButton", {
        Position = position,
        Size = size,
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, parent)
    addCorner(button, 7)
    local stroke = addStroke(button, COLORS.BorderSoft, 0.15, 1)
    local icon = makeIcon(button, iconAsset, 13, COLORS.TextMuted)
    icon.Position = UDim2.fromOffset(10, 9)
    local label = makeLabel(button, text, 10, COLORS.TextMuted, FONT_SEMIBOLD)
    label.Position = UDim2.fromOffset(28, 0)
    label.Size = UDim2.new(1, -34, 1, 0)
    bindHover(button, COLORS.SurfaceRaised, COLORS.SurfaceHover, stroke, COLORS.BorderSoft, COLORS.Accent)
    return button, label
end

local function makeSelectionIndicator(parent, selected, accent)
    local circle = create("Frame", {
        Position = UDim2.new(1, -34, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = selected and accent or COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, parent)
    addCorner(circle, 10)
    addStroke(circle, selected and accent or COLORS.BorderSoft, selected and 0.2 or 0.1, 1)
    if selected then
        local check = makeIcon(circle, ICONS.Check, 11, COLORS.White)
        check.AnchorPoint = Vector2.new(0.5, 0.5)
        check.Position = UDim2.fromScale(0.5, 0.5)
    end
end

local function pruneSelection(selection, values, canSelect)
    local valid = {}
    for _, value in ipairs(values) do
        if not canSelect or canSelect(value) then
            valid[tostring(value.Id)] = true
        end
    end
    for id in pairs(selection) do
        if not valid[tostring(id)] then
            selection[id] = nil
        end
    end
end

-- ScreenGui & Main Frame Setup
local screenGui = create("ScreenGui", {
    Name = "GarbanControlCenter",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 80,
}, nil)

local parentTarget = CoreGui
if typeof(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and typeof(result) == "Instance" then
        parentTarget = result
    end
end

local parented = pcall(function()
    screenGui.Parent = parentTarget
end)

if not parented or not screenGui.Parent then
    local pgui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pgui and LocalPlayer then
        pcall(function() pgui = LocalPlayer:WaitForChild("PlayerGui", 3) end)
    end
    screenGui.Parent = pgui or CoreGui
end

local mainShadow = create("Frame", {
    Name = "Shadow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 8),
    Size = UDim2.fromOffset(916, 576),
    BackgroundColor3 = COLORS.Black,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Visible = false,
}, screenGui)
addCorner(mainShadow, 20)

local mainFrame = create("CanvasGroup", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(900, 560),
    BackgroundColor3 = COLORS.Canvas,
    BorderSizePixel = 0,
    GroupTransparency = 1,
    Visible = false,
    ClipsDescendants = true,
}, screenGui)
addCorner(mainFrame, 14)
addStroke(mainFrame, COLORS.Border, 0.1, 1)

local uiScale = create("UIScale", { Scale = 1 }, mainFrame)
local shadowScale = create("UIScale", { Scale = 1 }, mainShadow)

local function updateResponsiveScale()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local scale = math.clamp(math.min((viewport.X - 32) / 900, (viewport.Y - 32) / 560), 0.68, 1)
    uiScale.Scale = scale
    shadowScale.Scale = scale
end

local function bindCurrentCamera()
    local camera = Workspace.CurrentCamera
    if camera then
        table.insert(UIModule.Connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
    end
    updateResponsiveScale()
end
bindCurrentCamera()
table.insert(UIModule.Connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCurrentCamera))

-- Forward Declarations of Global Elements
local pageTitle, pageSubtitle
local tabButtons = {}
local tabViews = {}
local evoActionButton, evoActionLabel
local sellActionButton, sellActionLabel, selectedCountLabel
local evoListScroll, evoListSubtitle
local sellListScroll, sellListSubtitle, filterContainer
local materialScroll, materialSubtitle
local teamCard
local logBox

local pageMeta = {
    Evolve = { Title = "Evolution Lab", Subtitle = "Plan materials and evolve your strongest unit safely." },
    Sell = { Title = "Unit Cleaner", Subtitle = "Review inventory, apply rarity filters, and sell with safeguards." },
    Team = { Title = "Automation", Subtitle = "Control runtime modules used by the current session." },
    Macro = { Title = "Macro Studio", Subtitle = "Record confirmed actions, manage profiles, and replay safely." },
}

local evoBusy, sellBusy = false, false
local function refreshSelectionLabels()
    local evoCount = countSelected(UIModule.SelectedEvoUnits)
    if evoActionLabel then
        evoActionLabel.Text = evoBusy and "Processing evolution plan..."
            or (evoCount > 0 and string.format("Craft & evolve selected (%d)", evoCount) or "Craft & evolve ready units")
    end
    local sellCount = countSelected(UIModule.SelectedSellUnits)
    if selectedCountLabel then
        selectedCountLabel.Text = tostring(sellCount)
    end
    if sellActionLabel then
        sellActionLabel.Text = sellBusy and "Waiting for confirmation..." or string.format("Sell selected (%d)", sellCount)
    end
end

local refreshRunning, refreshPending = false, false
local function requestRefresh()
    if refreshRunning then
        refreshPending = true
        return
    end
    refreshRunning = true
    task.spawn(function()
        repeat
            refreshPending = false
            local callback = UIModule.Callbacks.OnRefresh
            if callback then
                local ok, err = pcall(callback)
                if not ok then warn("[UI] Refresh failed: " .. tostring(err)) end
            end
        until not refreshPending
        refreshRunning = false
    end)
end

function UIModule:SetState(open)
    self.IsOpen = open == true
    if self.IsOpen then
        mainFrame.Visible = true
        mainShadow.Visible = true
        mainFrame.Size = UDim2.fromOffset(872, 542)
        mainFrame.GroupTransparency = 1
        mainShadow.BackgroundTransparency = 1
        TweenService:Create(mainFrame, TWEEN_NORMAL, { Size = UDim2.fromOffset(900, 560), GroupTransparency = 0 }):Play()
        TweenService:Create(mainShadow, TWEEN_NORMAL, { BackgroundTransparency = 0.35 }):Play()
        requestRefresh()
    else
        TweenService:Create(mainFrame, TWEEN_FAST, { GroupTransparency = 1 }):Play()
        TweenService:Create(mainShadow, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
        task.delay(TWEEN_FAST.Time, function()
            if not self.IsOpen then
                mainFrame.Visible = false
                mainShadow.Visible = false
            end
        end)
    end
end

function UIModule:SwitchTab(tabName)
    if not pageMeta[tabName] then return end
    self.CurrentTab = tabName
    if pageTitle then pageTitle.Text = pageMeta[tabName].Title end
    if pageSubtitle then pageSubtitle.Text = pageMeta[tabName].Subtitle end
    for name, tab in pairs(tabButtons) do
        local active = name == tabName
        TweenService:Create(tab.Button, TWEEN_FAST, { BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar }):Play()
        TweenService:Create(tab.Stroke, TWEEN_FAST, { Color = active and COLORS.Border or COLORS.Sidebar, Transparency = active and 0.2 or 1 }):Play()
        TweenService:Create(tab.Indicator, TWEEN_FAST, { BackgroundTransparency = active and 0 or 1 }):Play()
        TweenService:Create(tab.IconBack, TWEEN_FAST, { BackgroundColor3 = active and COLORS.AccentSoft or COLORS.Surface }):Play()
        TweenService:Create(tab.Icon, TWEEN_FAST, { ImageColor3 = active and COLORS.Accent or COLORS.TextMuted }):Play()
        TweenService:Create(tab.Title, TWEEN_FAST, { TextColor3 = active and COLORS.Text or COLORS.TextMuted }):Play()
    end
    for name, view in pairs(tabViews) do
        view.Visible = name == tabName
    end
    requestRefresh()
end

function UIModule:AppendLog(message)
    if not logBox then return end
    local lines = string.split(logBox.Text, "\n")
    if #lines == 1 and lines[1] == "Ready. Waiting for an action..." then
        table.clear(lines)
    end
    while #lines >= 6 do
        table.remove(lines, 1)
    end
    table.insert(lines, string.format("[%s] %s", os.date("%H:%M:%S"), tostring(message)))
    logBox.Text = table.concat(lines, "\n")
end

function UIModule:UpdateMacroState(state)
    local s = state or {}
    local values = self._MacroStatusValues or {}
    for _, key in ipairs({ "Status", "Action", "Type", "Unit" }) do
        if values[key] then
            values[key].Text = tostring(s[key] or (key == "Unit" and "—" or "None"))
        end
    end
    if values.Status then
        local status = tostring(s.Status or "Idle")
        values.Status.TextColor3 = status == "Recording" and COLORS.Red
            or status == "Playing" and COLORS.Green
            or COLORS.Text
    end
    if self._MacroWaitingLabel then
        self._MacroWaitingLabel.Text = "Waiting for: " .. tostring(s.WaitingFor or "Idle")
    end
    if s.MacroName and s.MacroName ~= "" and self.MacroNameInput and not self.MacroNameInput:IsFocused() then
        self.MacroNameInput.Text = tostring(s.MacroName)
    end
    if tostring(s.Status) ~= "Recording" and self._SetRecordToggle then
        self._SetRecordToggle(false, true)
    end
    if tostring(s.Status) ~= "Playing" and self._SetPlayToggle then
        self._SetPlayToggle(false, true)
    end
end

function UIModule:UpdateMacroProfiles(profiles, selected)
    self.MacroProfiles = {}
    for _, profile in ipairs(profiles or {}) do
        table.insert(self.MacroProfiles, tostring(profile))
    end
    table.sort(self.MacroProfiles, function(a, b) return a:lower() < b:lower() end)
    local explicitSelection = selected and tostring(selected) or nil
    self.SelectedMacroProfile = explicitSelection or self.SelectedMacroProfile
    if not explicitSelection and not table.find(self.MacroProfiles, self.SelectedMacroProfile) then
        self.SelectedMacroProfile = self.MacroProfiles[1]
    end
    local label = self.SelectedMacroProfile or "Select profile..."
    if self._MacroProfileSelectorLabel then
        self._MacroProfileSelectorLabel.Text = label
    end
    if self._MacroProfilesSubtitle then
        self._MacroProfilesSubtitle.Text = #self.MacroProfiles == 0 and "No profiles found"
            or string.format("%d profile(s) · selected %s", #self.MacroProfiles, label)
    end
    if self.MacroNameInput and self.SelectedMacroProfile and not self.MacroNameInput:IsFocused() then
        self.MacroNameInput.Text = self.SelectedMacroProfile
    end
end

local TOGGLE_DESCRIPTIONS = {
    Craft = "Synthesize missing evolution materials with replica confirmation.",
    Evolve = "Evolve the best eligible candidate when every requirement is ready.",
    Trial = "Launch the matching unit trial when only its quest item is missing.",
    Cleaner = "Remove safe duplicates when inventory pressure reaches the threshold.",
    Summon = "Use the standard banner automation while it is enabled.",
    Lobby = "Return safely when configured Sprite Grey cap is reached.",
    HINAHUB = "Start external HinaHub automation module in lobby.",
}

local function getToggleDescription(name)
    for key, description in pairs(TOGGLE_DESCRIPTIONS) do
        if name:find(key, 1, true) then return description end
    end
    return "Enable or disable this runtime module for the current session."
end

function UIModule:CreateToggle(name, defaultState, isAccentViolet, onToggle)
    local active = defaultState == true
    local accent = COLORS.Accent
    local row = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, teamCard)
    addCorner(row, 8)
    local rowStroke = addStroke(row, active and COLORS.Border or COLORS.BorderSoft, active and 0.25 or 0.15, 1)

    local iconBack = create("Frame", {
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(38, 38),
        BackgroundColor3 = active and COLORS.AccentSoft or COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, row)
    addCorner(iconBack, 7)
    local rowIcon = makeIcon(iconBack, ICONS.Settings, 16, active and accent or COLORS.TextDim)
    rowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    rowIcon.Position = UDim2.fromScale(0.5, 0.5)

    local title = makeLabel(row, name, 12, active and COLORS.Text or COLORS.TextMuted, FONT_SEMIBOLD)
    title.Position = UDim2.fromOffset(58, 8)
    title.Size = UDim2.new(1, -120, 0, 18)

    local description = makeLabel(row, getToggleDescription(name), 10, COLORS.TextDim, FONT_MEDIUM)
    description.Position = UDim2.fromOffset(58, 28)
    description.Size = UDim2.new(1, -120, 0, 16)

    local switch = create("Frame", {
        Position = UDim2.new(1, -52, 0.5, -12),
        Size = UDim2.fromOffset(42, 24),
        BackgroundColor3 = active and accent or COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, row)
    addCorner(switch, 12)
    addStroke(switch, active and accent or COLORS.Border, active and 0.2 or 0.1, 1)

    local knob = create("Frame", {
        Position = active and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = active and COLORS.White or COLORS.TextDim,
        BorderSizePixel = 0,
    }, switch)
    addCorner(knob, 9)

    local function render()
        TweenService:Create(row, TWEEN_FAST, { BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar }):Play()
        TweenService:Create(rowStroke, TWEEN_FAST, { Color = active and COLORS.Border or COLORS.BorderSoft }):Play()
        TweenService:Create(iconBack, TWEEN_FAST, { BackgroundColor3 = active and COLORS.AccentSoft or COLORS.SurfaceRaised }):Play()
        TweenService:Create(rowIcon, TWEEN_FAST, { ImageColor3 = active and accent or COLORS.TextDim }):Play()
        TweenService:Create(title, TWEEN_FAST, { TextColor3 = active and COLORS.Text or COLORS.TextMuted }):Play()
        TweenService:Create(switch, TWEEN_FAST, { BackgroundColor3 = active and accent or COLORS.SurfaceRaised }):Play()
        TweenService:Create(knob, TWEEN_FAST, { Position = active and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = active and COLORS.White or COLORS.TextDim }):Play()
    end

    row.Activated:Connect(function()
        local previous = active
        active = not active
        if onToggle then
            local ok, err = pcall(onToggle, active)
            if not ok then
                active = previous
                warn("[UI] Toggle failed: " .. tostring(err))
            end
        end
        render()
    end)
    return row
end

function UIModule:UpdateMaterials(materials)
    if not materialScroll then return end
    clearGuiRows(materialScroll)
    local sorted = table.clone(materials or {})
    table.sort(sorted, function(a, b)
        if (a.Deficit or 0) ~= (b.Deficit or 0) then return (a.Deficit or 0) > (b.Deficit or 0) end
        return tostring(a.DisplayName) < tostring(b.DisplayName)
    end)
    if materialSubtitle then
        materialSubtitle.Text = string.format("%d tracked requirements", #sorted)
    end
    if #sorted == 0 then
        local empty = makeLabel(materialScroll, "No materials required yet.", 11, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center)
        empty.Size = UDim2.new(1, 0, 0, 44)
        return
    end
    for order, material in ipairs(sorted) do
        local current, needed = tonumber(material.Current) or 0, tonumber(material.Needed) or 0
        local deficit = tonumber(material.Deficit) or math.max(0, needed - current)
        local ready = deficit <= 0
        local row = create("Frame", { Size = UDim2.new(1, -3, 0, 44), BackgroundColor3 = COLORS.Sidebar, BorderSizePixel = 0, LayoutOrder = order }, materialScroll)
        addCorner(row, 8)
        addStroke(row, ready and COLORS.Green or COLORS.BorderSoft, ready and 0.5 or 0.15, 1)

        local name = makeLabel(row, tostring(material.DisplayName or "Material"), 11, COLORS.Text, FONT_SEMIBOLD)
        name.Position = UDim2.fromOffset(10, 5)
        name.Size = UDim2.new(0.62, -10, 0, 18)

        local amount = makeLabel(row, string.format("%d / %d", current, needed), 10, COLORS.TextMuted, FONT_MEDIUM, Enum.TextXAlignment.Right)
        amount.Position = UDim2.new(0.62, 0, 0, 5)
        amount.Size = UDim2.new(0.38, -10, 0, 18)

        local track = create("Frame", { Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 4), BackgroundColor3 = COLORS.SurfaceRaised, BorderSizePixel = 0 }, row)
        addCorner(track, 2)
        local ratio = needed > 0 and math.clamp(current / needed, 0, 1) or 1
        local fill = create("Frame", { Size = UDim2.new(ratio, 0, 1, 0), BackgroundColor3 = ready and COLORS.Green or COLORS.Accent, BorderSizePixel = 0 }, track)
        addCorner(fill, 2)
    end
end

function UIModule:UpdateEvoList(candidates)
    self.CachedEvoCandidates = candidates or {}
    pruneSelection(self.SelectedEvoUnits, self.CachedEvoCandidates)
    if not evoListScroll then return end
    clearGuiRows(evoListScroll)
    if evoListSubtitle then
        evoListSubtitle.Text = string.format("%d eligible unit%s", #self.CachedEvoCandidates, #self.CachedEvoCandidates == 1 and "" or "s")
    end
    if #self.CachedEvoCandidates == 0 then
        local empty = makeLabel(evoListScroll, "No evolution candidate is ready.", 11, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center)
        empty.Size = UDim2.new(1, -3, 0, 60)
        refreshSelectionLabels()
        return
    end
    for order, unit in ipairs(self.CachedEvoCandidates) do
        local id, rarity = tostring(unit.Id), tostring(unit.Rarity or "Unknown")
        local selected, rarityColor = self.SelectedEvoUnits[id] == true, RARITY_COLORS[rarity] or COLORS.TextDim
        local row = create("TextButton", {
            Size = UDim2.new(1, -3, 0, 54),
            BackgroundColor3 = selected and COLORS.SurfaceHover or COLORS.Sidebar,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = order,
        }, evoListScroll)
        addCorner(row, 8)
        local rowStroke = addStroke(row, selected and COLORS.Accent or COLORS.BorderSoft, selected and 0.25 or 0.15, 1)

        local accent = create("Frame", { Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(3, 34), BackgroundColor3 = rarityColor, BorderSizePixel = 0 }, row)
        addCorner(accent, 2)

        local name = makeLabel(row, string.format("%s  ·  Lv.%d", tostring(unit.DisplayName or unit.Asset or "Unit"), tonumber(unit.Level) or 1), 11, COLORS.Text, FONT_SEMIBOLD)
        name.Position = UDim2.fromOffset(12, 7)
        name.Size = UDim2.new(1, -52, 0, 18)

        local detail = makeLabel(row, string.format("%s  /  %s  /  %d materials", rarity:upper(), tostring(unit.Trait or "No Trait"), tonumber(unit.ReqCount) or 0), 9, rarityColor, FONT_MEDIUM)
        detail.Position = UDim2.fromOffset(12, 27)
        detail.Size = UDim2.new(1, -52, 0, 16)

        makeSelectionIndicator(row, selected, COLORS.Accent)
        bindHover(row, selected and COLORS.SurfaceHover or COLORS.Sidebar, COLORS.SurfaceHover, rowStroke, selected and COLORS.Accent or COLORS.BorderSoft, COLORS.Accent)
        row.Activated:Connect(function()
            if UIModule.SelectedEvoUnits[id] then
                UIModule.SelectedEvoUnits[id] = nil
            else
                UIModule.SelectedEvoUnits[id] = true
            end
            refreshSelectionLabels()
            UIModule:UpdateEvoList(UIModule.CachedEvoCandidates)
        end)
    end
    refreshSelectionLabels()
end

local function setupFilters()
    if not filterContainer then return end
    clearGuiRows(filterContainer)
    for layoutOrder, rarity in ipairs({ "Rare", "Epic", "Legendary", "Mythic" }) do
        local active, rarityColor = UIModule.SellFilters[rarity] == true, RARITY_COLORS[rarity] or COLORS.TextMuted
        local button = create("TextButton", {
            BackgroundColor3 = active and COLORS.SurfaceHover or COLORS.Sidebar,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = layoutOrder,
        }, filterContainer)
        addCorner(button, 8)
        local stroke = addStroke(button, active and rarityColor or COLORS.BorderSoft, active and 0.35 or 0.15, 1)
        local dot = create("Frame", { Position = UDim2.fromOffset(10, 13), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = active and rarityColor or COLORS.TextDim, BorderSizePixel = 0 }, button)
        addCorner(dot, 4)
        local label = makeLabel(button, rarity, 10, active and COLORS.Text or COLORS.TextMuted, FONT_SEMIBOLD)
        label.Position = UDim2.fromOffset(24, 0)
        label.Size = UDim2.new(1, -30, 1, 0)
        bindHover(button, active and COLORS.SurfaceHover or COLORS.Sidebar, COLORS.SurfaceHover, stroke, active and rarityColor or COLORS.BorderSoft, rarityColor)
        button.Activated:Connect(function()
            UIModule.SellFilters[rarity] = not UIModule.SellFilters[rarity]
            table.clear(UIModule.SelectedSellUnits)
            setupFilters()
            UIModule:UpdateSellList(UIModule.CachedSellUnits)
        end)
    end
end

function UIModule:UpdateSellList(units)
    self.CachedSellUnits = units or {}
    pruneSelection(self.SelectedSellUnits, self.CachedSellUnits, function(unit) return unit.IsProtected ~= true end)
    if not sellListScroll then return end
    clearGuiRows(sellListScroll)
    local visibleCount = 0
    for _, unit in ipairs(self.CachedSellUnits) do
        if self.SellFilters[tostring(unit.Rarity)] then visibleCount = visibleCount + 1 end
    end
    if sellListSubtitle then
        sellListSubtitle.Text = string.format("%d visible of %d owned", visibleCount, #self.CachedSellUnits)
    end
    if visibleCount == 0 then
        local empty = makeLabel(sellListScroll, "No units match the active rarity filters.", 11, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center)
        empty.Size = UDim2.new(1, -3, 0, 60)
        refreshSelectionLabels()
        return
    end
    local layoutOrder = 0
    for _, unit in ipairs(self.CachedSellUnits) do
        local rarity = tostring(unit.Rarity or "Unknown")
        if self.SellFilters[rarity] then
            layoutOrder = layoutOrder + 1
            local id, protected = tostring(unit.Id), unit.IsProtected == true
            local selected, rarityColor = self.SelectedSellUnits[id] == true and not protected, RARITY_COLORS[rarity] or COLORS.TextDim
            local row = create("TextButton", {
                Size = UDim2.new(1, -3, 0, 54),
                BackgroundColor3 = selected and COLORS.SurfaceHover or COLORS.Sidebar,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = layoutOrder,
            }, sellListScroll)
            addCorner(row, 8)
            local rowStroke = addStroke(row, selected and COLORS.Red or COLORS.BorderSoft, selected and 0.3 or 0.15, 1)

            local name = makeLabel(row, string.format("%s  ·  Lv.%d", tostring(unit.DisplayName or unit.Asset or "Unit"), tonumber(unit.Level) or 1), 11, protected and COLORS.TextMuted or COLORS.Text, FONT_SEMIBOLD)
            name.Position = UDim2.fromOffset(12, 7)
            name.Size = UDim2.new(1, -54, 0, 18)

            local detailText = protected and (rarity:upper() .. "  /  PROTECTED") or (rarity:upper() .. "  /  READY TO SELL")
            local detail = makeLabel(row, detailText, 9, protected and COLORS.Green or rarityColor, FONT_MEDIUM)
            detail.Position = UDim2.fromOffset(12, 27)
            detail.Size = UDim2.new(1, -54, 0, 16)

            if protected then
                local shield = makeIcon(row, ICONS.Shield, 15, COLORS.Green)
                shield.Position = UDim2.new(1, -30, 0.5, -7)
            else
                makeSelectionIndicator(row, selected, COLORS.Red)
                bindHover(row, selected and COLORS.SurfaceHover or COLORS.Sidebar, COLORS.SurfaceHover, rowStroke, selected and COLORS.Red or COLORS.BorderSoft, COLORS.Red)
                row.Activated:Connect(function()
                    if UIModule.SelectedSellUnits[id] then
                        UIModule.SelectedSellUnits[id] = nil
                    else
                        UIModule.SelectedSellUnits[id] = true
                    end
                    refreshSelectionLabels()
                    UIModule:UpdateSellList(UIModule.CachedSellUnits)
                end)
            end
        end
    end
    refreshSelectionLabels()
end

function UIModule:Destroy()
    for _, connection in ipairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.Connections)
    if screenGui then
        screenGui:Destroy()
    end
end

-- ============================================================================
-- MODULAR SECTION BUILDERS (Prevents Local Register Overflow)
-- ============================================================================

local function buildSidebar()
    local sidebar = create("Frame", {
        Size = UDim2.new(0, 204, 1, 0),
        BackgroundColor3 = COLORS.Sidebar,
        BorderSizePixel = 0,
    }, mainFrame)
    create("Frame", {
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = COLORS.BorderSoft,
        BorderSizePixel = 0,
    }, sidebar)

    local brandMark = create("Frame", {
        Position = UDim2.fromOffset(18, 18),
        Size = UDim2.fromOffset(38, 38),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, sidebar)
    addCorner(brandMark, 9)
    addStroke(brandMark, COLORS.Border, 0.2, 1)
    local brandIcon = makeIcon(brandMark, ICONS.Sparkles, 18, COLORS.Accent)
    brandIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    brandIcon.Position = UDim2.fromScale(0.5, 0.5)

    local brandTitle = makeLabel(sidebar, "GARBAN", 16, COLORS.Text, FONT_BOLD)
    brandTitle.Position = UDim2.fromOffset(66, 17)
    brandTitle.Size = UDim2.fromOffset(125, 20)

    local brandSubtitle = makeLabel(sidebar, "BR BR PATAPIM", 9, COLORS.TextDim, FONT_BOLD)
    brandSubtitle.Position = UDim2.fromOffset(66, 37)
    brandSubtitle.Size = UDim2.fromOffset(125, 16)

    local navCaption = makeLabel(sidebar, "WORKSPACE", 9, COLORS.TextDim, FONT_BOLD)
    navCaption.Position = UDim2.fromOffset(18, 88)
    navCaption.Size = UDim2.new(1, -36, 0, 16)

    local navContainer = create("Frame", {
        Position = UDim2.fromOffset(12, 111),
        Size = UDim2.new(1, -24, 0, 198),
        BackgroundTransparency = 1,
    }, sidebar)
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navContainer)

    local function createNavButton(tabName, title, subtitle, iconAsset, layoutOrder)
        local active = UIModule.CurrentTab == tabName
        local button = create("TextButton", {
            Name = tabName,
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = layoutOrder,
        }, navContainer)
        addCorner(button, 8)
        local stroke = addStroke(button, active and COLORS.Border or COLORS.Sidebar, active and 0.2 or 1, 1)
        local indicator = create("Frame", {
            Position = UDim2.new(0, 0, 0.5, -10),
            Size = UDim2.fromOffset(3, 20),
            BackgroundColor3 = COLORS.Accent,
            BackgroundTransparency = active and 0 or 1,
            BorderSizePixel = 0,
        }, button)
        addCorner(indicator, 2)

        local iconBack = create("Frame", {
            Position = UDim2.fromOffset(10, 8),
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = active and COLORS.AccentSoft or COLORS.Surface,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
        }, button)
        addCorner(iconBack, 7)

        local icon = makeIcon(iconBack, iconAsset, 15, active and COLORS.Accent or COLORS.TextMuted)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)

        local titleLabel = makeLabel(button, title, 12, active and COLORS.Text or COLORS.TextMuted, FONT_SEMIBOLD)
        titleLabel.Position = UDim2.fromOffset(47, 5)
        titleLabel.Size = UDim2.new(1, -55, 0, 19)

        local subtitleLabel = makeLabel(button, subtitle, 10, COLORS.TextDim, FONT_MEDIUM)
        subtitleLabel.Position = UDim2.fromOffset(47, 22)
        subtitleLabel.Size = UDim2.new(1, -55, 0, 15)

        tabButtons[tabName] = { Button = button, Stroke = stroke, Indicator = indicator, IconBack = iconBack, Icon = icon, Title = titleLabel }
        button.Activated:Connect(function() UIModule:SwitchTab(tabName) end)
    end

    createNavButton("Evolve", "Evolution Lab", "Craft & evolve", ICONS.Sparkles, 1)
    createNavButton("Sell", "Unit Cleaner", "Filter & protect", ICONS.Cleaner, 2)
    createNavButton("Team", "Automation", "Runtime options", ICONS.Settings, 3)
    createNavButton("Macro", "Macro Studio", "Record & replay", ICONS.Macro, 4)

    -- Safety card
    local safetyCard = create("Frame", {
        Position = UDim2.new(0, 12, 1, -136),
        Size = UDim2.new(1, -24, 0, 68),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, sidebar)
    addCorner(safetyCard, 9)
    addStroke(safetyCard, COLORS.BorderSoft, 0.15, 1)

    local safetyIconBack = create("Frame", {
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, safetyCard)
    addCorner(safetyIconBack, 6)
    local safetyIcon = makeIcon(safetyIconBack, ICONS.Shield, 14, COLORS.Green)
    safetyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    safetyIcon.Position = UDim2.fromScale(0.5, 0.5)

    local safetyTitle = makeLabel(safetyCard, "Runtime Protected", 11, COLORS.Text, FONT_SEMIBOLD)
    safetyTitle.Position = UDim2.fromOffset(44, 7)
    safetyTitle.Size = UDim2.new(1, -50, 0, 18)

    local safetyText = makeLabel(safetyCard, "Replica sync active", 9, COLORS.TextDim, FONT_MEDIUM)
    safetyText.Position = UDim2.fromOffset(44, 25)
    safetyText.Size = UDim2.new(1, -50, 0, 15)

    local safetyLine = create("Frame", {
        Position = UDim2.fromOffset(10, 50),
        Size = UDim2.new(1, -20, 0, 3),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, safetyCard)
    addCorner(safetyLine, 2)
    local safetyFill = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = COLORS.Green,
        BorderSizePixel = 0,
    }, safetyLine)
    addCorner(safetyFill, 2)

    -- Account card
    local accountCard = create("Frame", {
        Position = UDim2.new(0, 12, 1, -56),
        Size = UDim2.new(1, -24, 0, 44),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, sidebar)
    addCorner(accountCard, 9)
    addStroke(accountCard, COLORS.BorderSoft, 0.1, 1)

    local accountIconBack = create("Frame", {
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, accountCard)
    addCorner(accountIconBack, 7)
    local accountIcon = makeIcon(accountIconBack, ICONS.User, 14, COLORS.TextMuted)
    accountIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    accountIcon.Position = UDim2.fromScale(0.5, 0.5)

    local accountName = makeLabel(accountCard, tostring(LocalPlayer and LocalPlayer.DisplayName or "Player"), 11, COLORS.Text, FONT_SEMIBOLD)
    accountName.Position = UDim2.fromOffset(44, 5)
    accountName.Size = UDim2.new(1, -50, 0, 17)

    local accountId = makeLabel(accountCard, "@" .. tostring(LocalPlayer and LocalPlayer.Name or "local"), 9, COLORS.TextDim, FONT_MEDIUM)
    accountId.Position = UDim2.fromOffset(44, 22)
    accountId.Size = UDim2.new(1, -50, 0, 15)
end

local function buildHeaderAndHost()
    local content = create("Frame", {
        Position = UDim2.fromOffset(204, 0),
        Size = UDim2.new(1, -204, 1, 0),
        BackgroundTransparency = 1,
    }, mainFrame)

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 78),
        BackgroundTransparency = 1,
    }, content)

    pageTitle = makeLabel(header, "Evolution Lab", 19, COLORS.Text, FONT_BOLD)
    pageTitle.Position = UDim2.fromOffset(24, 18)
    pageTitle.Size = UDim2.new(0, 250, 0, 24)

    pageSubtitle = makeLabel(header, "Plan materials and evolve your strongest unit safely.", 11, COLORS.TextMuted, FONT_MEDIUM)
    pageSubtitle.Position = UDim2.fromOffset(24, 44)
    pageSubtitle.Size = UDim2.new(1, -300, 0, 18)

    -- Performance pill
    local perfPill = create("Frame", {
        Position = UDim2.new(1, -238, 0, 23),
        Size = UDim2.fromOffset(176, 30),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, header)
    addCorner(perfPill, 8)
    addStroke(perfPill, COLORS.BorderSoft, 0.15, 1)

    local perfDot = create("Frame", {
        Position = UDim2.fromOffset(10, 11),
        Size = UDim2.fromOffset(7, 7),
        BackgroundColor3 = COLORS.Green,
        BorderSizePixel = 0,
    }, perfPill)
    addCorner(perfDot, 4)

    local fpsCaption = makeLabel(perfPill, "FPS", 9, COLORS.TextDim, FONT_BOLD)
    fpsCaption.Position = UDim2.fromOffset(23, 0)
    fpsCaption.Size = UDim2.fromOffset(22, 30)

    local fpsValLabel = makeLabel(perfPill, "60", 10, COLORS.Text, FONT_BOLD)
    fpsValLabel.Position = UDim2.fromOffset(46, 0)
    fpsValLabel.Size = UDim2.fromOffset(24, 30)

    local perfSep = makeLabel(perfPill, "•", 9, COLORS.TextDim, FONT_BOLD, Enum.TextXAlignment.Center)
    perfSep.Position = UDim2.fromOffset(70, 0)
    perfSep.Size = UDim2.fromOffset(12, 30)

    local pingCaption = makeLabel(perfPill, "PING", 9, COLORS.TextDim, FONT_BOLD)
    pingCaption.Position = UDim2.fromOffset(84, 0)
    pingCaption.Size = UDim2.fromOffset(28, 30)

    local pingValLabel = makeLabel(perfPill, "—", 10, COLORS.Text, FONT_BOLD)
    pingValLabel.Position = UDim2.fromOffset(113, 0)
    pingValLabel.Size = UDim2.fromOffset(56, 30)

    local fpsFrames, fpsTimeAcc = 0, 0
    table.insert(UIModule.Connections, RunService.RenderStepped:Connect(function(dt)
        fpsFrames = fpsFrames + 1
        fpsTimeAcc = fpsTimeAcc + dt
        if fpsTimeAcc >= 0.5 then
            local currentFps = math.round(fpsFrames / math.max(0.001, fpsTimeAcc))
            fpsFrames = 0
            fpsTimeAcc = 0
            fpsValLabel.Text = tostring(currentFps)
            if currentFps >= 55 then
                fpsValLabel.TextColor3 = COLORS.Text
            elseif currentFps >= 30 then
                fpsValLabel.TextColor3 = COLORS.Amber
            else
                fpsValLabel.TextColor3 = COLORS.Red
            end

            local pingMs = nil
            pcall(function()
                if LocalPlayer then pingMs = math.round(LocalPlayer:GetNetworkPing() * 1000) end
            end)

            if pingMs then
                pingValLabel.Text = string.format("%dms", pingMs)
                if pingMs <= 80 then
                    pingValLabel.TextColor3 = COLORS.Text
                    perfDot.BackgroundColor3 = COLORS.Green
                elseif pingMs <= 160 then
                    pingValLabel.TextColor3 = COLORS.Amber
                    perfDot.BackgroundColor3 = COLORS.Amber
                else
                    pingValLabel.TextColor3 = COLORS.Red
                    perfDot.BackgroundColor3 = COLORS.Red
                end
            else
                pingValLabel.Text = "N/A"
                pingValLabel.TextColor3 = COLORS.TextDim
                perfDot.BackgroundColor3 = COLORS.Green
            end
        end
    end))

    local closeButton = create("TextButton", {
        Position = UDim2.new(1, -48, 0, 22),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, header)
    addCorner(closeButton, 8)
    local closeStroke = addStroke(closeButton, COLORS.BorderSoft, 0.1, 1)
    local closeIcon = makeIcon(closeButton, ICONS.Close, 14, COLORS.TextMuted)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Position = UDim2.fromScale(0.5, 0.5)
    bindHover(closeButton, COLORS.Surface, COLORS.SurfaceHover, closeStroke, COLORS.BorderSoft, COLORS.Red)
    closeButton.Activated:Connect(function() UIModule:SetState(false) end)

    -- Window Dragging
    local dragging, dragStart, windowStart = false, Vector2.zero, UDim2.fromScale(0.5, 0.5)
    table.insert(UIModule.Connections, header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            windowStart = mainFrame.Position
        end
    end))
    table.insert(UIModule.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    table.insert(UIModule.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local camera = Workspace.CurrentCamera
            if not camera then return end
            local viewport = camera.ViewportSize
            local halfWidth = (mainFrame.AbsoluteSize.X * 0.5)
            local halfHeight = (mainFrame.AbsoluteSize.Y * 0.5)
            local absoluteX = viewport.X * windowStart.X.Scale + windowStart.X.Offset + delta.X
            local absoluteY = viewport.Y * windowStart.Y.Scale + windowStart.Y.Offset + delta.Y
            local minX, maxX = halfWidth + 8, viewport.X - halfWidth - 8
            local minY, maxY = halfHeight + 8, viewport.Y - halfHeight - 8
            local clampedX = minX <= maxX and math.clamp(absoluteX, minX, maxX) or (viewport.X * 0.5)
            local clampedY = minY <= maxY and math.clamp(absoluteY, minY, maxY) or (viewport.Y * 0.5)
            mainFrame.Position = UDim2.new(
                windowStart.X.Scale, clampedX - viewport.X * windowStart.X.Scale,
                windowStart.Y.Scale, clampedY - viewport.Y * windowStart.Y.Scale
            )
            mainShadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset + 8)
        end
    end))

    local viewHost = create("Frame", {
        Position = UDim2.fromOffset(20, 78),
        Size = UDim2.new(1, -40, 1, -96),
        BackgroundTransparency = 1,
    }, content)

    return viewHost
end

local function buildEvolveTab(viewHost)
    local evolveView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, viewHost)
    tabViews.Evolve = evolveView

    local _, evoListBody, _, subTitle = createPanel(evolveView, UDim2.fromOffset(0, 0), UDim2.new(0.55, -7, 1, 0), "Evolution candidates", "0 eligible units", ICONS.Team, COLORS.Accent)
    evoListSubtitle = subTitle

    local evoListControls = create("Frame", { Position = UDim2.new(0, 0, 1, -36), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, evoListBody)
    local evoSelectAllButton = createMiniButton(evoListControls, "Select all", ICONS.CheckAll, UDim2.fromOffset(0, 2), UDim2.new(0.5, -4, 0, 32))
    local evoClearButton = createMiniButton(evoListControls, "Clear", ICONS.Clear, UDim2.new(0.5, 4, 0, 2), UDim2.new(0.5, -4, 0, 32))

    local evoListHost = create("Frame", { Size = UDim2.new(1, 0, 1, -44), BackgroundTransparency = 1 }, evoListBody)
    evoListScroll = createScroll(evoListHost)

    local evoRight = create("Frame", { Position = UDim2.new(0.55, 7, 0, 0), Size = UDim2.new(0.45, -7, 1, 0), BackgroundTransparency = 1 }, evolveView)
    local _, materialBody, _, matSub = createPanel(evoRight, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 226), "Material plan", "Live inventory requirements", ICONS.Flask, COLORS.Accent)
    materialSubtitle = matSub
    materialScroll = createScroll(materialBody)

    local logPanel = create("Frame", {
        Position = UDim2.fromOffset(0, 236),
        Size = UDim2.new(1, 0, 1, -284),
        BackgroundColor3 = COLORS.Sidebar,
        BorderSizePixel = 0,
    }, evoRight)
    addCorner(logPanel, 10)
    addStroke(logPanel, COLORS.BorderSoft, 0.05, 1)

    local logIcon = makeIcon(logPanel, ICONS.Terminal, 13, COLORS.Accent)
    logIcon.Position = UDim2.fromOffset(12, 11)
    local logTitle = makeLabel(logPanel, "LIVE ACTIVITY", 9, COLORS.TextDim, FONT_BOLD)
    logTitle.Position = UDim2.fromOffset(32, 7)
    logTitle.Size = UDim2.new(1, -44, 0, 22)

    logBox = makeLabel(logPanel, "Ready. Waiting for an action...", 10, COLORS.TextMuted, FONT_MONO)
    logBox.Position = UDim2.fromOffset(12, 30)
    logBox.Size = UDim2.new(1, -24, 1, -38)
    logBox.TextYAlignment = Enum.TextYAlignment.Top
    logBox.TextWrapped = true
    logBox.TextTruncate = Enum.TextTruncate.None

    local btn, lbl = createActionButton(evoRight, "Craft & evolve selected", ICONS.Wand, COLORS.Accent)
    btn.Position = UDim2.new(0, 0, 1, -40)
    evoActionButton, evoActionLabel = btn, lbl

    evoSelectAllButton.Activated:Connect(function()
        if UIModule.Callbacks.OnSelectAllEvo then UIModule.Callbacks.OnSelectAllEvo() end
        refreshSelectionLabels()
    end)
    evoClearButton.Activated:Connect(function()
        table.clear(UIModule.SelectedEvoUnits)
        refreshSelectionLabels()
        UIModule:UpdateEvoList(UIModule.CachedEvoCandidates)
    end)
    evoActionButton.Activated:Connect(function()
        if evoBusy or not UIModule.Callbacks.OnEvoAction then return end
        evoBusy = true
        evoActionButton.Active = false
        evoActionButton.BackgroundTransparency = 0.25
        refreshSelectionLabels()
        task.spawn(function()
            local ok, err = pcall(UIModule.Callbacks.OnEvoAction)
            if not ok then UIModule:AppendLog("Evolution action failed: " .. tostring(err)) end
            evoBusy = false
            evoActionButton.Active = true
            evoActionButton.BackgroundTransparency = 0
            refreshSelectionLabels()
        end)
    end)
end

local function buildSellTab(viewHost)
    local sellView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, viewHost)
    tabViews.Sell = sellView

    local _, sellListBody, _, sellSub = createPanel(sellView, UDim2.fromOffset(0, 0), UDim2.new(0.62, -7, 1, 0), "Inventory units", "0 visible units", ICONS.Team, COLORS.Accent)
    sellListSubtitle = sellSub

    local sellListHost = create("Frame", { Size = UDim2.new(1, 0, 1, -44), BackgroundTransparency = 1 }, sellListBody)
    sellListScroll = createScroll(sellListHost)

    local sellControls = create("Frame", { Position = UDim2.new(0, 0, 1, -36), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, sellListBody)
    local sellSelectButton = createMiniButton(sellControls, "Select filtered", ICONS.Filter, UDim2.fromOffset(0, 2), UDim2.new(0.5, -4, 0, 32))
    local sellClearButton = createMiniButton(sellControls, "Clear", ICONS.Clear, UDim2.new(0.5, 4, 0, 2), UDim2.new(0.5, -4, 0, 32))

    local sellRight = create("Frame", { Position = UDim2.new(0.62, 7, 0, 0), Size = UDim2.new(0.38, -7, 1, 0), BackgroundTransparency = 1 }, sellView)
    local _, filterBody = createPanel(sellRight, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 238), "Rarity filters", "Choose eligible unit tiers", ICONS.Filter, COLORS.Amber)
    filterContainer = create("Frame", { Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 }, filterBody)
    create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 34), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, filterContainer)
    setupFilters()

    local protectedNotice = create("Frame", {
        Position = UDim2.new(0, 0, 1, -44),
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, filterBody)
    addCorner(protectedNotice, 8)
    addStroke(protectedNotice, COLORS.BorderSoft, 0.1, 1)

    local protectedIcon = makeIcon(protectedNotice, ICONS.Shield, 14, COLORS.Green)
    protectedIcon.Position = UDim2.fromOffset(10, 12)
    local protectedText = makeLabel(protectedNotice, "Locked & high-tier units stay protected", 9, COLORS.Green, FONT_SEMIBOLD)
    protectedText.Position = UDim2.fromOffset(30, 0)
    protectedText.Size = UDim2.new(1, -38, 1, 0)

    local selectedCard = create("Frame", {
        Position = UDim2.fromOffset(0, 250),
        Size = UDim2.new(1, 0, 0, 86),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, sellRight)
    addCorner(selectedCard, 10)
    addStroke(selectedCard, COLORS.BorderSoft, 0.1, 1)

    local selectedCaption = makeLabel(selectedCard, "SELECTED FOR CLEANUP", 9, COLORS.TextDim, FONT_BOLD)
    selectedCaption.Position = UDim2.fromOffset(14, 10)
    selectedCaption.Size = UDim2.new(1, -28, 0, 16)

    selectedCountLabel = makeLabel(selectedCard, "0", 26, COLORS.Text, FONT_BOLD)
    selectedCountLabel.Position = UDim2.fromOffset(14, 26)
    selectedCountLabel.Size = UDim2.new(0.45, 0, 0, 36)

    local selectedHint = makeLabel(selectedCard, "units", 11, COLORS.TextMuted, FONT_MEDIUM, Enum.TextXAlignment.Right)
    selectedHint.Position = UDim2.new(0.45, 0, 0, 35)
    selectedHint.Size = UDim2.new(0.55, -14, 0, 22)

    local btn, lbl = createActionButton(sellRight, "Sell selected (0)", ICONS.Cleaner, COLORS.Red)
    btn.Position = UDim2.new(0, 0, 1, -40)
    sellActionButton, sellActionLabel = btn, lbl

    sellSelectButton.Activated:Connect(function()
        if UIModule.Callbacks.OnSelectFilteredSell then UIModule.Callbacks.OnSelectFilteredSell() end
        refreshSelectionLabels()
    end)
    sellClearButton.Activated:Connect(function()
        table.clear(UIModule.SelectedSellUnits)
        refreshSelectionLabels()
        UIModule:UpdateSellList(UIModule.CachedSellUnits)
    end)
    sellActionButton.Activated:Connect(function()
        if sellBusy or not UIModule.Callbacks.OnSellAction then return end
        sellBusy = true
        sellActionButton.Active = false
        sellActionButton.BackgroundTransparency = 0.25
        refreshSelectionLabels()
        task.spawn(function()
            local ok, err = pcall(UIModule.Callbacks.OnSellAction)
            if not ok then UIModule:AppendLog("Sell action failed: " .. tostring(err)) end
            sellBusy = false
            sellActionButton.Active = true
            sellActionButton.BackgroundTransparency = 0
            refreshSelectionLabels()
        end)
    end)
end

local function buildTeamTab(viewHost)
    local teamView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, viewHost)
    tabViews.Team = teamView

    local automationHero = create("Frame", {
        Size = UDim2.new(1, 0, 0, 86),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, teamView)
    addCorner(automationHero, 10)
    addStroke(automationHero, COLORS.BorderSoft, 0.1, 1)

    local heroIconBack = create("Frame", {
        Position = UDim2.fromOffset(16, 16),
        Size = UDim2.fromOffset(54, 54),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, automationHero)
    addCorner(heroIconBack, 12)
    addStroke(heroIconBack, COLORS.BorderSoft, 0.2, 1)

    local heroIcon = makeIcon(heroIconBack, ICONS.Ghost, 24, COLORS.Accent)
    heroIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    heroIcon.Position = UDim2.fromScale(0.5, 0.5)

    local heroTitle = makeLabel(automationHero, "Automation Control Center", 15, COLORS.Text, FONT_BOLD)
    heroTitle.Position = UDim2.fromOffset(82, 18)
    heroTitle.Size = UDim2.new(1, -190, 0, 22)

    local heroText = makeLabel(automationHero, "Runtime switches apply instantly and remain isolated from game UI settings.", 10, COLORS.TextMuted, FONT_MEDIUM)
    heroText.Position = UDim2.fromOffset(82, 42)
    heroText.Size = UDim2.new(1, -190, 0, 18)

    local heroBadge = create("Frame", {
        Position = UDim2.new(1, -100, 0, 28),
        Size = UDim2.fromOffset(84, 28),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, automationHero)
    addCorner(heroBadge, 14)
    addStroke(heroBadge, COLORS.BorderSoft, 0.1, 1)
    local heroBadgeLabel = makeLabel(heroBadge, "SYNCED", 9, COLORS.Green, FONT_BOLD, Enum.TextXAlignment.Center)
    heroBadgeLabel.Size = UDim2.fromScale(1, 1)

    local togglesPanel = create("Frame", {
        Position = UDim2.fromOffset(0, 98),
        Size = UDim2.new(1, 0, 1, -98),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, teamView)
    addCorner(togglesPanel, 10)
    addStroke(togglesPanel, COLORS.BorderSoft, 0.1, 1)

    local toggleHeaderIcon = makeIcon(togglesPanel, ICONS.Settings, 14, COLORS.Accent)
    toggleHeaderIcon.Position = UDim2.fromOffset(16, 16)

    local toggleHeaderTitle = makeLabel(togglesPanel, "Runtime Modules", 13, COLORS.Text, FONT_SEMIBOLD)
    toggleHeaderTitle.Position = UDim2.fromOffset(40, 10)
    toggleHeaderTitle.Size = UDim2.new(1, -56, 0, 22)

    local toggleHeaderText = makeLabel(togglesPanel, "Enable only the systems you want this session.", 10, COLORS.TextDim, FONT_MEDIUM)
    toggleHeaderText.Position = UDim2.fromOffset(40, 29)
    toggleHeaderText.Size = UDim2.new(1, -56, 0, 16)

    create("Frame", {
        Position = UDim2.fromOffset(14, 54),
        Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = COLORS.BorderSoft,
        BorderSizePixel = 0,
    }, togglesPanel)

    teamCard = create("ScrollingFrame", {
        Position = UDim2.fromOffset(14, 64),
        Size = UDim2.new(1, -28, 1, -76),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Border,
        ScrollBarImageTransparency = 0.2,
        CanvasSize = UDim2.fromOffset(0, 0),
    }, togglesPanel)

    local teamLayout = create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, teamCard)
    table.insert(UIModule.Connections, teamLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        teamCard.CanvasSize = UDim2.fromOffset(0, teamLayout.AbsoluteContentSize.Y + 4)
    end))
end

local function buildMacroTab(viewHost)
    local macroView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, viewHost)
    tabViews.Macro = macroView

    local macroLeft = create("Frame", { Size = UDim2.new(0.54, -7, 1, 0), BackgroundTransparency = 1 }, macroView)
    local macroRight = create("Frame", { Position = UDim2.new(0.54, 7, 0, 0), Size = UDim2.new(0.46, -7, 1, 0), BackgroundTransparency = 1 }, macroView)

    local _, macroStatusBody = createPanel(macroLeft, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 204), "Macro Status", "Server-synchronized recorder", ICONS.Record, COLORS.Red)
    local statusGrid = create("Frame", { Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1 }, macroStatusBody)
    create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 38), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder }, statusGrid)

    local macroStatusValues = {}
    for order, item in ipairs({
        { "Status", "Idle" }, { "Action", "None" }, { "Type", "None" }, { "Unit", "—" },
    }) do
        local card = create("Frame", { BackgroundColor3 = COLORS.SurfaceRaised, BorderSizePixel = 0, LayoutOrder = order }, statusGrid)
        addCorner(card, 7)
        addStroke(card, COLORS.BorderSoft, 0.15, 1)

        local caption = makeLabel(card, string.upper(item[1]), 8, COLORS.TextDim, FONT_BOLD)
        caption.Position = UDim2.fromOffset(8, 3)
        caption.Size = UDim2.new(1, -16, 0, 12)

        local value = makeLabel(card, item[2], 10, order == 1 and COLORS.Green or COLORS.Text, FONT_SEMIBOLD)
        value.Position = UDim2.fromOffset(8, 16)
        value.Size = UDim2.new(1, -16, 0, 18)
        macroStatusValues[item[1]] = value
    end

    local waitingPill = create("Frame", {
        Position = UDim2.new(0, 0, 1, -34),
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, macroStatusBody)
    addCorner(waitingPill, 7)
    addStroke(waitingPill, COLORS.BorderSoft, 0.1, 1)

    local waitingIcon = makeIcon(waitingPill, ICONS.Clock, 13, COLORS.Amber)
    waitingIcon.Position = UDim2.fromOffset(10, 8)
    local waitingLabel = makeLabel(waitingPill, "Waiting for: Idle", 10, COLORS.Amber, FONT_SEMIBOLD)
    waitingLabel.Position = UDim2.fromOffset(28, 0)
    waitingLabel.Size = UDim2.new(1, -36, 1, 0)

    local _, macroControlsBody = createPanel(macroLeft, UDim2.fromOffset(0, 214), UDim2.new(1, 0, 1, -214), "Playback Controls", "Record and replay safely", ICONS.Play, COLORS.Accent)
    local macroToggleRow = create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, macroControlsBody)

    local function makeMacroToggle(parent, title, iconAsset, position, accent, callbackName)
        local active = false
        local button = create("TextButton", {
            Position = position,
            Size = UDim2.new(0.5, -4, 0, 38),
            BackgroundColor3 = COLORS.SurfaceRaised,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
        }, parent)
        addCorner(button, 8)
        local stroke = addStroke(button, COLORS.BorderSoft, 0.15, 1)
        local icon = makeIcon(button, iconAsset, 14, COLORS.TextMuted)
        icon.Position = UDim2.fromOffset(10, 12)
        local label = makeLabel(button, title, 11, COLORS.TextMuted, FONT_SEMIBOLD)
        label.Position = UDim2.fromOffset(30, 0)
        label.Size = UDim2.new(1, -38, 1, 0)

        local function setState(value, silent)
            active = value == true
            button.BackgroundColor3 = active and accent:Lerp(COLORS.Canvas, 0.78) or COLORS.SurfaceRaised
            stroke.Color = active and accent or COLORS.BorderSoft
            stroke.Transparency = active and 0.25 or 0.15
            icon.ImageColor3 = active and accent or COLORS.TextMuted
            label.TextColor3 = active and COLORS.Text or COLORS.TextMuted

            if not silent then
                local callback = UIModule.Callbacks[callbackName]
                if callback then
                    local ok, accepted, message = pcall(callback, active, UIModule.MacroNameInput and UIModule.MacroNameInput.Text or "")
                    if not ok or accepted == false then
                        active = false
                        button.BackgroundColor3 = COLORS.SurfaceRaised
                        stroke.Color = COLORS.BorderSoft
                        stroke.Transparency = 0.15
                        icon.ImageColor3 = COLORS.TextMuted
                        label.TextColor3 = COLORS.TextMuted
                        UIModule:AppendLog("Macro control rejected: " .. tostring(message or accepted))
                    end
                end
            end
        end
        button.Activated:Connect(function() setState(not active, false) end)
        return setState
    end

    UIModule._SetRecordToggle = makeMacroToggle(macroToggleRow, "Record Macro", ICONS.Record, UDim2.fromOffset(0, 0), COLORS.Red, "OnMacroRecordToggle")
    UIModule._SetPlayToggle = makeMacroToggle(macroToggleRow, "Play Macro", ICONS.Play, UDim2.new(0.5, 4, 0, 0), COLORS.Green, "OnMacroPlayToggle")

    -- Step Delay Slider
    local delayCaption = makeLabel(macroControlsBody, "STEP DELAY", 9, COLORS.TextDim, FONT_BOLD)
    delayCaption.Position = UDim2.fromOffset(0, 48)
    delayCaption.Size = UDim2.new(1, -66, 0, 16)

    local delayValue = makeLabel(macroControlsBody, "0.20s", 10, COLORS.Accent, FONT_BOLD, Enum.TextXAlignment.Right)
    delayValue.Position = UDim2.new(1, -62, 0, 48)
    delayValue.Size = UDim2.fromOffset(62, 16)

    local delayTrack = create("TextButton", {
        Position = UDim2.fromOffset(0, 68),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, macroControlsBody)

    local delayRail = create("Frame", {
        Position = UDim2.new(0, 0, 0.5, -2),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
    }, delayTrack)
    addCorner(delayRail, 3)

    local delayFill = create("Frame", {
        Size = UDim2.new((0.2 - 0.05) / 0.95, 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, delayRail)
    addCorner(delayFill, 3)

    local delayKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((0.2 - 0.05) / 0.95, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = COLORS.White,
        BorderSizePixel = 0,
    }, delayRail)
    addCorner(delayKnob, 7)
    addStroke(delayKnob, COLORS.Accent, 0.1, 2)

    local draggingDelay = false
    local function setDelayFromX(x)
        local ratio = math.clamp((x - delayTrack.AbsolutePosition.X) / math.max(1, delayTrack.AbsoluteSize.X), 0, 1)
        local value = math.floor((0.05 + ratio * 0.95) * 20 + 0.5) / 20
        local renderedRatio = (value - 0.05) / 0.95
        delayFill.Size = UDim2.new(renderedRatio, 0, 1, 0)
        delayKnob.Position = UDim2.new(renderedRatio, 0, 0.5, 0)
        delayValue.Text = string.format("%.2fs", value)
        if UIModule.Callbacks.OnMacroStepDelay then
            UIModule.Callbacks.OnMacroStepDelay(value)
        end
    end

    delayTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingDelay = true
            setDelayFromX(input.Position.X)
        end
    end)
    table.insert(UIModule.Connections, UserInputService.InputChanged:Connect(function(input)
        if draggingDelay and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setDelayFromX(input.Position.X)
        end
    end))
    table.insert(UIModule.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingDelay = false
        end
    end))

    local playModes = { "Money, Time", "Strict Time", "Smart Hybrid" }
    local playModeIndex = 3
    local modeButton = create("TextButton", {
        Position = UDim2.fromOffset(0, 96),
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, macroControlsBody)
    addCorner(modeButton, 8)
    local modeStroke = addStroke(modeButton, COLORS.BorderSoft, 0.15, 1)
    bindHover(modeButton, COLORS.SurfaceRaised, COLORS.SurfaceHover, modeStroke, COLORS.BorderSoft, COLORS.Accent)

    local modeCaption = makeLabel(modeButton, "PLAY MODE", 9, COLORS.TextDim, FONT_BOLD)
    modeCaption.Position = UDim2.fromOffset(10, 3)
    modeCaption.Size = UDim2.new(0.45, 0, 0, 14)

    local modeValue = makeLabel(modeButton, playModes[playModeIndex], 10, COLORS.Text, FONT_SEMIBOLD, Enum.TextXAlignment.Right)
    modeValue.Position = UDim2.new(0.4, 0, 0, 0)
    modeValue.Size = UDim2.new(0.6, -10, 1, 0)

    modeButton.Activated:Connect(function()
        playModeIndex = playModeIndex % #playModes + 1
        modeValue.Text = playModes[playModeIndex]
        if UIModule.Callbacks.OnMacroPlayMode then
            UIModule.Callbacks.OnMacroPlayMode(playModes[playModeIndex])
        end
    end)

    local macroWarning = makeLabel(macroControlsBody, "Note: Mobile/Slow devices may affect macro execution timings.", 9, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center)
    macroWarning.Position = UDim2.new(0, 0, 1, -20)
    macroWarning.Size = UDim2.new(1, 0, 0, 16)

    -- Profiles Panel
    local _, profilesBody, _, profSub = createPanel(macroRight, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), "Macro Profiles", "No profile selected", ICONS.Macro, COLORS.Accent)
    UIModule._MacroProfilesSubtitle = profSub

    local function makeInput(parent, placeholder, position, size, multiline)
        local box = create("TextBox", {
            Position = position,
            Size = size,
            BackgroundColor3 = COLORS.Sidebar,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            PlaceholderText = placeholder,
            PlaceholderColor3 = COLORS.TextDim,
            Text = "",
            TextColor3 = COLORS.Text,
            TextSize = 10,
            FontFace = multiline and FONT_MONO or FONT_MEDIUM,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            TextWrapped = multiline == true,
            MultiLine = multiline == true,
        }, parent)
        addCorner(box, 8)
        local stroke = addStroke(box, COLORS.BorderSoft, 0.15, 1)
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, multiline and 8 or 0),
            PaddingBottom = UDim.new(0, multiline and 8 or 0),
        }, box)

        box.Focused:Connect(function()
            TweenService:Create(stroke, TWEEN_FAST, { Color = COLORS.Accent }):Play()
        end)
        box.FocusLost:Connect(function()
            TweenService:Create(stroke, TWEEN_FAST, { Color = COLORS.BorderSoft }):Play()
        end)
        return box
    end

    local profileSelector = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = COLORS.SurfaceRaised,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, profilesBody)
    addCorner(profileSelector, 8)
    addStroke(profileSelector, COLORS.Accent, 0.3, 1)

    local profileSelectorLabel = makeLabel(profileSelector, "Select profile...", 11, COLORS.Text, FONT_SEMIBOLD)
    profileSelectorLabel.Position = UDim2.fromOffset(10, 0)
    profileSelectorLabel.Size = UDim2.new(1, -20, 1, 0)
    UIModule._MacroProfileSelectorLabel = profileSelectorLabel

    local macroNameInput = makeInput(profilesBody, "Macro name", UDim2.fromOffset(0, 44), UDim2.new(1, 0, 0, 34), false)
    UIModule.MacroNameInput = macroNameInput

    local profileButtons = create("Frame", { Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1 }, profilesBody)
    create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 32), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder }, profileButtons)

    local function profileButton(text, icon, color, order, callbackName)
        local button = create("TextButton", {
            BackgroundColor3 = COLORS.Sidebar,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = order,
        }, profileButtons)
        addCorner(button, 7)
        local stroke = addStroke(button, COLORS.BorderSoft, 0.15, 1)
        local image = makeIcon(button, icon, 12, color)
        image.Position = UDim2.fromOffset(9, 10)
        local label = makeLabel(button, text, 9, COLORS.TextMuted, FONT_SEMIBOLD)
        label.Position = UDim2.fromOffset(26, 0)
        label.Size = UDim2.new(1, -32, 1, 0)
        bindHover(button, COLORS.Sidebar, COLORS.SurfaceHover, stroke, COLORS.BorderSoft, color)
        button.Activated:Connect(function()
            local callback = UIModule.Callbacks[callbackName]
            if callback then
                callback(macroNameInput.Text)
            end
        end)
    end

    profileButton("Create", ICONS.Plus, COLORS.Green, 1, "OnMacroCreate")
    profileButton("Delete", ICONS.Cleaner, COLORS.Red, 2, "OnMacroDelete")
    profileButton("Export", ICONS.Clipboard, COLORS.Accent, 3, "OnMacroExport")
    profileButton("Refresh", ICONS.Settings, COLORS.TextMuted, 4, "OnMacroRefresh")

    local importCaption = makeLabel(profilesBody, "IMPORT CONFIG", 9, COLORS.TextDim, FONT_BOLD)
    importCaption.Position = UDim2.fromOffset(0, 166)
    importCaption.Size = UDim2.new(1, 0, 0, 14)

    local importInput = makeInput(profilesBody, '{"steps":[...]} or paste raw config', UDim2.fromOffset(0, 184), UDim2.new(1, 0, 1, -230), true)
    UIModule.MacroImportInput = importInput

    local importButton = createActionButton(profilesBody, "Import Macro", ICONS.Upload, COLORS.Accent)
    importButton.Position = UDim2.new(0, 0, 1, -38)
    importButton.Size = UDim2.new(1, 0, 0, 36)

    profileSelector.Activated:Connect(function()
        if #UIModule.MacroProfiles == 0 then return end
        local currentIndex = table.find(UIModule.MacroProfiles, UIModule.SelectedMacroProfile) or 0
        currentIndex = currentIndex % #UIModule.MacroProfiles + 1
        UIModule.SelectedMacroProfile = UIModule.MacroProfiles[currentIndex]
        macroNameInput.Text = UIModule.SelectedMacroProfile
        profileSelectorLabel.Text = UIModule.SelectedMacroProfile
        if UIModule._MacroProfilesSubtitle then
            UIModule._MacroProfilesSubtitle.Text = string.format("%d profile(s) · selected %s", #UIModule.MacroProfiles, UIModule.SelectedMacroProfile)
        end
        if UIModule.Callbacks.OnMacroSelect then
            UIModule.Callbacks.OnMacroSelect(UIModule.SelectedMacroProfile)
        end
    end)

    importButton.Activated:Connect(function()
        if UIModule.Callbacks.OnMacroImport then
            UIModule.Callbacks.OnMacroImport(importInput.Text, macroNameInput.Text)
        end
    end)

    UIModule._MacroStatusValues = macroStatusValues
    UIModule._MacroWaitingLabel = waitingLabel
end

-- Execution Pipeline
buildSidebar()
local viewHost = buildHeaderAndHost()
buildEvolveTab(viewHost)
buildSellTab(viewHost)
buildTeamTab(viewHost)
buildMacroTab(viewHost)

-- Main Hotkey Listener
table.insert(UIModule.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        UIModule:SetState(not UIModule.IsOpen)
    end
end))

-- Render & Auto-Open
refreshSelectionLabels()
if UIModule.Callbacks.OnRefresh then UIModule.Callbacks.OnRefresh() end
UIModule:SetState(true)

return UIModule
