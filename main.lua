local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local COLORS = {
    Canvas = Color3.fromRGB(8, 10, 18), Sidebar = Color3.fromRGB(12, 15, 26),
    Surface = Color3.fromRGB(17, 21, 35), SurfaceRaised = Color3.fromRGB(23, 28, 45),
    SurfaceHover = Color3.fromRGB(29, 35, 56), Border = Color3.fromRGB(45, 52, 76),
    BorderSoft = Color3.fromRGB(33, 39, 59), Text = Color3.fromRGB(242, 244, 255),
    TextMuted = Color3.fromRGB(154, 163, 190), TextDim = Color3.fromRGB(102, 112, 143),
    Violet = Color3.fromRGB(147, 112, 255), VioletBright = Color3.fromRGB(177, 146, 255),
    Blue = Color3.fromRGB(83, 162, 255), Cyan = Color3.fromRGB(77, 214, 221),
    Green = Color3.fromRGB(77, 215, 151), Amber = Color3.fromRGB(244, 180, 70),
    Red = Color3.fromRGB(245, 103, 124), White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

-- IDs are selected from asset.txt (Lucide icon asset set).
local ICONS = {
    Close = "rbxassetid://116396312853810", Sparkles = "rbxassetid://105634041692696",
    Cleaner = "rbxassetid://126010725826757", Team = "rbxassetid://85332511060401",
    CheckAll = "rbxassetid://101885204738917", Clear = "rbxassetid://111132030834422",
    Filter = "rbxassetid://83186010624431", Settings = "rbxassetid://109485777305919",
    Flask = "rbxassetid://115528123394259", Terminal = "rbxassetid://102379915564176",
    Shield = "rbxassetid://71867984579031", Ghost = "rbxassetid://132705178126217",
    Check = "rbxassetid://86817768619372", Wand = "rbxassetid://115623066336607",
}

local RARITY_COLORS = {
    Secret = Color3.fromRGB(244, 88, 113), Mythic = Color3.fromRGB(213, 92, 255),
    Limited = Color3.fromRGB(213, 92, 255), Legendary = Color3.fromRGB(249, 178, 59),
    Epic = Color3.fromRGB(155, 104, 255), Rare = Color3.fromRGB(73, 159, 255),
    Unknown = COLORS.TextDim,
}

local FONT_BOLD = Font.fromName("BuilderSans", Enum.FontWeight.Bold)
local FONT_SEMIBOLD = Font.fromName("BuilderSans", Enum.FontWeight.SemiBold)
local FONT_MEDIUM = Font.fromName("BuilderSans", Enum.FontWeight.Medium)
local FONT_MONO = Font.fromName("Code", Enum.FontWeight.Medium)
local TWEEN_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_NORMAL = TweenInfo.new(0.23, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local UIModule = {
    CurrentTab = "Evolve", IsOpen = false, Connections = {},
    SelectedEvoUnits = {}, SelectedSellUnits = {},
    SellFilters = { Rare = true, Epic = true, Legendary = false, Mythic = false },
    Callbacks = {}, CachedEvoCandidates = {}, CachedSellUnits = {},
}

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do instance[property] = value end
    instance.Parent = parent
    return instance
end

local function addCorner(target, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, target)
end

local function addStroke(target, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or COLORS.Border, Transparency = transparency or 0,
        Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, target)
end

local function makeLabel(parent, text, size, color, font, alignment)
    return create("TextLabel", {
        BackgroundTransparency = 1, Text = text or "", TextColor3 = color or COLORS.Text,
        TextSize = size or 13, FontFace = font or FONT_MEDIUM,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function makeIcon(parent, asset, size, color)
    return create("ImageLabel", {
        BackgroundTransparency = 1, Image = asset, ImageColor3 = color or COLORS.Text,
        Size = UDim2.fromOffset(size or 16, size or 16), ScaleType = Enum.ScaleType.Fit,
    }, parent)
end

local function bindHover(button, normalColor, hoverColor, stroke, normalStroke, hoverStroke)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TWEEN_FAST, { BackgroundColor3 = hoverColor }):Play()
        if stroke and hoverStroke then TweenService:Create(stroke, TWEEN_FAST, { Color = hoverStroke }):Play() end
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TWEEN_FAST, { BackgroundColor3 = normalColor }):Play()
        if stroke and normalStroke then TweenService:Create(stroke, TWEEN_FAST, { Color = normalStroke }):Play() end
    end)
end

local function clearGuiRows(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end

local function countSelected(selection)
    local count = 0
    for _, selected in pairs(selection) do if selected then count = count + 1 end end
    return count
end

local screenGui = create("ScreenGui", {
    Name = "HinaExpeditionsControlCenter", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 80,
}, nil)
local parentTarget = (typeof(gethui) == "function" and gethui()) or CoreGui
if not pcall(function() screenGui.Parent = parentTarget end) then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local mainShadow = create("Frame", {
    Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 8),
    Size = UDim2.fromOffset(916, 576), BackgroundColor3 = COLORS.Black,
    BackgroundTransparency = 0.44, BorderSizePixel = 0, Visible = false,
}, screenGui)
addCorner(mainShadow, 22)
local mainFrame = create("CanvasGroup", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(900, 560), BackgroundColor3 = COLORS.Canvas, BorderSizePixel = 0,
    GroupTransparency = 1, Visible = false, ClipsDescendants = true,
}, screenGui)
addCorner(mainFrame, 18)
addStroke(mainFrame, COLORS.Border, 0.08, 1)
local uiScale = create("UIScale", { Scale = 1 }, mainFrame)

local function updateResponsiveScale()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    uiScale.Scale = math.clamp(math.min((viewport.X - 32) / 900, (viewport.Y - 32) / 560), 0.68, 1)
end
updateResponsiveScale()
if Workspace.CurrentCamera then
    table.insert(UIModule.Connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
end
table.insert(UIModule.Connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateResponsiveScale))

