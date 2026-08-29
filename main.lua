local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local CTP = {
    Mauve     = Color3.fromRGB(198, 160, 246),
    Red       = Color3.fromRGB(237, 135, 150),
    Blue      = Color3.fromRGB(138, 173, 244),
    Text      = Color3.fromRGB(215, 223, 250),
    Subtext1  = Color3.fromRGB(192, 200, 232),
    Subtext0  = Color3.fromRGB(175, 183, 212),
    Overlay0  = Color3.fromRGB(110, 115, 141),
    Surface1  = Color3.fromRGB(73, 77, 100),
    Surface0  = Color3.fromRGB(44, 47, 65),
    Base      = Color3.fromRGB(18, 19, 28),
    Mantle    = Color3.fromRGB(13, 14, 21),
    Crust     = Color3.fromRGB(9, 10, 15),
}

local UI = {
    Font = Font.fromName("BuilderSans", Enum.FontWeight.Bold),
    RegularFont = Font.fromName("BuilderSans", Enum.FontWeight.Medium),
    MonoFont = Font.fromName("Code", Enum.FontWeight.Medium),
    TitleSize = 15,
    ButtonSize = 13,
    BodySize = 13,
    SecondarySize = 12,
    BadgeSize = 11,
    MonoSize = 12,
    CornerLarge = UDim.new(0, 10),
    CornerMedium = UDim.new(0, 8),
    CornerSmall = UDim.new(0, 6),
    TweenFast = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    TweenNormal = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

local ICONS = {
    Close        = "rbxassetid://116396312853810",
    Evolve       = "rbxassetid://105634041692696",
    Cleaner      = "rbxassetid://113939163175897",
    Team         = "rbxassetid://85332511060401",
    SelectAll    = "rbxassetid://101885204738917",
    Clear        = "rbxassetid://111132030834422",
    Filter       = "rbxassetid://83186010624431",
    ToggleOn     = "rbxassetid://129483325318573",
    ToggleOff    = "rbxassetid://105639191695402",
}

local RARITY_COLORS = {
    ["Secret"]    = Color3.fromRGB(170, 8, 15),
    ["Mythic"]    = Color3.fromRGB(205, 28, 165),
    ["Limited"]   = Color3.fromRGB(205, 28, 165),
    ["Legendary"] = Color3.fromRGB(238, 158, 20),
    ["Epic"]      = Color3.fromRGB(122, 28, 195),
    ["Rare"]      = Color3.fromRGB(0, 125, 235),
    ["Unknown"]   = Color3.fromRGB(110, 115, 141),
}

local UIModule = {
    CurrentTab = "Evolve",
    IsOpen = false,
    Connections = {},
    SelectedEvoUnits = {},
    SelectedSellUnits = {},
    SellFilters = { Rare = true, Epic = true, Legendary = false, Mythic = false },
    Callbacks = {},
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimeExpeditionsManagerGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
local parentTarget = (typeof(gethui) == "function" and gethui()) or CoreGui
if not pcall(function() screenGui.Parent = parentTarget end) then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("CanvasGroup", screenGui)
mainFrame.Size = UDim2.fromOffset(780, 480)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = CTP.Base
mainFrame.BorderSizePixel = 0
mainFrame.GroupTransparency = 1
mainFrame.Visible = false
Instance.new("UICorner", mainFrame).CornerRadius = UI.CornerLarge
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = CTP.Surface0
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = CTP.Mantle
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UI.CornerLarge

local topAccent = Instance.new("Frame", topBar)
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.Position = UDim2.new(0, 0, 1, -2)
topAccent.BorderSizePixel = 0
topAccent.BackgroundColor3 = CTP.Mauve

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Position = UDim2.fromOffset(14, 0)
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.RichText = true
titleLabel.Text = string.format("<font color=\"#%s\"><b>HINA HUB</b></font>  <font color=\"#%s\">|</font>  <font color=\"#%s\">Macro & Trial Manager</font>  <font color=\"#%s\">[RightShift]</font>",
    CTP.Mauve:ToHex(), CTP.Overlay0:ToHex(), CTP.Text:ToHex(), CTP.Subtext0:ToHex())
titleLabel.FontFace = UI.Font
titleLabel.TextSize = UI.TitleSize
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local unloadBtn = Instance.new("TextButton", topBar)
unloadBtn.Size = UDim2.fromOffset(24, 24)
unloadBtn.Position = UDim2.new(1, -32, 0.5, -12)
unloadBtn.BackgroundColor3 = CTP.Surface0
unloadBtn.Text = ""
unloadBtn.AutoButtonColor = false
Instance.new("UICorner", unloadBtn).CornerRadius = UI.CornerSmall
local unloadStroke = Instance.new("UIStroke", unloadBtn)
unloadStroke.Color = CTP.Surface1
unloadStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local unloadIcon = Instance.new("ImageLabel", unloadBtn)
unloadIcon.Size = UDim2.fromOffset(14, 14)
unloadIcon.Position = UDim2.fromScale(0.5, 0.5)
unloadIcon.AnchorPoint = Vector2.new(0.5, 0.5)
unloadIcon.BackgroundTransparency = 1
unloadIcon.Image = ICONS.Close
unloadIcon.ImageColor3 = CTP.Red

local navBar = Instance.new("Frame", mainFrame)
navBar.Position = UDim2.fromOffset(12, 44)
navBar.Size = UDim2.new(1, -24, 0, 28)
navBar.BackgroundTransparency = 1

local tabButtons = {}
local function createTabButton(text, iconAsset, xPos, width, tabName)
    local btn = Instance.new("TextButton", navBar)
    btn.Position = UDim2.new(xPos, 0, 0, 0)
    btn.Size = UDim2.new(width, -4, 1, 0)
    local isActive = (UIModule.CurrentTab == tabName)
    btn.BackgroundColor3 = isActive and CTP.Surface0 or CTP.Mantle
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UI.CornerSmall
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = isActive and CTP.Mauve or CTP.Surface0
    stroke.Thickness = 1
    stroke.Transparency = isActive and 0.25 or 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local icon = Instance.new("ImageLabel", btn)
    icon.Size = UDim2.fromOffset(14, 14)
    icon.Position = UDim2.new(0.5, -42, 0.5, -7)
    icon.BackgroundTransparency = 1
    icon.Image = iconAsset
    icon.ImageColor3 = isActive and CTP.Mauve or CTP.Subtext0

    local label = Instance.new("TextLabel", btn)
    label.Position = UDim2.new(0.5, -22, 0, 0)
    label.Size = UDim2.new(0.5, 22, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = isActive and CTP.Mauve or CTP.Subtext0
    label.FontFace = UI.Font
    label.TextSize = UI.ButtonSize
    label.TextXAlignment = Enum.TextXAlignment.Left

    tabButtons[tabName] = { Button = btn, Stroke = stroke, Label = label, Icon = icon }
    return btn
end

local tabBtnEvo = createTabButton("Evolve", ICONS.Evolve, 0, 0.333, "Evolve")
local tabBtnSell = createTabButton("Cleaner", ICONS.Cleaner, 0.333, 0.333, "Sell")
local tabBtnTeam = createTabButton("Team & Options", ICONS.Team, 0.666, 0.334, "Team")

local viewsContainer = Instance.new("Frame", mainFrame)
viewsContainer.Position = UDim2.fromOffset(12, 78)
viewsContainer.Size = UDim2.new(1, -24, 1, -88)
viewsContainer.BackgroundTransparency = 1

local evolveView = Instance.new("Frame", viewsContainer)
evolveView.Size = UDim2.fromScale(1, 1)
evolveView.BackgroundTransparency = 1

local evoLeftPanel = Instance.new("Frame", evolveView)
evoLeftPanel.Size = UDim2.new(0.50, -5, 1, 0)
evoLeftPanel.BackgroundColor3 = CTP.Mantle
Instance.new("UICorner", evoLeftPanel).CornerRadius = UI.CornerMedium
local evoLeftStroke = Instance.new("UIStroke", evoLeftPanel)
evoLeftStroke.Color = CTP.Surface0
evoLeftStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local evoListScroll = Instance.new("ScrollingFrame", evoLeftPanel)
evoListScroll.Position = UDim2.fromOffset(6, 28)
evoListScroll.Size = UDim2.new(1, -12, 1, -66)
evoListScroll.BackgroundTransparency = 1
evoListScroll.BorderSizePixel = 0
evoListScroll.ScrollBarThickness = 3
evoListScroll.ScrollBarImageColor3 = CTP.Surface1
local evoListLayout = Instance.new("UIListLayout", evoListScroll)
evoListLayout.Padding = UDim.new(0, 4)

local evoBottomBar = Instance.new("Frame", evoLeftPanel)
evoBottomBar.Position = UDim2.new(0, 6, 1, -30)
evoBottomBar.Size = UDim2.new(1, -12, 0, 24)
evoBottomBar.BackgroundTransparency = 1

local function createBottomActionButton(parent, text, iconAsset, size, posX)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size
    btn.Position = UDim2.new(posX, 0, 0, 0)
    btn.BackgroundColor3 = CTP.Surface0
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UI.CornerSmall
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = CTP.Surface1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local icon = Instance.new("ImageLabel", btn)
    icon.Size = UDim2.fromOffset(12, 12)
    icon.Position = UDim2.new(0.5, -34, 0.5, -6)
    icon.BackgroundTransparency = 1
    icon.Image = iconAsset
    icon.ImageColor3 = CTP.Text

    local lbl = Instance.new("TextLabel", btn)
    lbl.Position = UDim2.new(0.5, -18, 0, 0)
    lbl.Size = UDim2.new(0.5, 18, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = CTP.Text
    lbl.FontFace = UI.Font
    lbl.TextSize = UI.ButtonSize
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return btn
end

local evoSelectAllBtn = createBottomActionButton(evoBottomBar, "Select All", ICONS.SelectAll, UDim2.new(0.48, 0, 1, 0), 0)
local evoClearBtn = createBottomActionButton(evoBottomBar, "Clear", ICONS.Clear, UDim2.new(0.48, 0, 1, 0), 0.52)

local evoRightPanel = Instance.new("Frame", evolveView)
evoRightPanel.Position = UDim2.new(0.50, 5, 0, 0)
evoRightPanel.Size = UDim2.new(0.50, -5, 1, 0)
evoRightPanel.BackgroundColor3 = CTP.Mantle
Instance.new("UICorner", evoRightPanel).CornerRadius = UI.CornerMedium
local evoRightStroke = Instance.new("UIStroke", evoRightPanel)
evoRightStroke.Color = CTP.Surface0
evoRightStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local evoMatScroll = Instance.new("ScrollingFrame", evoRightPanel)
evoMatScroll.Position = UDim2.fromOffset(6, 28)
evoMatScroll.Size = UDim2.new(1, -12, 0, 160)
evoMatScroll.BackgroundTransparency = 1
evoMatScroll.BorderSizePixel = 0
evoMatScroll.ScrollBarThickness = 3
evoMatScroll.ScrollBarImageColor3 = CTP.Surface1
local evoMatLayout = Instance.new("UIListLayout", evoMatScroll)
evoMatLayout.Padding = UDim.new(0, 4)

local evoLogBox = Instance.new("TextLabel", evoRightPanel)
evoLogBox.Position = UDim2.fromOffset(6, 194)
evoLogBox.Size = UDim2.new(1, -12, 1, -232)
evoLogBox.BackgroundColor3 = CTP.Crust
evoLogBox.TextColor3 = CTP.Text
evoLogBox.FontFace = UI.MonoFont
evoLogBox.TextSize = UI.MonoSize
evoLogBox.TextXAlignment = Enum.TextXAlignment.Left
evoLogBox.TextYAlignment = Enum.TextYAlignment.Top
evoLogBox.TextWrapped = true
evoLogBox.Text = "Terminal initialized."
Instance.new("UICorner", evoLogBox).CornerRadius = UI.CornerSmall
local evoLogStroke = Instance.new("UIStroke", evoLogBox)
evoLogStroke.Color = CTP.Surface1
evoLogStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local evoLogPadding = Instance.new("UIPadding", evoLogBox)
evoLogPadding.PaddingTop = UDim.new(0, 6)
evoLogPadding.PaddingLeft = UDim.new(0, 8)
evoLogPadding.PaddingRight = UDim.new(0, 8)
evoLogPadding.PaddingBottom = UDim.new(0, 6)

local evoActionBtn = Instance.new("TextButton", evoRightPanel)
evoActionBtn.Position = UDim2.new(0, 6, 1, -32)
evoActionBtn.Size = UDim2.new(1, -12, 0, 26)
evoActionBtn.BackgroundColor3 = CTP.Mauve
evoActionBtn.Text = ""
evoActionBtn.AutoButtonColor = false
Instance.new("UICorner", evoActionBtn).CornerRadius = UI.CornerSmall

local evoActionLabel = Instance.new("TextLabel", evoActionBtn)
evoActionLabel.Size = UDim2.fromScale(1, 1)
evoActionLabel.BackgroundTransparency = 1
evoActionLabel.Text = "Craft & Evolve Now"
evoActionLabel.TextColor3 = CTP.Crust
evoActionLabel.FontFace = UI.Font
evoActionLabel.TextSize = UI.ButtonSize

local sellView = Instance.new("Frame", viewsContainer)
sellView.Size = UDim2.fromScale(1, 1)
sellView.BackgroundTransparency = 1
sellView.Visible = false

local sellLeftPanel = Instance.new("Frame", sellView)
sellLeftPanel.Size = UDim2.new(0.55, -5, 1, 0)
sellLeftPanel.BackgroundColor3 = CTP.Mantle
Instance.new("UICorner", sellLeftPanel).CornerRadius = UI.CornerMedium
local sellLeftStroke = Instance.new("UIStroke", sellLeftPanel)
sellLeftStroke.Color = CTP.Surface0
sellLeftStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local sellListScroll = Instance.new("ScrollingFrame", sellLeftPanel)
sellListScroll.Position = UDim2.fromOffset(6, 28)
sellListScroll.Size = UDim2.new(1, -12, 1, -66)
sellListScroll.BackgroundTransparency = 1
sellListScroll.BorderSizePixel = 0
sellListScroll.ScrollBarThickness = 3
sellListScroll.ScrollBarImageColor3 = CTP.Surface1
local sellListLayout = Instance.new("UIListLayout", sellListScroll)
sellListLayout.Padding = UDim.new(0, 4)

local sellBottomBar = Instance.new("Frame", sellLeftPanel)
sellBottomBar.Position = UDim2.new(0, 6, 1, -30)
sellBottomBar.Size = UDim2.new(1, -12, 0, 24)
sellBottomBar.BackgroundTransparency = 1

local sellSelectFilteredBtn = createBottomActionButton(sellBottomBar, "Select Filtered", ICONS.Filter, UDim2.new(0.48, 0, 1, 0), 0)
local sellClearBtn = createBottomActionButton(sellBottomBar, "Clear", ICONS.Clear, UDim2.new(0.48, 0, 1, 0), 0.52)

local sellRightPanel = Instance.new("Frame", sellView)
sellRightPanel.Position = UDim2.new(0.55, 5, 0, 0)
sellRightPanel.Size = UDim2.new(0.45, -5, 1, 0)
sellRightPanel.BackgroundColor3 = CTP.Mantle
Instance.new("UICorner", sellRightPanel).CornerRadius = UI.CornerMedium
local sellRightStroke = Instance.new("UIStroke", sellRightPanel)
sellRightStroke.Color = CTP.Surface0
sellRightStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local filterContainer = Instance.new("Frame", sellRightPanel)
filterContainer.Position = UDim2.fromOffset(10, 28)
filterContainer.Size = UDim2.new(1, -20, 0, 72)
filterContainer.BackgroundTransparency = 1
local filterLayout = Instance.new("UIGridLayout", filterContainer)
filterLayout.CellSize = UDim2.new(0.48, 0, 0, 28)
filterLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)

local sellActionBtn = Instance.new("TextButton", sellRightPanel)
sellActionBtn.Position = UDim2.new(0, 10, 1, -32)
sellActionBtn.Size = UDim2.new(1, -20, 0, 26)
sellActionBtn.BackgroundColor3 = CTP.Red
sellActionBtn.Text = ""
sellActionBtn.AutoButtonColor = false
Instance.new("UICorner", sellActionBtn).CornerRadius = UI.CornerSmall

local sellActionLabel = Instance.new("TextLabel", sellActionBtn)
sellActionLabel.Size = UDim2.fromScale(1, 1)
sellActionLabel.BackgroundTransparency = 1
sellActionLabel.Text = "Sell Selected (0)"
sellActionLabel.TextColor3 = CTP.Crust
sellActionLabel.FontFace = UI.Font
sellActionLabel.TextSize = UI.ButtonSize

local teamView = Instance.new("Frame", viewsContainer)
teamView.Size = UDim2.fromScale(1, 1)
teamView.BackgroundTransparency = 1
teamView.Visible = false

local teamCard = Instance.new("ScrollingFrame", teamView)
teamCard.Size = UDim2.new(1, 0, 1, 0)
teamCard.BackgroundColor3 = CTP.Mantle
teamCard.BorderSizePixel = 0
teamCard.ScrollBarThickness = 3
teamCard.ScrollBarImageColor3 = CTP.Surface1
Instance.new("UICorner", teamCard).CornerRadius = UI.CornerMedium
local teamStroke = Instance.new("UIStroke", teamCard)
teamStroke.Color = CTP.Surface0
teamStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local teamLayout = Instance.new("UIListLayout", teamCard)
teamLayout.Padding = UDim.new(0, 6)
local teamPadding = Instance.new("UIPadding", teamCard)
teamPadding.PaddingTop = UDim.new(0, 10)
teamPadding.PaddingLeft = UDim.new(0, 10)
teamPadding.PaddingRight = UDim.new(0, 10)
teamPadding.PaddingBottom = UDim.new(0, 10)

teamLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teamCard.CanvasSize = UDim2.fromOffset(0, teamLayout.AbsoluteContentSize.Y + 20)
end)
evoMatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    evoMatScroll.CanvasSize = UDim2.fromOffset(0, evoMatLayout.AbsoluteContentSize.Y + 6)
end)
evoListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    evoListScroll.CanvasSize = UDim2.fromOffset(0, evoListLayout.AbsoluteContentSize.Y + 6)
end)
sellListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sellListScroll.CanvasSize = UDim2.fromOffset(0, sellListLayout.AbsoluteContentSize.Y + 6)
end)

