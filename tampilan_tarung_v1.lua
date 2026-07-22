-- =================================================================
-- TAMPILAN TARUNG V1 (UI FRAMEWORK)
-- =================================================================
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local State = getgenv().PandaHub.State
local UI = getgenv().PandaHub.UI
local Tabs = getgenv().PandaHub.Tabs

-- GUI MULTI-FITUR
local gui = Instance.new("ScreenGui")
gui.Name = "PandaHub"
gui.ResetOnSpawn = false

if gethui then
    gui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(gui)
    gui.Parent = CoreGui
else
    gui.Parent = CoreGui
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 330, 0, 380)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = " PANDA HUB (MODULAR) "
title.Parent = frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = frame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 40)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 1
spacer.Parent = frame
title.Parent = spacer

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(243, 156, 18)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.TextSize = 20
minimizeBtn.Text = "-"
minimizeBtn.Parent = spacer

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 16
closeBtn.Text = "X"
closeBtn.Parent = spacer

local isMinimized = false

local bodyFrame = Instance.new("Frame")
bodyFrame.Size = UDim2.new(1, 0, 1, -45)
bodyFrame.BackgroundTransparency = 1
bodyFrame.LayoutOrder = 2
bodyFrame.Parent = frame

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Parent = bodyFrame
bodyLayout.FillDirection = Enum.FillDirection.Horizontal
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder

local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(0, 75, 1, 0)
navBar.BackgroundTransparency = 1
navBar.LayoutOrder = 1
navBar.Parent = bodyFrame

local navLayout = Instance.new("UIListLayout")
navLayout.Parent = navBar
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Padding = UDim.new(0, 5)

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -75, 1, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.LayoutOrder = 2
contentContainer.Parent = bodyFrame

local function createTab(name, visible)
    local tab = Instance.new("ScrollingFrame")
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.BorderSizePixel = 0
    tab.ScrollBarThickness = 4
    tab.CanvasSize = UDim2.new(0, 0, 0, 500)
    tab.Visible = visible
    tab.Parent = contentContainer

    local layout = Instance.new("UIListLayout")
    layout.Parent = tab
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    return tab
end

-- Export Tabs ke Global
Tabs.Farm = createTab("Farm", true)
Tabs.Cheats = createTab("Cheats", false)
Tabs.Teleport = createTab("Teleport", false)
Tabs.Builder = createTab("Builder", false)
Tabs.Info = createTab("Info", false)
Tabs.Gift = createTab("Gift", false)
Tabs.Anti = createTab("Anti", false)

UI.switchTab = function(tab)
    for _, t in pairs(Tabs) do
        t.Visible = (t == tab)
    end
end

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 330, 0, 40)
        minimizeBtn.Text = "+"
        bodyFrame.Visible = false
    else
        frame.Size = UDim2.new(0, 330, 0, 380)
        minimizeBtn.Text = "-"
        bodyFrame.Visible = true
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    pcall(function()
        gui:Destroy()
        if getgenv().PandaHub and getgenv().PandaHub.Connections then
            for _, conn in ipairs(getgenv().PandaHub.Connections) do
                pcall(function() conn:Disconnect() end)
            end
            getgenv().PandaHub.Connections = {}
        end
    end)
end)

UI.createNavBtn = function(text, tabToOpen)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text
    btn.Parent = navBar
    
    btn.MouseButton1Click:Connect(function()
        UI.switchTab(tabToOpen)
    end)
    return btn
end

-- Create Navigations
UI.createNavBtn("Farm", Tabs.Farm)
UI.createNavBtn("Cheats", Tabs.Cheats)
UI.createNavBtn("Teleport", Tabs.Teleport)
UI.createNavBtn("Builder", Tabs.Builder)
UI.createNavBtn("Info", Tabs.Info)
UI.createNavBtn("Gift", Tabs.Gift)
UI.createNavBtn("Anti", Tabs.Anti)

UI.createToggle = function(name, text, stateKey, layoutOrder, parentTab, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text .. (State[stateKey] and ": ON" or ": OFF")
    btn.LayoutOrder = layoutOrder
    btn.Parent = parentTab
    
    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        if State[stateKey] then
            btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.Text = text .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = text .. ": OFF"
        end
        if callback then callback(State[stateKey]) end
    end)
    return btn
end

UI.createInfoBox = function(titleText, descText, layoutOrder, parentTab)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.LayoutOrder = layoutOrder
    container.Parent = parentTab

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 5)
    uicorner.Parent = container

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 25)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(241, 196, 15)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -10, 0, 0)
    desc.Position = UDim2.new(0, 5, 0, 30)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    desc.Parent = container

    local textBounds = game:GetService("TextService"):GetTextSize(descText, 12, Enum.Font.Gotham, Vector2.new(230, 9999))
    desc.Size = UDim2.new(1, -10, 0, textBounds.Y + 10)
    container.Size = UDim2.new(0.95, 0, 0, 30 + textBounds.Y + 10)
end

--------------------------------------------------------------------------------
-- SISTEM DRAG GUI
--------------------------------------------------------------------------------
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