local sidebar = create("Frame", { Size = UDim2.new(0, 204, 1, 0), BackgroundColor3 = COLORS.Sidebar, BorderSizePixel = 0 }, mainFrame)
create("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = COLORS.BorderSoft, BorderSizePixel = 0 }, sidebar)
local brandMark = create("Frame", { Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = COLORS.Violet, BorderSizePixel = 0 }, sidebar)
addCorner(brandMark, 11)
create("UIGradient", { Color = ColorSequence.new(COLORS.VioletBright, COLORS.Blue), Rotation = 135 }, brandMark)
local brandIcon = makeIcon(brandMark, ICONS.Sparkles, 20, COLORS.White)
brandIcon.AnchorPoint, brandIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
local brandTitle = makeLabel(sidebar, "HINA", 17, COLORS.Text, FONT_BOLD)
brandTitle.Position, brandTitle.Size = UDim2.fromOffset(66, 18), UDim2.fromOffset(100, 21)
local brandSubtitle = makeLabel(sidebar, "EXPEDITIONS", 10, COLORS.TextMuted, FONT_SEMIBOLD)
brandSubtitle.Position, brandSubtitle.Size = UDim2.fromOffset(66, 39), UDim2.fromOffset(112, 16)
local navCaption = makeLabel(sidebar, "WORKSPACE", 10, COLORS.TextDim, FONT_BOLD)
navCaption.Position, navCaption.Size = UDim2.fromOffset(18, 88), UDim2.new(1, -36, 0, 16)
local navContainer = create("Frame", { Position = UDim2.fromOffset(12, 111), Size = UDim2.new(1, -24, 0, 150), BackgroundTransparency = 1 }, sidebar)
create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, navContainer)

local tabButtons = {}
local function createNavButton(tabName, title, subtitle, iconAsset, layoutOrder)
    local active = UIModule.CurrentTab == tabName
    local button = create("TextButton", {
        Name = tabName, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar,
        BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = layoutOrder,
    }, navContainer)
    addCorner(button, 10)
    local stroke = addStroke(button, active and COLORS.Violet or COLORS.Sidebar, active and 0.35 or 1, 1)
    local indicator = create("Frame", { Position = UDim2.new(0, 0, 0.5, -12), Size = UDim2.fromOffset(3, 24), BackgroundColor3 = COLORS.VioletBright, BackgroundTransparency = active and 0 or 1, BorderSizePixel = 0 }, button)
    addCorner(indicator, 3)
    local iconBack = create("Frame", { Position = UDim2.fromOffset(11, 8), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = active and COLORS.Violet or COLORS.Surface, BackgroundTransparency = active and 0.78 or 0, BorderSizePixel = 0 }, button)
    addCorner(iconBack, 8)
    local icon = makeIcon(iconBack, iconAsset, 15, active and COLORS.VioletBright or COLORS.TextMuted)
    icon.AnchorPoint, icon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    local titleLabel = makeLabel(button, title, 13, active and COLORS.Text or COLORS.TextMuted, FONT_SEMIBOLD)
    titleLabel.Position, titleLabel.Size = UDim2.fromOffset(49, 5), UDim2.new(1, -57, 0, 19)
    local subtitleLabel = makeLabel(button, subtitle, 10, COLORS.TextDim, FONT_MEDIUM)
    subtitleLabel.Position, subtitleLabel.Size = UDim2.fromOffset(49, 23), UDim2.new(1, -57, 0, 15)
    tabButtons[tabName] = { Button = button, Stroke = stroke, Indicator = indicator, IconBack = iconBack, Icon = icon, Title = titleLabel }
    return button
end

local evolveTab = createNavButton("Evolve", "Evolution Lab", "Craft & evolve", ICONS.Sparkles, 1)
local sellTab = createNavButton("Sell", "Unit Cleaner", "Filter & protect", ICONS.Cleaner, 2)
local teamTab = createNavButton("Team", "Automation", "Runtime options", ICONS.Settings, 3)

