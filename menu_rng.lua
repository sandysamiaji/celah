local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- =================================================================
-- PROTEKSI MULTIPLE EXECUTION & CLEANUP
-- =================================================================
if _G.PandaRNGHubConnections then
    for _, conn in ipairs(_G.PandaRNGHubConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.PandaRNGHubConnections = {}

local function track(conn)
    table.insert(_G.PandaRNGHubConnections, conn)
    return conn
end

-- CLEANUP OLD GUI
pcall(function()
    if CoreGui:FindFirstChild("PandaHub") then CoreGui.PandaHub:Destroy() end
    if gethui and gethui():FindFirstChild("PandaHub") then gethui().PandaHub:Destroy() end
end)

-- State Management (Semua Fitur)
local State = {
    AutoThrow = false,
    SpamThrowCoin = false,
    SpamThrowDelay = 0.1,
    AutoSellAll = false,
    AutoBuyCoins = false,
    AutoCoinLanded = false,
    AutoAFKSafe = false
}

-- Remotes
local Events = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events")

-- Loop Actions
local lastSpamThrow = 0
track(RunService.Heartbeat:Connect(function()
    if State.SpamThrowCoin then
        if tick() - lastSpamThrow >= State.SpamThrowDelay then
            lastSpamThrow = tick()
            pcall(function()
                Events.ThrowReady:FireServer()
                Events.CoinThrow:FireServer()
            end)
        end
    end
    if State.AutoCoinLanded then
        pcall(function() Events.CoinLanded:FireServer() end)
    end
    if State.AutoSellAll then
        pcall(function() Events.SellAll:FireServer() end)
    end
end))

task.spawn(function()
    while task.wait(1) do
        if State.AutoBuyCoins then
            pcall(function() Events.BuyAllCoins:FireServer() end)
        end
        if State.AutoThrow then
            pcall(function() Events.EnableAutothrow:FireServer() end)
        end
        if State.AutoAFKSafe then
            pcall(function() Events.StartAFKSafe:FireServer() end)
        end
    end
end)

--------------------------------------------------------------------------------
-- GUI MULTI-FITUR
--------------------------------------------------------------------------------
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
title.Text = " PANDA RNG HUB "
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

local farmTab = Instance.new("ScrollingFrame")
farmTab.Size = UDim2.new(1, 0, 1, 0)
farmTab.BackgroundTransparency = 1
farmTab.BorderSizePixel = 0
farmTab.ScrollBarThickness = 4
farmTab.CanvasSize = UDim2.new(0, 0, 0, 500)
farmTab.Visible = true
farmTab.Parent = contentContainer

local farmLayout = Instance.new("UIListLayout")
farmLayout.Parent = farmTab
farmLayout.SortOrder = Enum.SortOrder.LayoutOrder
farmLayout.Padding = UDim.new(0, 5)
farmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
farmLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    farmTab.CanvasSize = UDim2.new(0, 0, 0, farmLayout.AbsoluteContentSize.Y + 20)
end)

local miscTab = Instance.new("ScrollingFrame")
miscTab.Size = UDim2.new(1, 0, 1, 0)
miscTab.BackgroundTransparency = 1
miscTab.BorderSizePixel = 0
miscTab.ScrollBarThickness = 4
miscTab.CanvasSize = UDim2.new(0, 0, 0, 500)
miscTab.Visible = false
miscTab.Parent = contentContainer

local miscLayout = Instance.new("UIListLayout")
miscLayout.Parent = miscTab
miscLayout.SortOrder = Enum.SortOrder.LayoutOrder
miscLayout.Padding = UDim.new(0, 5)
miscLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
miscLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    miscTab.CanvasSize = UDim2.new(0, 0, 0, miscLayout.AbsoluteContentSize.Y + 20)
end)

local infoTab = Instance.new("ScrollingFrame")
infoTab.Size = UDim2.new(1, 0, 1, 0)
infoTab.BackgroundTransparency = 1
infoTab.BorderSizePixel = 0
infoTab.ScrollBarThickness = 4
infoTab.CanvasSize = UDim2.new(0, 0, 0, 800)
infoTab.Visible = false
infoTab.Parent = contentContainer

local infoLayout = Instance.new("UIListLayout")
infoLayout.Parent = infoTab
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Padding = UDim.new(0, 5)
infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
infoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    infoTab.CanvasSize = UDim2.new(0, 0, 0, infoLayout.AbsoluteContentSize.Y + 20)
end)

local function switchTab(tab)
    farmTab.Visible = (tab == farmTab)
    miscTab.Visible = (tab == miscTab)
    infoTab.Visible = (tab == infoTab)
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
        if _G.PandaRNGHubConnections then
            for _, conn in ipairs(_G.PandaRNGHubConnections) do
                pcall(function() conn:Disconnect() end)
            end
            _G.PandaRNGHubConnections = {}
        end
        State.AutoThrow = false
        State.AutoSellAll = false
        State.AutoBuyCoins = false
        State.AutoCoinLanded = false
    end)