function UIModule:SetState(open)
    self.IsOpen = open
    if open then
        mainFrame.Visible = true
        if self.Callbacks.OnRefresh then self.Callbacks.OnRefresh() end
        TweenService:Create(mainFrame, UI.TweenNormal, { GroupTransparency = 0 }):Play()
    else
        local tween = TweenService:Create(mainFrame, UI.TweenFast, { GroupTransparency = 1 })
        tween:Play()
        task.delay(0.15, function()
            if not self.IsOpen then mainFrame.Visible = false end
        end)
    end
end

function UIModule:SwitchTab(tabName)
    self.CurrentTab = tabName
    for name, tabData in pairs(tabButtons) do
        local isAct = (name == tabName)
        TweenService:Create(tabData.Button, UI.TweenFast, { BackgroundColor3 = isAct and CTP.Surface0 or CTP.Mantle }):Play()
        TweenService:Create(tabData.Label, UI.TweenFast, { TextColor3 = isAct and CTP.Mauve or CTP.Subtext0 }):Play()
        TweenService:Create(tabData.Icon, UI.TweenFast, { ImageColor3 = isAct and CTP.Mauve or CTP.Subtext0 }):Play()
        TweenService:Create(tabData.Stroke, UI.TweenFast, { Color = isAct and CTP.Mauve or CTP.Surface0 }):Play()
    end
    evolveView.Visible = (tabName == "Evolve")
    sellView.Visible = (tabName == "Sell")
    teamView.Visible = (tabName == "Team")
    if self.Callbacks.OnRefresh then self.Callbacks.OnRefresh() end