local safetyCard = create("Frame", { Position = UDim2.new(0, 12, 1, -142), Size = UDim2.new(1, -24, 0, 72), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0 }, sidebar)
addCorner(safetyCard, 11); addStroke(safetyCard, COLORS.BorderSoft, 0.15, 1)
local safetyIconBack = create("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = COLORS.Green, BackgroundTransparency = 0.84, BorderSizePixel = 0 }, safetyCard)
addCorner(safetyIconBack, 8)
local safetyIcon = makeIcon(safetyIconBack, ICONS.Shield, 15, COLORS.Green)
safetyIcon.AnchorPoint, safetyIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
local safetyTitle = makeLabel(safetyCard, "Runtime protected", 12, COLORS.Text, FONT_SEMIBOLD)
safetyTitle.Position, safetyTitle.Size = UDim2.fromOffset(46, 8), UDim2.new(1, -54, 0, 20)
local safetyText = makeLabel(safetyCard, "Replica sync + retry guard", 10, COLORS.TextDim, FONT_MEDIUM)
safetyText.Position, safetyText.Size = UDim2.fromOffset(46, 27), UDim2.new(1, -54, 0, 17)
local safetyLine = create("Frame", { Position = UDim2.fromOffset(10, 53), Size = UDim2.new(1, -20, 0, 3), BackgroundColor3 = COLORS.SurfaceRaised, BorderSizePixel = 0 }, safetyCard)
addCorner(safetyLine, 3)
local safetyFill = create("Frame", { Size = UDim2.new(0.78, 0, 1, 0), BackgroundColor3 = COLORS.Green, BorderSizePixel = 0 }, safetyLine)
addCorner(safetyFill, 3)

local unloadButton = create("TextButton", { Position = UDim2.new(0, 12, 1, -56), Size = UDim2.new(1, -24, 0, 40), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, sidebar)
addCorner(unloadButton, 10)
local unloadStroke = addStroke(unloadButton, COLORS.BorderSoft, 0.1, 1)
local unloadIcon = makeIcon(unloadButton, ICONS.Close, 15, COLORS.Red); unloadIcon.Position = UDim2.fromOffset(13, 12)
local unloadLabel = makeLabel(unloadButton, "Unload runtime", 12, COLORS.TextMuted, FONT_SEMIBOLD)
unloadLabel.Position, unloadLabel.Size = UDim2.fromOffset(38, 0), UDim2.new(1, -48, 1, 0)
bindHover(unloadButton, COLORS.Surface, COLORS.SurfaceHover, unloadStroke, COLORS.BorderSoft, COLORS.Red)

local content = create("Frame", { Position = UDim2.fromOffset(204, 0), Size = UDim2.new(1, -204, 1, 0), BackgroundTransparency = 1 }, mainFrame)
local header = create("Frame", { Size = UDim2.new(1, 0, 0, 78), BackgroundTransparency = 1 }, content)
local pageTitle = makeLabel(header, "Evolution Lab", 20, COLORS.Text, FONT_BOLD)
pageTitle.Position, pageTitle.Size = UDim2.fromOffset(24, 17), UDim2.new(0, 250, 0, 26)
local pageSubtitle = makeLabel(header, "Plan materials and evolve your strongest unit safely.", 11, COLORS.TextMuted, FONT_MEDIUM)
pageSubtitle.Position, pageSubtitle.Size = UDim2.fromOffset(24, 43), UDim2.new(0, 390, 0, 18)
local onlinePill = create("Frame", { Position = UDim2.new(1, -216, 0, 23), Size = UDim2.fromOffset(112, 28), BackgroundColor3 = COLORS.Green, BackgroundTransparency = 0.88, BorderSizePixel = 0 }, header)
addCorner(onlinePill, 14); addStroke(onlinePill, COLORS.Green, 0.62, 1)
local onlineDot = create("Frame", { Position = UDim2.fromOffset(11, 11), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = COLORS.Green, BorderSizePixel = 0 }, onlinePill); addCorner(onlineDot, 6)
local onlineText = makeLabel(onlinePill, "RUNTIME READY", 9, COLORS.Green, FONT_BOLD)
onlineText.Position, onlineText.Size = UDim2.fromOffset(23, 0), UDim2.new(1, -29, 1, 0)
local closeButton = create("TextButton", { Position = UDim2.new(1, -52, 0, 21), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, header)
addCorner(closeButton, 9)
local closeStroke = addStroke(closeButton, COLORS.BorderSoft, 0.1, 1)
local closeIcon = makeIcon(closeButton, ICONS.Close, 14, COLORS.TextMuted)
closeIcon.AnchorPoint, closeIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
bindHover(closeButton, COLORS.Surface, COLORS.SurfaceHover, closeStroke, COLORS.BorderSoft, COLORS.Red)

local viewHost = create("Frame", { Position = UDim2.fromOffset(20, 78), Size = UDim2.new(1, -40, 1, -96), BackgroundTransparency = 1 }, content)

local function createPanel(parent, position, size, title, subtitle, iconAsset, accent)
    local panel = create("Frame", { Position = position, Size = size, BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0 }, parent)
    addCorner(panel, 13); addStroke(panel, COLORS.BorderSoft, 0.05, 1)
    local iconBack = create("Frame", { Position = UDim2.fromOffset(14, 13), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = accent or COLORS.Violet, BackgroundTransparency = 0.84, BorderSizePixel = 0 }, panel)
    addCorner(iconBack, 8)
    local icon = makeIcon(iconBack, iconAsset, 16, accent or COLORS.VioletBright)
    icon.AnchorPoint, icon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    local titleLabel = makeLabel(panel, title, 13, COLORS.Text, FONT_SEMIBOLD)
    titleLabel.Position, titleLabel.Size = UDim2.fromOffset(54, 10), UDim2.new(1, -68, 0, 21)
    local subtitleLabel = makeLabel(panel, subtitle, 10, COLORS.TextDim, FONT_MEDIUM)
    subtitleLabel.Position, subtitleLabel.Size = UDim2.fromOffset(54, 29), UDim2.new(1, -68, 0, 17)
    create("Frame", { Position = UDim2.fromOffset(14, 56), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = COLORS.BorderSoft, BorderSizePixel = 0 }, panel)
    local body = create("Frame", { Position = UDim2.fromOffset(14, 69), Size = UDim2.new(1, -28, 1, -83), BackgroundTransparency = 1 }, panel)
    return panel, body, titleLabel, subtitleLabel
end

local function createScroll(parent)
    local scroll = create("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.Violet, ScrollBarImageTransparency = 0.35, AutomaticCanvasSize = Enum.AutomaticSize.None }, parent)
    local layout = create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
    table.insert(UIModule.Connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 4)
    end))
    return scroll, layout
end

local function createActionButton(parent, text, iconAsset, color)
    local button = create("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = color, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, parent)
    addCorner(button, 10)
    create("UIGradient", { Color = ColorSequence.new(color:Lerp(COLORS.White, 0.12), color:Lerp(COLORS.Black, 0.08)), Rotation = 12 }, button)
    local icon = makeIcon(button, iconAsset, 16, COLORS.White); icon.Position = UDim2.new(0.5, -84, 0.5, -8)
    local label = makeLabel(button, text, 12, COLORS.White, FONT_BOLD, Enum.TextXAlignment.Center); label.Size = UDim2.fromScale(1, 1)
    bindHover(button, color, color:Lerp(COLORS.White, 0.08))
    return button, label
end

local function createMiniButton(parent, text, iconAsset, position, size)
    local button = create("TextButton", { Position = position, Size = size, BackgroundColor3 = COLORS.SurfaceRaised, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, parent)
    addCorner(button, 9)
    local stroke = addStroke(button, COLORS.Border, 0.2, 1)
    local icon = makeIcon(button, iconAsset, 13, COLORS.TextMuted); icon.Position = UDim2.fromOffset(11, 10)
    local label = makeLabel(button, text, 11, COLORS.TextMuted, FONT_SEMIBOLD); label.Position, label.Size = UDim2.fromOffset(32, 0), UDim2.new(1, -39, 1, 0)
    bindHover(button, COLORS.SurfaceRaised, COLORS.SurfaceHover, stroke, COLORS.Border, COLORS.Violet)
    return button, label
end

-- Evolution workspace.
local evolveView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, viewHost)
local _, evoListBody, _, evoListSubtitle = createPanel(evolveView, UDim2.fromOffset(0, 0), UDim2.new(0.55, -7, 1, 0), "Evolution candidates", "0 eligible units", ICONS.Team, COLORS.Violet)
local evoListControls = create("Frame", { Position = UDim2.new(0, 0, 1, -38), Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, evoListBody)
local evoSelectAllButton = createMiniButton(evoListControls, "Select all", ICONS.CheckAll, UDim2.fromOffset(0, 2), UDim2.new(0.5, -4, 0, 34))
local evoClearButton = createMiniButton(evoListControls, "Clear", ICONS.Clear, UDim2.new(0.5, 4, 0, 2), UDim2.new(0.5, -4, 0, 34))
local evoListHost = create("Frame", { Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1 }, evoListBody)
local evoListScroll = createScroll(evoListHost)
local evoRight = create("Frame", { Position = UDim2.new(0.55, 7, 0, 0), Size = UDim2.new(0.45, -7, 1, 0), BackgroundTransparency = 1 }, evolveView)
local _, materialBody, _, materialSubtitle = createPanel(evoRight, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 226), "Material plan", "Live inventory requirements", ICONS.Flask, COLORS.Cyan)
local materialScroll = createScroll(materialBody)
local logPanel = create("Frame", { Position = UDim2.fromOffset(0, 238), Size = UDim2.new(1, 0, 1, -294), BackgroundColor3 = COLORS.Sidebar, BorderSizePixel = 0 }, evoRight)
addCorner(logPanel, 12); addStroke(logPanel, COLORS.BorderSoft, 0.05, 1)
local logIcon = makeIcon(logPanel, ICONS.Terminal, 14, COLORS.Green); logIcon.Position = UDim2.fromOffset(12, 11)
local logTitle = makeLabel(logPanel, "LIVE ACTIVITY", 9, COLORS.TextDim, FONT_BOLD); logTitle.Position, logTitle.Size = UDim2.fromOffset(34, 7), UDim2.new(1, -46, 0, 22)
local logBox = makeLabel(logPanel, "Ready. Waiting for an action...", 10, COLORS.TextMuted, FONT_MONO)
logBox.Position, logBox.Size = UDim2.fromOffset(12, 31), UDim2.new(1, -24, 1, -42)
logBox.TextYAlignment, logBox.TextWrapped, logBox.TextTruncate = Enum.TextYAlignment.Top, true, Enum.TextTruncate.None
local evoActionButton, evoActionLabel = createActionButton(evoRight, "Craft & evolve selected", ICONS.Wand, COLORS.Violet)
evoActionButton.Position = UDim2.new(0, 0, 1, -44)

-- Inventory cleaner workspace.
local sellView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, viewHost)
local _, sellListBody, _, sellListSubtitle = createPanel(sellView, UDim2.fromOffset(0, 0), UDim2.new(0.62, -7, 1, 0), "Inventory units", "0 visible units", ICONS.Team, COLORS.Blue)
local sellListHost = create("Frame", { Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1 }, sellListBody)
local sellListScroll = createScroll(sellListHost)
local sellControls = create("Frame", { Position = UDim2.new(0, 0, 1, -38), Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, sellListBody)
local sellSelectButton = createMiniButton(sellControls, "Select filtered", ICONS.Filter, UDim2.fromOffset(0, 2), UDim2.new(0.5, -4, 0, 34))
local sellClearButton = createMiniButton(sellControls, "Clear", ICONS.Clear, UDim2.new(0.5, 4, 0, 2), UDim2.new(0.5, -4, 0, 34))
local sellRight = create("Frame", { Position = UDim2.new(0.62, 7, 0, 0), Size = UDim2.new(0.38, -7, 1, 0), BackgroundTransparency = 1 }, sellView)
local _, filterBody = createPanel(sellRight, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 238), "Rarity filters", "Choose eligible unit tiers", ICONS.Filter, COLORS.Amber)
local filterContainer = create("Frame", { Size = UDim2.new(1, 0, 0, 124), BackgroundTransparency = 1 }, filterBody)
create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 34), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, filterContainer)
local protectedNotice = create("Frame", { Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = COLORS.Green, BackgroundTransparency = 0.9, BorderSizePixel = 0 }, filterBody)
addCorner(protectedNotice, 9); addStroke(protectedNotice, COLORS.Green, 0.62, 1)
local protectedIcon = makeIcon(protectedNotice, ICONS.Shield, 14, COLORS.Green); protectedIcon.Position = UDim2.fromOffset(10, 14)
local protectedText = makeLabel(protectedNotice, "Locked & high-tier units stay protected", 10, COLORS.Green, FONT_SEMIBOLD)
protectedText.Position, protectedText.Size = UDim2.fromOffset(31, 0), UDim2.new(1, -39, 1, 0)
local selectedCard = create("Frame", { Position = UDim2.fromOffset(0, 250), Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0 }, sellRight)
addCorner(selectedCard, 12); addStroke(selectedCard, COLORS.BorderSoft, 0.05, 1)
local selectedCaption = makeLabel(selectedCard, "SELECTED FOR CLEANUP", 9, COLORS.TextDim, FONT_BOLD); selectedCaption.Position, selectedCaption.Size = UDim2.fromOffset(14, 11), UDim2.new(1, -28, 0, 18)
local selectedCountLabel = makeLabel(selectedCard, "0", 28, COLORS.Text, FONT_BOLD); selectedCountLabel.Position, selectedCountLabel.Size = UDim2.fromOffset(14, 28), UDim2.new(0.45, 0, 0, 38)
local selectedHint = makeLabel(selectedCard, "units", 11, COLORS.TextMuted, FONT_MEDIUM, Enum.TextXAlignment.Right); selectedHint.Position, selectedHint.Size = UDim2.new(0.45, 0, 0, 37), UDim2.new(0.55, -14, 0, 24)
local sellActionButton, sellActionLabel = createActionButton(sellRight, "Sell selected (0)", ICONS.Cleaner, COLORS.Red)
sellActionButton.Position = UDim2.new(0, 0, 1, -44)