end)

local function createNavBtn(text, tabToOpen)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text
    btn.Parent = navBar
    
    btn.MouseButton1Click:Connect(function()
        switchTab(tabToOpen)
    end)
    return btn
end

local farmNav = createNavBtn("Farm", farmTab)
local miscNav = createNavBtn("Misc", miscTab)
local infoNav = createNavBtn("Info", infoTab)

local function createToggle(name, text, stateKey, layoutOrder, parentTab)
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
    end)
    return btn
end

local function createButton(name, text, layoutOrder, parentTab, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    btn.LayoutOrder = layoutOrder
    btn.Parent = parentTab
    
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return btn
end

-- INFO TAB
local function createInfoBox(titleText, descText, layoutOrder, parentTab)
    parentTab = parentTab or infoTab
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.LayoutOrder = layoutOrder
    container.Parent = parentTab

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 5)
    uicorner.Parent = container

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -10, 0, 25)
    titleLbl.Position = UDim2.new(0, 5, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = Color3.fromRGB(241, 196, 15)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = container

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

createInfoBox("Auto Throw", "Automatically enables auto throwing of coins or items depending on your settings.", 1)
createInfoBox("Spam Throw Coin", "Aggressively spams the CoinThrow and ThrowReady remotes. Might be faster than Auto Throw.", 1)
createInfoBox("Auto Sell All", "Automatically sells all of your unequipped or unprotected items for fast cash.", 2)
createInfoBox("Auto Buy Coins", "Automatically buys available coins to boost your luck continuously.", 3)
createInfoBox("Auto Coin Landed", "Spams the CoinLanded remote event, potentially granting extra money if the game allows it.", 4)
createInfoBox("Claim Rewards", "Instantly claims group rewards, starter cash, and any available gifts from the server.", 5)

-- FARM TAB
createToggle("AutoThrowToggle", "Auto Throw", "AutoThrow", 1, farmTab)
createToggle("SpamThrowCoinToggle", "Spam Throw Coin", "SpamThrowCoin", 2, farmTab)

local spamDelayContainer = Instance.new("Frame")
spamDelayContainer.Size = UDim2.new(0.9, 0, 0, 35)
spamDelayContainer.BackgroundTransparency = 1
spamDelayContainer.LayoutOrder = 2
spamDelayContainer.Parent = farmTab

local spamDelayLabel = Instance.new("TextLabel")
spamDelayLabel.Size = UDim2.new(0.55, 0, 1, 0)
spamDelayLabel.BackgroundTransparency = 1
spamDelayLabel.Text = "Spam Delay:"
spamDelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
spamDelayLabel.Font = Enum.Font.GothamBold
spamDelayLabel.TextSize = 13
spamDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
spamDelayLabel.Parent = spamDelayContainer

local spamDelayInput = Instance.new("TextBox")
spamDelayInput.Size = UDim2.new(0.4, 0, 0.8, 0)
spamDelayInput.Position = UDim2.new(0.6, 0, 0.1, 0)
spamDelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
spamDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
spamDelayInput.Font = Enum.Font.Gotham
spamDelayInput.TextSize = 13
spamDelayInput.Text = tostring(State.SpamThrowDelay)
spamDelayInput.PlaceholderText = "Seconds"
spamDelayInput.Parent = spamDelayContainer

spamDelayInput.FocusLost:Connect(function()
    local val = tonumber(spamDelayInput.Text)
    if val then
        if val < 0 then val = 0 end
        State.SpamThrowDelay = val
        spamDelayInput.Text = tostring(val)
    else
        spamDelayInput.Text = tostring(State.SpamThrowDelay)
    end
end)

createToggle("AutoSellToggle", "Auto Sell All", "AutoSellAll", 3, farmTab)
createToggle("AutoBuyCoinsToggle", "Auto Buy Coins", "AutoBuyCoins", 4, farmTab)
createToggle("AutoCoinLandedToggle", "Auto Coin Landed (Risky)", "AutoCoinLanded", 5, farmTab)
createToggle("AutoAFKSafeToggle", "Auto AFK Safe", "AutoAFKSafe", 6, farmTab)

-- MISC TAB
createButton("ClaimGroupBtn", "Claim Group Reward", 1, miscTab, function()
    Events.ClaimGroup:FireServer()
end)

createButton("ClaimStarterBtn", "Claim Starter Cash", 2, miscTab, function()
    Events.ClaimStarterCash:FireServer()
end)

createButton("SkipTutBtn", "Skip Tutorial", 3, miscTab, function()
    Events.ForceTutorialReveal:FireServer()
end)

local redeemContainer = Instance.new("Frame")
redeemContainer.Size = UDim2.new(0.9, 0, 0, 35)
redeemContainer.BackgroundTransparency = 1
redeemContainer.LayoutOrder = 4
redeemContainer.Parent = miscTab

local redeemInput = Instance.new("TextBox")
redeemInput.Size = UDim2.new(0.65, 0, 1, 0)
redeemInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
redeemInput.TextColor3 = Color3.fromRGB(255, 255, 255)
redeemInput.Font = Enum.Font.Gotham
redeemInput.TextSize = 13
redeemInput.Text = ""
redeemInput.PlaceholderText = "Enter Code..."
redeemInput.Parent = redeemContainer

local redeemBtn = Instance.new("TextButton")
redeemBtn.Size = UDim2.new(0.3, 0, 1, 0)
redeemBtn.Position = UDim2.new(0.7, 0, 0, 0)
redeemBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
redeemBtn.Font = Enum.Font.GothamBold
redeemBtn.TextSize = 12
redeemBtn.Text = "Redeem"
redeemBtn.Parent = redeemContainer

redeemBtn.MouseButton1Click:Connect(function()
    if redeemInput.Text ~= "" then
        pcall(function()
            Events.RedeemCode:InvokeServer(redeemInput.Text)
        end)
    end
end)

local function scanForItems()
    local items = {}
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetChildren()) do
            if (v:IsA("Model") or v:IsA("Tool") or v:IsA("Folder")) and v.Name ~= "HumanoidRootPart" and v.Name ~= "Humanoid" and not v:IsA("Part") and not v:IsA("MeshPart") then
                table.insert(items, v.Name)
            end
        end
    end
    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        table.insert(items, v.Name)
    end
    for _, v in ipairs(LocalPlayer:GetChildren()) do
        if v:IsA("Folder") and (string.find(string.lower(v.Name), "inv") or string.find(string.lower(v.Name), "item") or string.find(string.lower(v.Name), "pet") or string.find(string.lower(v.Name), "aura")) then
            for _, item in ipairs(v:GetChildren()) do
                table.insert(items, item.Name)
            end
        end
    end
    return items