end

tabBtnEvo.Activated:Connect(function() UIModule:SwitchTab("Evolve") end)
tabBtnSell.Activated:Connect(function() UIModule:SwitchTab("Sell") end)
tabBtnTeam.Activated:Connect(function() UIModule:SwitchTab("Team") end)

local isDragging = false
local dragStart, startPos = Vector2.zero, UDim2.new()

table.insert(UIModule.Connections, topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end))
table.insert(UIModule.Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end))
table.insert(UIModule.Connections, UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

function UIModule:AppendLog(msg)
    local lines = string.split(evoLogBox.Text, "\n")
    if #lines > 5 then table.remove(lines, 1) end
    table.insert(lines, string.format("[%s] %s", os.date("%X"), msg))
    evoLogBox.Text = table.concat(lines, "\n")
end

function UIModule:CreateToggle(name, defaultState, isAccentMauve, onToggle)
    local active = defaultState
    local activeColor = isAccentMauve and CTP.Mauve or CTP.Blue

    local btn = Instance.new("TextButton", teamCard)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = active and CTP.Surface1 or CTP.Surface0
    btn.AutoButtonColor = false
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UI.CornerSmall
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = active and activeColor or CTP.Surface1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local label = Instance.new("TextLabel", btn)
    label.Position = UDim2.fromOffset(10, 0)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = active and CTP.Text or CTP.Subtext0
    label.FontFace = UI.Font
    label.TextSize = UI.BodySize
    label.TextXAlignment = Enum.TextXAlignment.Left

    local badge = Instance.new("Frame", btn)
    badge.Position = UDim2.new(1, -54, 0.5, -10)
    badge.Size = UDim2.fromOffset(44, 20)
    badge.BackgroundColor3 = active and activeColor or CTP.Surface0
    Instance.new("UICorner", badge).CornerRadius = UI.CornerSmall

    local badgeIcon = Instance.new("ImageLabel", badge)
    badgeIcon.Size = UDim2.fromOffset(12, 12)
    badgeIcon.Position = UDim2.new(0, 4, 0.5, -6)
    badgeIcon.BackgroundTransparency = 1
    badgeIcon.Image = active and ICONS.ToggleOn or ICONS.ToggleOff
    badgeIcon.ImageColor3 = active and CTP.Crust or CTP.Overlay0

    local badgeText = Instance.new("TextLabel", badge)
    badgeText.Position = UDim2.new(0, 18, 0, 0)
    badgeText.Size = UDim2.new(1, -18, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = active and "ON" or "OFF"
    badgeText.TextColor3 = active and CTP.Crust or CTP.Overlay0
    badgeText.FontFace = UI.Font
    badgeText.TextSize = UI.BadgeSize
    badgeText.TextXAlignment = Enum.TextXAlignment.Left

    btn.Activated:Connect(function()
        active = not active
        TweenService:Create(btn, UI.TweenFast, { BackgroundColor3 = active and CTP.Surface1 or CTP.Surface0 }):Play()
        TweenService:Create(stroke, UI.TweenFast, { Color = active and activeColor or CTP.Surface1 }):Play()
        TweenService:Create(badge, UI.TweenFast, { BackgroundColor3 = active and activeColor or CTP.Surface0 }):Play()
        label.TextColor3 = active and CTP.Text or CTP.Subtext0
        badgeIcon.Image = active and ICONS.ToggleOn or ICONS.ToggleOff
        badgeIcon.ImageColor3 = active and CTP.Crust or CTP.Overlay0
        badgeText.Text = active and "ON" or "OFF"
        badgeText.TextColor3 = active and CTP.Crust or CTP.Overlay0
        if onToggle then onToggle(active) end
    end)
end

function UIModule:UpdateMaterials(materials)
    for _, child in ipairs(evoMatScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    for _, mat in ipairs(materials) do
        local row = Instance.new("Frame", evoMatScroll)
        row.Size = UDim2.new(1, 0, 0, 24)
        row.BackgroundColor3 = mat.Deficit > 0 and CTP.Base or CTP.Surface0
        Instance.new("UICorner", row).CornerRadius = UI.CornerSmall

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Position = UDim2.fromOffset(10, 0)
        nameLbl.Size = UDim2.new(0.50, -10, 1, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = mat.DisplayName
        nameLbl.TextColor3 = CTP.Text
        nameLbl.FontFace = UI.Font
        nameLbl.TextSize = UI.SecondarySize
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local countLbl = Instance.new("TextLabel", row)
        countLbl.Position = UDim2.new(0.50, 0, 0, 0)
        countLbl.Size = UDim2.new(0.26, 0, 1, 0)
        countLbl.BackgroundTransparency = 1
        countLbl.Text = string.format("%d / %d", mat.Current, mat.Needed)
        countLbl.TextColor3 = CTP.Subtext1
        countLbl.FontFace = UI.RegularFont
        countLbl.TextSize = UI.SecondarySize

        local defLbl = Instance.new("TextLabel", row)
        defLbl.Position = UDim2.new(0.76, 0, 0, 0)
        defLbl.Size = UDim2.new(0.24, -6, 1, 0)
        defLbl.BackgroundTransparency = 1
        defLbl.Text = mat.Deficit > 0 and ("-" .. tostring(mat.Deficit)) or "Ready"
        defLbl.TextColor3 = mat.Deficit > 0 and CTP.Red or CTP.Blue
        defLbl.FontFace = UI.Font
        defLbl.TextSize = UI.SecondarySize
        defLbl.TextXAlignment = Enum.TextXAlignment.Right
    end
end

function UIModule:UpdateEvoList(candidates)
    for _, child in ipairs(evoListScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    for _, u in ipairs(candidates) do
        local isSelected = (self.SelectedEvoUnits[u.Id] == true)
        local row = Instance.new("TextButton", evoListScroll)
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = isSelected and CTP.Surface1 or CTP.Surface0
        row.AutoButtonColor = false
        row.Text = ""
        Instance.new("UICorner", row).CornerRadius = UI.CornerSmall
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = isSelected and CTP.Blue or CTP.Surface1
        rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Position = UDim2.fromOffset(8, 4)
        nameLbl.Size = UDim2.new(1, -16, 0, 16)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = string.format("%s (Lv.%d)", u.DisplayName, u.Level)
        nameLbl.TextColor3 = CTP.Text
        nameLbl.FontFace = UI.Font
        nameLbl.TextSize = UI.BodySize
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local detailLbl = Instance.new("TextLabel", row)
        detailLbl.Position = UDim2.fromOffset(8, 20)
        detailLbl.Size = UDim2.new(1, -16, 0, 16)
        detailLbl.BackgroundTransparency = 1
        detailLbl.Text = string.format("%s  •  %s  •  %d materials", u.Rarity:upper(), u.Trait, u.ReqCount)
        detailLbl.FontFace = UI.RegularFont
        detailLbl.TextSize = UI.SecondarySize
        detailLbl.TextXAlignment = Enum.TextXAlignment.Left
        detailLbl.TextColor3 = RARITY_COLORS[u.Rarity] or CTP.Text

        row.Activated:Connect(function()
            self.SelectedEvoUnits[u.Id] = not self.SelectedEvoUnits[u.Id] and true or nil
            if self.Callbacks.OnRefresh then self.Callbacks.OnRefresh() end
        end)
    end
end

function UIModule:UpdateSellList(units)
    for _, child in ipairs(sellListScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    for _, u in ipairs(units) do
        if self.SellFilters[u.Rarity] then
            local isSelected = (self.SelectedSellUnits[u.Id] == true)
            local row = Instance.new("TextButton", sellListScroll)
            row.Size = UDim2.new(1, 0, 0, 42)
            row.BackgroundColor3 = isSelected and CTP.Surface1 or CTP.Surface0
            row.AutoButtonColor = false
            row.Text = ""
            Instance.new("UICorner", row).CornerRadius = UI.CornerSmall
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = isSelected and CTP.Mauve or CTP.Surface1
            rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Position = UDim2.fromOffset(8, 4)
            nameLbl.Size = UDim2.new(1, -16, 0, 16)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = (u.IsProtected and "🔒 " or "") .. string.format("%s (Lv.%d)", u.DisplayName, u.Level)
            nameLbl.FontFace = UI.Font
            nameLbl.TextSize = UI.BodySize
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextColor3 = u.IsProtected and CTP.Overlay0 or CTP.Text

            local detailLbl = Instance.new("TextLabel", row)
            detailLbl.Position = UDim2.fromOffset(8, 20)
            detailLbl.Size = UDim2.new(1, -16, 0, 16)
            detailLbl.BackgroundTransparency = 1
            detailLbl.Text = string.format("%s  •  %s", u.Rarity:upper(), u.IsProtected and "PROTECTED" or "READY TO SELL")
            detailLbl.FontFace = UI.RegularFont
            detailLbl.TextSize = UI.SecondarySize
            detailLbl.TextXAlignment = Enum.TextXAlignment.Left
            detailLbl.TextColor3 = RARITY_COLORS[u.Rarity] or CTP.Text

            if not u.IsProtected then
                row.Activated:Connect(function()
                    self.SelectedSellUnits[u.Id] = not self.SelectedSellUnits[u.Id] and true or nil
                    local count = 0
                    for _ in pairs(self.SelectedSellUnits) do count = count + 1 end
                    sellActionLabel.Text = string.format("Sell Selected (%d)", count)
                    if self.Callbacks.OnRefresh then self.Callbacks.OnRefresh() end
                end)
            end
        end
    end
end

local function setupFilters()
    for _, child in ipairs(filterContainer:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    for _, r in ipairs({ "Rare", "Epic", "Legendary", "Mythic" }) do
        local active = (UIModule.SellFilters[r] == true)
        local btn = Instance.new("TextButton", filterContainer)
        btn.BackgroundColor3 = active and CTP.Surface1 or CTP.Surface0
        btn.Text = ""
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UI.CornerSmall
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = active and (RARITY_COLORS[r] or CTP.Mauve) or CTP.Surface1
        btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local lbl = Instance.new("TextLabel", btn)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.Size = UDim2.new(1, -10, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = r
        lbl.FontFace = UI.Font
        lbl.TextSize = UI.SecondarySize
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextColor3 = RARITY_COLORS[r] or CTP.Text

        btn.Activated:Connect(function()
            UIModule.SellFilters[r] = not UIModule.SellFilters[r]
            setupFilters()
            table.clear(UIModule.SelectedSellUnits)
            sellActionLabel.Text = "Sell Selected (0)"
            if UIModule.Callbacks.OnRefresh then UIModule.Callbacks.OnRefresh() end
        end)
    end
end
setupFilters()

evoSelectAllBtn.Activated:Connect(function()
    if UIModule.Callbacks.OnSelectAllEvo then UIModule.Callbacks.OnSelectAllEvo() end
end)
evoClearBtn.Activated:Connect(function()
    table.clear(UIModule.SelectedEvoUnits)
    if UIModule.Callbacks.OnRefresh then UIModule.Callbacks.OnRefresh() end
end)
sellSelectFilteredBtn.Activated:Connect(function()
    if UIModule.Callbacks.OnSelectFilteredSell then UIModule.Callbacks.OnSelectFilteredSell() end
end)
sellClearBtn.Activated:Connect(function()
    table.clear(UIModule.SelectedSellUnits)
    sellActionLabel.Text = "Sell Selected (0)"
    if UIModule.Callbacks.OnRefresh then UIModule.Callbacks.OnRefresh() end
end)

evoActionBtn.Activated:Connect(function()
    if UIModule.Callbacks.OnEvoAction then
        evoActionLabel.Text = "Processing..."
        UIModule.Callbacks.OnEvoAction()
        evoActionLabel.Text = "Craft & Evolve Now"
    end
end)

sellActionBtn.Activated:Connect(function()
    if UIModule.Callbacks.OnSellAction then
        sellActionLabel.Text = "Selling..."
        UIModule.Callbacks.OnSellAction()
        sellActionLabel.Text = "Sell Selected (0)"
    end
end)

unloadBtn.Activated:Connect(function()
    if UIModule.Callbacks.OnUnload then UIModule.Callbacks.OnUnload() end
end)

table.insert(UIModule.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        UIModule:SetState(not UIModule.IsOpen)
    end
end))

function UIModule:Destroy()
    for _, conn in ipairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(self.Connections)
    if screenGui then screenGui:Destroy() end
end

return UIModule