-- Automation workspace.
local teamView = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, viewHost)
local automationHero = create("Frame", { Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0, ClipsDescendants = true }, teamView)
addCorner(automationHero, 13); addStroke(automationHero, COLORS.Violet, 0.68, 1)
local heroGlow = create("Frame", { Position = UDim2.new(1, -150, 0, -70), Size = UDim2.fromOffset(220, 220), BackgroundColor3 = COLORS.Violet, BackgroundTransparency = 0.9, BorderSizePixel = 0 }, automationHero); addCorner(heroGlow, 110)
local heroIconBack = create("Frame", { Position = UDim2.fromOffset(16, 17), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = COLORS.Violet, BackgroundTransparency = 0.78, BorderSizePixel = 0 }, automationHero); addCorner(heroIconBack, 16)
local heroIcon = makeIcon(heroIconBack, ICONS.Ghost, 27, COLORS.VioletBright); heroIcon.AnchorPoint, heroIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
local heroTitle = makeLabel(automationHero, "Automation control center", 16, COLORS.Text, FONT_BOLD); heroTitle.Position, heroTitle.Size = UDim2.fromOffset(88, 18), UDim2.new(1, -190, 0, 24)
local heroText = makeLabel(automationHero, "Runtime switches apply instantly and remain isolated from game UI settings.", 11, COLORS.TextMuted, FONT_MEDIUM); heroText.Position, heroText.Size = UDim2.fromOffset(88, 42), UDim2.new(1, -190, 0, 20)
local heroBadge = create("Frame", { Position = UDim2.new(1, -111, 0, 28), Size = UDim2.fromOffset(91, 30), BackgroundColor3 = COLORS.Green, BackgroundTransparency = 0.86, BorderSizePixel = 0 }, automationHero); addCorner(heroBadge, 15)
local heroBadgeLabel = makeLabel(heroBadge, "SYNCED", 10, COLORS.Green, FONT_BOLD, Enum.TextXAlignment.Center); heroBadgeLabel.Size = UDim2.fromScale(1, 1)
local togglesPanel = create("Frame", { Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 1, -104), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0 }, teamView)
addCorner(togglesPanel, 13); addStroke(togglesPanel, COLORS.BorderSoft, 0.05, 1)
local toggleHeaderIcon = makeIcon(togglesPanel, ICONS.Settings, 15, COLORS.Blue); toggleHeaderIcon.Position = UDim2.fromOffset(16, 16)
local toggleHeaderTitle = makeLabel(togglesPanel, "Runtime modules", 13, COLORS.Text, FONT_SEMIBOLD); toggleHeaderTitle.Position, toggleHeaderTitle.Size = UDim2.fromOffset(42, 10), UDim2.new(1, -58, 0, 24)
local toggleHeaderText = makeLabel(togglesPanel, "Enable only the systems you want this session.", 10, COLORS.TextDim, FONT_MEDIUM); toggleHeaderText.Position, toggleHeaderText.Size = UDim2.fromOffset(42, 31), UDim2.new(1, -58, 0, 17)
create("Frame", { Position = UDim2.fromOffset(14, 58), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = COLORS.BorderSoft, BorderSizePixel = 0 }, togglesPanel)
local teamCard = create("ScrollingFrame", { Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 1, -84), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.Violet, ScrollBarImageTransparency = 0.35, CanvasSize = UDim2.fromOffset(0, 0) }, togglesPanel)
local teamLayout = create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, teamCard)
table.insert(UIModule.Connections, teamLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teamCard.CanvasSize = UDim2.fromOffset(0, teamLayout.AbsoluteContentSize.Y + 4)
end))