end

local exploitLabel = Instance.new("TextLabel")
exploitLabel.Size = UDim2.new(0.9, 0, 0, 20)
exploitLabel.BackgroundTransparency = 1
exploitLabel.Text = "-- Economy Exploit Test --"
exploitLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
exploitLabel.Font = Enum.Font.GothamBold
exploitLabel.TextSize = 13
exploitLabel.LayoutOrder = 5
exploitLabel.Parent = miscTab

local exploitItemInput = Instance.new("TextBox")
exploitItemInput.Size = UDim2.new(0.9, 0, 0, 30)
exploitItemInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
exploitItemInput.TextColor3 = Color3.fromRGB(255, 255, 255)
exploitItemInput.Font = Enum.Font.Gotham
exploitItemInput.TextSize = 13
exploitItemInput.Text = ""
exploitItemInput.PlaceholderText = "Item ID/Name"
exploitItemInput.LayoutOrder = 6
exploitItemInput.Parent = miscTab

local exploitAmountInput = Instance.new("TextBox")
exploitAmountInput.Size = UDim2.new(0.9, 0, 0, 30)
exploitAmountInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
exploitAmountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
exploitAmountInput.Font = Enum.Font.Gotham
exploitAmountInput.TextSize = 13
exploitAmountInput.Text = "-9999999"
exploitAmountInput.PlaceholderText = "Amount"
exploitAmountInput.LayoutOrder = 7
exploitAmountInput.Parent = miscTab

local testSellStackBtn = Instance.new("TextButton")
testSellStackBtn.Size = UDim2.new(0.9, 0, 0, 35)
testSellStackBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
testSellStackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
testSellStackBtn.Font = Enum.Font.GothamBold
testSellStackBtn.TextSize = 12
testSellStackBtn.Text = "Test SellStack Bug"
testSellStackBtn.LayoutOrder = 8
testSellStackBtn.Parent = miscTab

testSellStackBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local amt = tonumber(exploitAmountInput.Text) or -9999999
        local itemName = exploitItemInput.Text
        if itemName == "" or itemName == "Item ID/Name" then
            local found = scanForItems()
            if #found > 0 then
                itemName = found[1]
                exploitItemInput.Text = itemName
            else
                itemName = "UnknownItem"
            end
        end
        Events.SellStack:FireServer(itemName, amt)
    end)
end)

local testSellItemBtn = Instance.new("TextButton")
testSellItemBtn.Size = UDim2.new(0.9, 0, 0, 35)
testSellItemBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
testSellItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
testSellItemBtn.Font = Enum.Font.GothamBold
testSellItemBtn.TextSize = 12
testSellItemBtn.Text = "Test SellItem Bug"
testSellItemBtn.LayoutOrder = 9
testSellItemBtn.Parent = miscTab

testSellItemBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local amt = tonumber(exploitAmountInput.Text) or -9999999
        local itemName = exploitItemInput.Text
        if itemName == "" or itemName == "Item ID/Name" then
            local found = scanForItems()
            if #found > 0 then
                itemName = found[1]
                exploitItemInput.Text = itemName
            else
                itemName = "UnknownItem"
            end
        end
        Events.SellItem:FireServer(itemName, amt)
    end)
end)
