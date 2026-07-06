local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- =================================================================
-- PROTEKSI MULTIPLE EXECUTION & CLEANUP (Mencegah Ghost Loop)
-- =================================================================
if _G.PandaFishingHubConnections then
    for _, conn in ipairs(_G.PandaFishingHubConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.PandaFishingHubConnections = {}

local function track(conn)
    table.insert(_G.PandaFishingHubConnections, conn)
    return conn
end

-- CLEANUP OLD GUI
pcall(function()
    if CoreGui:FindFirstChild("FishingMultiHub") then CoreGui.FishingMultiHub:Destroy() end
    if gethui and gethui():FindFirstChild("FishingMultiHub") then gethui().FishingMultiHub:Destroy() end
end)

-- =================================================================
-- STATE MANAGEMENT
-- =================================================================
local State = {
    AuraEnabled = false,
    AutoInteract = false,
    AuraRadius = 35,
    AttackCooldown = 0.2
}

-- =================================================================
-- GUI MULTI-FITUR
-- =================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "FishingMultiHub"
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
frame.Size = UDim2.new(0, 250, 0, 250)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35) -- Tema warna laut gelap
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(50, 150, 255)
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = "🎣 FISHING HUB PRO 🎣"
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
minimizeBtn.Position = UDim2.new(1, -35, 0.5, -15)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.TextSize = 20
minimizeBtn.Text = "-"
minimizeBtn.Parent = spacer

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 250, 0, 40)
        minimizeBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 250, 0, 250)
        minimizeBtn.Text = "-"
    end
end)

local function createToggle(name, text, stateKey, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text .. ": OFF"
    btn.LayoutOrder = layoutOrder
    btn.Parent = frame
    
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

createToggle("AuraToggle", "Aura Catch & Damage", "AuraEnabled", 2)
createToggle("InteractToggle", "Auto Chest & Rescue", "AutoInteract", 3)

-- INPUT RADIUS
local radiusContainer = Instance.new("Frame")
radiusContainer.Size = UDim2.new(0.9, 0, 0, 40)
radiusContainer.BackgroundTransparency = 1
radiusContainer.LayoutOrder = 4
radiusContainer.Parent = frame

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0.55, 0, 1, 0)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Jarak Radius:"
radiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusLabel.Font = Enum.Font.GothamBold
radiusLabel.TextSize = 14
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = radiusContainer

local radiusInput = Instance.new("TextBox")
radiusInput.Size = UDim2.new(0.4, 0, 0.8, 0)
radiusInput.Position = UDim2.new(0.6, 0, 0.1, 0)
radiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
radiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusInput.Font = Enum.Font.Gotham
radiusInput.TextSize = 14
radiusInput.Text = tostring(State.AuraRadius)
radiusInput.PlaceholderText = "Radius"
radiusInput.Parent = radiusContainer

radiusInput.FocusLost:Connect(function()
    local num = tonumber(radiusInput.Text)
    if num then
        if num < 5 then num = 5 end
        if num > 1000 then num = 1000 end
        State.AuraRadius = num
        radiusInput.Text = tostring(num)
    else
        radiusInput.Text = tostring(State.AuraRadius)
    end
end)

-- SISTEM DRAG GUI
local UserInputService = game:GetService("UserInputService")
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
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- =================================================================
-- LOGIKA AURA & AUTO INTERACT
-- =================================================================

-- 1. Cache ProximityPrompt (0 Lag) untuk Chest & NPC
local cachedPrompts = {}

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
        cachedPrompts[obj] = true
    end
end

track(workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
        cachedPrompts[obj] = true
    end
end))

track(workspace.DescendantRemoving:Connect(function(obj)
    if cachedPrompts[obj] then
        cachedPrompts[obj] = nil
    end
end))

local function getNearbyPrompts(rootPos)
    local nearby = {}
    for obj, _ in pairs(cachedPrompts) do
        if obj.Parent then
            local pos = nil
            local p = obj.Parent
            if p:IsA("BasePart") then pos = p.Position
            elseif p:IsA("Model") and p.PrimaryPart then pos = p.PrimaryPart.Position
            elseif p:IsA("Attachment") then pos = p.WorldPosition end
            
            if pos and (pos - rootPos).Magnitude <= State.AuraRadius then
                table.insert(nearby, obj)
            end
        end
    end
    return nearby
end

-- 2. Fungsi untuk mendeteksi item/part yang bergerak (ikan/drop) serta Monster & Player
local function getTargetsInRadius()
    local targetParts = {}
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return targetParts end
    local rootPart = char.HumanoidRootPart

    -- A. Deteksi Pemain Lain (Player Aura Damage)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= State.AuraRadius then
                    -- Ambil bagian tubuh esensial
                    local partsToHit = {"Torso", "UpperTorso", "Head", "Right Arm"}
                    for _, pName in ipairs(partsToHit) do
                        local p = player.Character:FindFirstChild(pName)
                        if p then table.insert(targetParts, p) end
                    end
                end
            end
        end
    end

    -- B. Deteksi Item, Ikan, & Monster/NPC
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local parts = workspace:GetPartBoundsInRadius(rootPart.Position, State.AuraRadius, params)
    for _, part in ipairs(parts) do
        local isTarget = false
        
        if not part.Anchored and part.Size.Magnitude < 50 then
            -- Kemungkinan ini adalah ikan / item drop
            isTarget = true
        elseif part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
            -- Ini adalah NPC atau Monster yang memiliki darah
            local hum = part.Parent:FindFirstChildOfClass("Humanoid")
            if hum.Health > 0 then
                isTarget = true
            end
        end
        
        if isTarget then
            table.insert(targetParts, part)
        end
    end
    return targetParts
end

local function getEquippedWeapon()
    if not LocalPlayer.Character then return nil end
    return LocalPlayer.Character:FindFirstChildOfClass("Tool")
end

-- =================================================================
-- MAIN LOOP
-- =================================================================
local lastAttackTime = 0

track(RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return end

    -- FITUR AURA CATCH (Nembak/Sentuh Item)
    if State.AuraEnabled and (currentTime - lastAttackTime >= State.AttackCooldown) then
        local weapon = getEquippedWeapon()
        local weaponHandle = weapon and weapon:FindFirstChild("Handle")
        local targets = getTargetsInRadius()
        
        for _, tPart in ipairs(targets) do
            if firetouchinterest then
                -- Sentuh gaib menggunakan Handle alat (Damage murni tanpa animasi)
                if weaponHandle then
                    firetouchinterest(tPart, weaponHandle, 0)
                    firetouchinterest(tPart, weaponHandle, 1)
                end
                
                -- Sentuh menggunakan tubuh pemain (Berjaga-jaga jika butuh sentuhan fisik)
                firetouchinterest(tPart, rootPart, 0)
                firetouchinterest(tPart, rootPart, 1)
            end
        end
        
        lastAttackTime = currentTime
    end
    
    -- FITUR AUTO INTERACT (Buka Chest & Rescue Fisherman)
    if State.AutoInteract then
        local nearbyPrompts = getNearbyPrompts(rootPart.Position)
        for _, promptObj in ipairs(nearbyPrompts) do
            if promptObj:IsA("ProximityPrompt") and fireproximityprompt then
                fireproximityprompt(promptObj)
            elseif promptObj:IsA("ClickDetector") and fireclickdetector then
                fireclickdetector(promptObj)
            end
        end
    end
end))