local pageMeta = {
    Evolve = { Title = "Evolution Lab", Subtitle = "Plan materials and evolve your strongest unit safely." },
    Sell = { Title = "Unit Cleaner", Subtitle = "Review inventory, apply rarity filters, and sell with safeguards." },
    Team = { Title = "Automation", Subtitle = "Control the runtime modules used by the current session." },
}

local function refreshSelectionLabels()
    local evoCount = countSelected(UIModule.SelectedEvoUnits)
    evoActionLabel.Text = evoCount > 0 and string.format("Craft & evolve selected (%d)", evoCount) or "Craft & evolve ready units"
    local sellCount = countSelected(UIModule.SelectedSellUnits)
    selectedCountLabel.Text = tostring(sellCount)
    sellActionLabel.Text = string.format("Sell selected (%d)", sellCount)
end

function UIModule:SetState(open)
    self.IsOpen = open == true
    if self.IsOpen then
        mainFrame.Visible, mainShadow.Visible = true, true
        mainFrame.Size, mainFrame.GroupTransparency = UDim2.fromOffset(872, 542), 1
        mainShadow.BackgroundTransparency = 1
        TweenService:Create(mainFrame, TWEEN_NORMAL, { Size = UDim2.fromOffset(900, 560), GroupTransparency = 0 }):Play()
        TweenService:Create(mainShadow, TWEEN_NORMAL, { BackgroundTransparency = 0.44 }):Play()
        if self.Callbacks.OnRefresh then task.spawn(self.Callbacks.OnRefresh) end
    else
        TweenService:Create(mainFrame, TWEEN_FAST, { GroupTransparency = 1 }):Play()
        TweenService:Create(mainShadow, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
        task.delay(TWEEN_FAST.Time, function()
            if not self.IsOpen then mainFrame.Visible, mainShadow.Visible = false, false end
        end)
    end
end

function UIModule:SwitchTab(tabName)
    if not pageMeta[tabName] then return end
    self.CurrentTab = tabName
    pageTitle.Text, pageSubtitle.Text = pageMeta[tabName].Title, pageMeta[tabName].Subtitle
    for name, tab in pairs(tabButtons) do
        local active = name == tabName
        TweenService:Create(tab.Button, TWEEN_FAST, { BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar }):Play()
        TweenService:Create(tab.Stroke, TWEEN_FAST, { Color = active and COLORS.Violet or COLORS.Sidebar, Transparency = active and 0.35 or 1 }):Play()
        TweenService:Create(tab.Indicator, TWEEN_FAST, { BackgroundTransparency = active and 0 or 1 }):Play()
        TweenService:Create(tab.IconBack, TWEEN_FAST, { BackgroundColor3 = active and COLORS.Violet or COLORS.Surface, BackgroundTransparency = active and 0.78 or 0 }):Play()
        TweenService:Create(tab.Icon, TWEEN_FAST, { ImageColor3 = active and COLORS.VioletBright or COLORS.TextMuted }):Play()
        TweenService:Create(tab.Title, TWEEN_FAST, { TextColor3 = active and COLORS.Text or COLORS.TextMuted }):Play()
    end
    evolveView.Visible, sellView.Visible, teamView.Visible = tabName == "Evolve", tabName == "Sell", tabName == "Team"
    if self.Callbacks.OnRefresh then task.spawn(self.Callbacks.OnRefresh) end
end

evolveTab.Activated:Connect(function() UIModule:SwitchTab("Evolve") end)
sellTab.Activated:Connect(function() UIModule:SwitchTab("Sell") end)
teamTab.Activated:Connect(function() UIModule:SwitchTab("Team") end)
closeButton.Activated:Connect(function() UIModule:SetState(false) end)
unloadButton.Activated:Connect(function() if UIModule.Callbacks.OnUnload then UIModule.Callbacks.OnUnload() end end)

local dragging, dragStart, windowStart = false, Vector2.zero, UDim2.fromScale(0.5, 0.5)
table.insert(UIModule.Connections, header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, windowStart = true, input.Position, mainFrame.Position
    end
end))
table.insert(UIModule.Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end))
table.insert(UIModule.Connections, UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + delta.X, windowStart.Y.Scale, windowStart.Y.Offset + delta.Y)
        mainShadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset + 8)
    end
end))

function UIModule:AppendLog(message)
    local lines = string.split(logBox.Text, "\n")
    if #lines == 1 and lines[1] == "Ready. Waiting for an action..." then table.clear(lines) end
    while #lines >= 6 do table.remove(lines, 1) end
    table.insert(lines, string.format("[%s] %s", os.date("%H:%M:%S"), tostring(message)))
    logBox.Text = table.concat(lines, "\n")
end

local TOGGLE_DESCRIPTIONS = {
    Craft = "Synthesize missing evolution materials with replica confirmation.",
    Evolve = "Evolve the best eligible candidate when every requirement is ready.",
    Trial = "Launch the matching unit trial when only its quest item is missing.",
    Cleaner = "Remove safe duplicates when inventory pressure reaches the threshold.",
    Summon = "Use the standard banner automation while it is enabled.",
    Lobby = "Return safely when the configured Sprite Grey cap is reached.",
    HINAHUB = "Start the external HinaHub automation module in the lobby.",
}
local function getToggleDescription(name)
    for key, description in pairs(TOGGLE_DESCRIPTIONS) do if name:find(key, 1, true) then return description end end
    return "Enable or disable this runtime module for the current session."
end

function UIModule:CreateToggle(name, defaultState, isAccentViolet, onToggle)
    local active, accent = defaultState == true, isAccentViolet and COLORS.Violet or COLORS.Blue
    local row = create("TextButton", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, teamCard)
    addCorner(row, 11)
    local rowStroke = addStroke(row, active and accent or COLORS.BorderSoft, active and 0.48 or 0.2, 1)
    local iconBack = create("Frame", { Position = UDim2.fromOffset(11, 11), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = active and accent or COLORS.SurfaceRaised, BackgroundTransparency = active and 0.82 or 0, BorderSizePixel = 0 }, row); addCorner(iconBack, 10)
    local rowIcon = makeIcon(iconBack, ICONS.Settings, 18, active and accent or COLORS.TextDim); rowIcon.AnchorPoint, rowIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    local title = makeLabel(row, name, 12, active and COLORS.Text or COLORS.TextMuted, FONT_SEMIBOLD); title.Position, title.Size = UDim2.fromOffset(62, 8), UDim2.new(1, -132, 0, 21)
    local description = makeLabel(row, getToggleDescription(name), 10, COLORS.TextDim, FONT_MEDIUM); description.Position, description.Size = UDim2.fromOffset(62, 29), UDim2.new(1, -132, 0, 19)
    local switch = create("Frame", { Position = UDim2.new(1, -57, 0.5, -13), Size = UDim2.fromOffset(46, 26), BackgroundColor3 = active and accent or COLORS.SurfaceRaised, BorderSizePixel = 0 }, row); addCorner(switch, 13)
    local switchStroke = addStroke(switch, active and accent or COLORS.Border, active and 0.25 or 0.1, 1)
    local knob = create("Frame", { Position = active and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = active and COLORS.White or COLORS.TextDim, BorderSizePixel = 0 }, switch); addCorner(knob, 10)
    local function render()
        TweenService:Create(row, TWEEN_FAST, { BackgroundColor3 = active and COLORS.SurfaceRaised or COLORS.Sidebar }):Play()
        TweenService:Create(rowStroke, TWEEN_FAST, { Color = active and accent or COLORS.BorderSoft, Transparency = active and 0.48 or 0.2 }):Play()
        TweenService:Create(iconBack, TWEEN_FAST, { BackgroundColor3 = active and accent or COLORS.SurfaceRaised, BackgroundTransparency = active and 0.82 or 0 }):Play()
        TweenService:Create(rowIcon, TWEEN_FAST, { ImageColor3 = active and accent or COLORS.TextDim }):Play()
        TweenService:Create(title, TWEEN_FAST, { TextColor3 = active and COLORS.Text or COLORS.TextMuted }):Play()
        TweenService:Create(switch, TWEEN_FAST, { BackgroundColor3 = active and accent or COLORS.SurfaceRaised }):Play()
        TweenService:Create(switchStroke, TWEEN_FAST, { Color = active and accent or COLORS.Border }):Play()
        TweenService:Create(knob, TWEEN_FAST, { Position = active and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = active and COLORS.White or COLORS.TextDim }):Play()
    end
    row.Activated:Connect(function()
        active = not active; render()
        if onToggle then task.spawn(onToggle, active) end
    end)
    return row
end

function UIModule:UpdateMaterials(materials)
    clearGuiRows(materialScroll)
    local sorted = table.clone(materials or {})
    table.sort(sorted, function(a, b)
        if (a.Deficit or 0) ~= (b.Deficit or 0) then return (a.Deficit or 0) > (b.Deficit or 0) end
        return tostring(a.DisplayName) < tostring(b.DisplayName)
    end)
    materialSubtitle.Text = string.format("%d tracked requirements", #sorted)
    if #sorted == 0 then
        local empty = makeLabel(materialScroll, "No materials required yet.", 11, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center); empty.Size = UDim2.new(1, 0, 0, 46)
        return
    end
    for order, material in ipairs(sorted) do
        local current, needed = tonumber(material.Current) or 0, tonumber(material.Needed) or 0
        local deficit = tonumber(material.Deficit) or math.max(0, needed - current)
        local ready = deficit <= 0
        local row = create("Frame", { Size = UDim2.new(1, -3, 0, 45), BackgroundColor3 = COLORS.Sidebar, BorderSizePixel = 0, LayoutOrder = order }, materialScroll)
        addCorner(row, 9); addStroke(row, ready and COLORS.Green or COLORS.BorderSoft, ready and 0.7 or 0.2, 1)
        local name = makeLabel(row, tostring(material.DisplayName or "Material"), 11, COLORS.Text, FONT_SEMIBOLD); name.Position, name.Size = UDim2.fromOffset(10, 5), UDim2.new(0.62, -10, 0, 18)
        local amount = makeLabel(row, string.format("%d / %d", current, needed), 10, COLORS.TextMuted, FONT_MEDIUM, Enum.TextXAlignment.Right); amount.Position, amount.Size = UDim2.new(0.62, 0, 0, 5), UDim2.new(0.38, -10, 0, 18)
        local track = create("Frame", { Position = UDim2.fromOffset(10, 29), Size = UDim2.new(1, -20, 0, 5), BackgroundColor3 = COLORS.SurfaceRaised, BorderSizePixel = 0 }, row); addCorner(track, 5)
        local ratio = needed > 0 and math.clamp(current / needed, 0, 1) or 1
        local fill = create("Frame", { Size = UDim2.new(ratio, 0, 1, 0), BackgroundColor3 = ready and COLORS.Green or COLORS.Cyan, BorderSizePixel = 0 }, track); addCorner(fill, 5)
    end
end

local function makeSelectionIndicator(parent, selected, accent)
    local circle = create("Frame", { Position = UDim2.new(1, -35, 0.5, -11), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = selected and accent or COLORS.SurfaceRaised, BorderSizePixel = 0 }, parent)
    addCorner(circle, 11); addStroke(circle, selected and accent or COLORS.Border, selected and 0.2 or 0.05, 1)
    if selected then
        local check = makeIcon(circle, ICONS.Check, 12, COLORS.White); check.AnchorPoint, check.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    end
end

function UIModule:UpdateEvoList(candidates)
    self.CachedEvoCandidates = candidates or {}
    clearGuiRows(evoListScroll)
    evoListSubtitle.Text = string.format("%d eligible unit%s", #self.CachedEvoCandidates, #self.CachedEvoCandidates == 1 and "" or "s")
    if #self.CachedEvoCandidates == 0 then
        local empty = makeLabel(evoListScroll, "No evolution candidate is ready.", 11, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center); empty.Size = UDim2.new(1, -3, 0, 64)
        return
    end
    for order, unit in ipairs(self.CachedEvoCandidates) do
        local id, rarity = tostring(unit.Id), tostring(unit.Rarity or "Unknown")
        local selected, rarityColor = self.SelectedEvoUnits[id] == true, RARITY_COLORS[rarity] or COLORS.TextDim
        local row = create("TextButton", { Size = UDim2.new(1, -3, 0, 58), BackgroundColor3 = selected and COLORS.SurfaceHover or COLORS.Sidebar, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order }, evoListScroll)
        addCorner(row, 10)
        local rowStroke = addStroke(row, selected and COLORS.Violet or COLORS.BorderSoft, selected and 0.25 or 0.2, 1)
        local accent = create("Frame", { Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(3, 38), BackgroundColor3 = rarityColor, BorderSizePixel = 0 }, row); addCorner(accent, 3)
        local name = makeLabel(row, string.format("%s  ·  Lv.%d", tostring(unit.DisplayName or unit.Asset or "Unit"), tonumber(unit.Level) or 1), 12, COLORS.Text, FONT_SEMIBOLD); name.Position, name.Size = UDim2.fromOffset(13, 7), UDim2.new(1, -54, 0, 20)
        local detail = makeLabel(row, string.format("%s  /  %s  /  %d materials", rarity:upper(), tostring(unit.Trait or "No Trait"), tonumber(unit.ReqCount) or 0), 10, rarityColor, FONT_MEDIUM); detail.Position, detail.Size = UDim2.fromOffset(13, 29), UDim2.new(1, -54, 0, 18)
        makeSelectionIndicator(row, selected, COLORS.Violet)
        bindHover(row, selected and COLORS.SurfaceHover or COLORS.Sidebar, COLORS.SurfaceHover, rowStroke, selected and COLORS.Violet or COLORS.BorderSoft, COLORS.Violet)
        row.Activated:Connect(function()
            UIModule.SelectedEvoUnits[id] = UIModule.SelectedEvoUnits[id] and nil or true
            refreshSelectionLabels(); UIModule:UpdateEvoList(UIModule.CachedEvoCandidates)
        end)
    end
    refreshSelectionLabels()
end

function UIModule:UpdateSellList(units)
    self.CachedSellUnits = units or {}
    clearGuiRows(sellListScroll)
    local visibleCount = 0
    for _, unit in ipairs(self.CachedSellUnits) do if self.SellFilters[tostring(unit.Rarity)] then visibleCount = visibleCount + 1 end end
    sellListSubtitle.Text = string.format("%d visible of %d owned", visibleCount, #self.CachedSellUnits)
    if visibleCount == 0 then
        local empty = makeLabel(sellListScroll, "No units match the active rarity filters.", 11, COLORS.TextDim, FONT_MEDIUM, Enum.TextXAlignment.Center); empty.Size = UDim2.new(1, -3, 0, 64)
        return
    end
    local layoutOrder = 0
    for _, unit in ipairs(self.CachedSellUnits) do
        local rarity = tostring(unit.Rarity or "Unknown")
        if self.SellFilters[rarity] then
            layoutOrder = layoutOrder + 1
            local id, protected = tostring(unit.Id), unit.IsProtected == true
            local selected, rarityColor = self.SelectedSellUnits[id] == true and not protected, RARITY_COLORS[rarity] or COLORS.TextDim
            local row = create("TextButton", { Size = UDim2.new(1, -3, 0, 58), BackgroundColor3 = selected and COLORS.SurfaceHover or COLORS.Sidebar, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = layoutOrder }, sellListScroll)
            addCorner(row, 10)
            local rowStroke = addStroke(row, selected and COLORS.Red or COLORS.BorderSoft, selected and 0.3 or 0.2, 1)
            local name = makeLabel(row, string.format("%s  ·  Lv.%d", tostring(unit.DisplayName or unit.Asset or "Unit"), tonumber(unit.Level) or 1), 12, protected and COLORS.TextMuted or COLORS.Text, FONT_SEMIBOLD); name.Position, name.Size = UDim2.fromOffset(13, 7), UDim2.new(1, -56, 0, 20)
            local detailText = protected and (rarity:upper() .. "  /  PROTECTED") or (rarity:upper() .. "  /  READY TO SELL")
            local detail = makeLabel(row, detailText, 10, protected and COLORS.Green or rarityColor, FONT_MEDIUM); detail.Position, detail.Size = UDim2.fromOffset(13, 29), UDim2.new(1, -56, 0, 18)
            if protected then
                local shield = makeIcon(row, ICONS.Shield, 16, COLORS.Green); shield.Position = UDim2.new(1, -31, 0.5, -8)
            else
                makeSelectionIndicator(row, selected, COLORS.Red)
                bindHover(row, selected and COLORS.SurfaceHover or COLORS.Sidebar, COLORS.SurfaceHover, rowStroke, selected and COLORS.Red or COLORS.BorderSoft, COLORS.Red)
                row.Activated:Connect(function()
                    UIModule.SelectedSellUnits[id] = UIModule.SelectedSellUnits[id] and nil or true
                    refreshSelectionLabels(); UIModule:UpdateSellList(UIModule.CachedSellUnits)
                end)
            end
        end
    end
    refreshSelectionLabels()
end

local function setupFilters()
    clearGuiRows(filterContainer)
    for layoutOrder, rarity in ipairs({ "Rare", "Epic", "Legendary", "Mythic" }) do
        local active, rarityColor = UIModule.SellFilters[rarity] == true, RARITY_COLORS[rarity] or COLORS.TextMuted
        local button = create("TextButton", { BackgroundColor3 = active and COLORS.SurfaceHover or COLORS.Sidebar, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = layoutOrder }, filterContainer)
        addCorner(button, 9)
        local stroke = addStroke(button, active and rarityColor or COLORS.BorderSoft, active and 0.35 or 0.2, 1)
        local dot = create("Frame", { Position = UDim2.fromOffset(10, 13), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = active and rarityColor or COLORS.TextDim, BorderSizePixel = 0 }, button); addCorner(dot, 8)
        local label = makeLabel(button, rarity, 10, active and COLORS.Text or COLORS.TextMuted, FONT_SEMIBOLD); label.Position, label.Size = UDim2.fromOffset(25, 0), UDim2.new(1, -31, 1, 0)
        bindHover(button, active and COLORS.SurfaceHover or COLORS.Sidebar, COLORS.SurfaceHover, stroke, active and rarityColor or COLORS.BorderSoft, rarityColor)
        button.Activated:Connect(function()
            UIModule.SellFilters[rarity] = not UIModule.SellFilters[rarity]
            table.clear(UIModule.SelectedSellUnits)
            setupFilters(); UIModule:UpdateSellList(UIModule.CachedSellUnits)
        end)
    end
end
setupFilters()

evoSelectAllButton.Activated:Connect(function()
    if UIModule.Callbacks.OnSelectAllEvo then UIModule.Callbacks.OnSelectAllEvo() end
    refreshSelectionLabels()
end)
evoClearButton.Activated:Connect(function()
    table.clear(UIModule.SelectedEvoUnits); refreshSelectionLabels(); UIModule:UpdateEvoList(UIModule.CachedEvoCandidates)
end)
sellSelectButton.Activated:Connect(function()
    if UIModule.Callbacks.OnSelectFilteredSell then UIModule.Callbacks.OnSelectFilteredSell() end
    refreshSelectionLabels()
end)
sellClearButton.Activated:Connect(function()
    table.clear(UIModule.SelectedSellUnits); refreshSelectionLabels(); UIModule:UpdateSellList(UIModule.CachedSellUnits)
end)

local evoBusy = false
evoActionButton.Activated:Connect(function()
    if evoBusy or not UIModule.Callbacks.OnEvoAction then return end
    evoBusy = true; evoActionLabel.Text = "Processing evolution plan..."
    task.spawn(function()
        local ok, err = pcall(UIModule.Callbacks.OnEvoAction)
        if not ok then UIModule:AppendLog("Evolution action failed: " .. tostring(err)) end
        evoBusy = false; refreshSelectionLabels()
    end)
end)
local sellBusy = false
sellActionButton.Activated:Connect(function()
    if sellBusy or not UIModule.Callbacks.OnSellAction then return end
    sellBusy = true; sellActionLabel.Text = "Waiting for inventory confirmation..."
    task.spawn(function()
        local ok, err = pcall(UIModule.Callbacks.OnSellAction)
        if not ok then UIModule:AppendLog("Sell action failed: " .. tostring(err)) end
        sellBusy = false; refreshSelectionLabels()
    end)
end)

table.insert(UIModule.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then UIModule:SetState(not UIModule.IsOpen) end
end))

function UIModule:Destroy()
    for _, connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
    table.clear(self.Connections)
    if screenGui then screenGui:Destroy() end
end

refreshSelectionLabels()
task.defer(function() if screenGui.Parent then UIModule:SetState(true) end end)
return UIModule
