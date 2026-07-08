local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- =================================================================
-- PROTEKSI MULTIPLE EXECUTION & CLEANUP (Mencegah Ghost Loop/Log)
-- =================================================================
if _G.PandaBoogaHubConnections then
    for _, conn in ipairs(_G.PandaBoogaHubConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.PandaBoogaHubConnections = {}

local function track(conn)
    table.insert(_G.PandaBoogaHubConnections, conn)
    return conn
end

-- CLEANUP OLD GUI
pcall(function()
    if CoreGui:FindFirstChild("BoogaMultiHub") then CoreGui.BoogaMultiHub:Destroy() end
    if gethui and gethui():FindFirstChild("BoogaMultiHub") then gethui().BoogaMultiHub:Destroy() end
end)

-- Konfigurasi Webhook
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local logQueue = {}
local lastLogSend = tick()

-- State Management (Semua Fitur)
local State = {
    AuraEnabled = false,
    AutoClaimReward = false,
    AutoRespawn = false,
    AntiFallDamage = false,
    Noclip = false,
    SpyTrace = false,
    InfiniteDrop = false,
    Invisible = false,
    AuraRadius = 35, -- Dikembalikan ke 25 sesuai permintaan
    AttackCooldown = 0.2
}

-- Logging System
local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(logQueue, msg)
end

local function processLogQueue()
    -- Webhook dinonaktifkan sesuai permintaan agar tidak lag dari HTTP requests
    logQueue = {}
end

--------------------------------------------------------------------------------
-- GUI MULTI-FITUR
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BoogaMultiHub"
gui.ResetOnSpawn = false

local hui
local success = pcall(function()
    hui = gethui and gethui()
end)

if success and hui then
    gui.Parent = hui
elseif syn and syn.protect_gui then
    syn.protect_gui(gui)
    gui.Parent = CoreGui
else
    gui.Parent = CoreGui
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 380)
frame.AnchorPoint = Vector2.new(0.5, 0) -- Anchor di atas tengah
frame.Position = UDim2.new(0.5, 0, 0.5, -190) -- Posisi agar tetap center di awal (380 / 2)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Active = true
frame.ClipsDescendants = true -- Agar menu tombol di bawahnya terpotong/disembunyikan saat diperkecil
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = "🔥 ALL-IN-ONE HUB 🔥"
title.Parent = frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = frame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Spacer bawah title
local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 40)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 1
spacer.Parent = frame
title.Parent = spacer

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0.5, -15)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Diubah jadi MERAH terang agar terlihat
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.TextSize = 20
minimizeBtn.Text = "-"
minimizeBtn.Parent = spacer

local isMinimized = false

local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(1, 0, 0, 35)
navBar.BackgroundTransparency = 1
navBar.LayoutOrder = 2
navBar.Parent = frame

local navLayout = Instance.new("UIListLayout")
navLayout.Parent = navBar
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Padding = UDim.new(0, 5)

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -85)
contentContainer.BackgroundTransparency = 1
contentContainer.LayoutOrder = 3
contentContainer.Parent = frame

local farmTab = Instance.new("Frame")
farmTab.Size = UDim2.new(1, 0, 1, 0)
farmTab.BackgroundTransparency = 1
farmTab.Visible = true
farmTab.Parent = contentContainer

local farmLayout = Instance.new("UIListLayout")
farmLayout.Parent = farmTab
farmLayout.SortOrder = Enum.SortOrder.LayoutOrder
farmLayout.Padding = UDim.new(0, 5)
farmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local cheatsTab = Instance.new("Frame")
cheatsTab.Size = UDim2.new(1, 0, 1, 0)
cheatsTab.BackgroundTransparency = 1
cheatsTab.Visible = false
cheatsTab.Parent = contentContainer

local cheatsLayout = Instance.new("UIListLayout")
cheatsLayout.Parent = cheatsTab
cheatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
cheatsLayout.Padding = UDim.new(0, 5)
cheatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local teleportTab = Instance.new("Frame")
teleportTab.Size = UDim2.new(1, 0, 1, 0)
teleportTab.BackgroundTransparency = 1
teleportTab.Visible = false
teleportTab.Parent = contentContainer

local teleportLayout = Instance.new("UIListLayout")
teleportLayout.Parent = teleportTab
teleportLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleportLayout.Padding = UDim.new(0, 5)
teleportLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local builderTab = Instance.new("Frame")
builderTab.Size = UDim2.new(1, 0, 1, 0)
builderTab.BackgroundTransparency = 1
builderTab.Visible = false
builderTab.Parent = contentContainer

local builderLayout = Instance.new("UIListLayout")
builderLayout.Parent = builderTab
builderLayout.SortOrder = Enum.SortOrder.LayoutOrder
builderLayout.Padding = UDim.new(0, 5)
builderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function switchTab(tab)
    farmTab.Visible = (tab == farmTab)
    cheatsTab.Visible = (tab == cheatsTab)
    teleportTab.Visible = (tab == teleportTab)
    builderTab.Visible = (tab == builderTab)
end

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 250, 0, 40)
        minimizeBtn.Text = "+"
        contentContainer.Visible = false
        navBar.Visible = false
    else
        frame.Size = UDim2.new(0, 250, 0, 380)
        minimizeBtn.Text = "-"
        contentContainer.Visible = true
        navBar.Visible = true
    end
end)

local function createNavBtn(text, tabToOpen)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 75, 1, 0)
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
local cheatsNav = createNavBtn("Cheats", cheatsTab)
local teleportNav = createNavBtn("Teleport", teleportTab)
local builderNav = createNavBtn("Builder", builderTab)

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
            logAction("FEATURE", text .. " diaktifkan")
        else
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = text .. ": OFF"
            logAction("FEATURE", text .. " dimatikan")
        end
    end)
    return btn
end

-- =======================
-- TABS POPULATION
-- =======================

-- FARM TAB
createToggle("AuraToggle", "Aura Farm", "AuraEnabled", 1, farmTab)

local radiusContainer = Instance.new("Frame")
radiusContainer.Size = UDim2.new(0.9, 0, 0, 35)
radiusContainer.BackgroundTransparency = 1
radiusContainer.LayoutOrder = 2
radiusContainer.Parent = farmTab

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0.55, 0, 1, 0)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Aura Radius:"
radiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusLabel.Font = Enum.Font.GothamBold
radiusLabel.TextSize = 13
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = radiusContainer

local radiusInput = Instance.new("TextBox")
radiusInput.Size = UDim2.new(0.4, 0, 0.8, 0)
radiusInput.Position = UDim2.new(0.6, 0, 0.1, 0)
radiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
radiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusInput.Font = Enum.Font.Gotham
radiusInput.TextSize = 13
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

createToggle("RewardToggle", "Claim Reward", "AutoClaimReward", 3, farmTab)
createToggle("RespawnToggle", "Auto Respawn", "AutoRespawn", 4, farmTab)

-- CHEATS TAB
createToggle("FallDamageToggle", "Anti Fall Dmg", "AntiFallDamage", 1, cheatsTab)
createToggle("NoclipToggle", "Noclip", "Noclip", 2, cheatsTab)
createToggle("SpyToggle", "Spy Trace", "SpyTrace", 3, cheatsTab)
createToggle("DropToggle", "Infinite Drop", "InfiniteDrop", 4, cheatsTab)
createToggle("InvisibleToggle", "Invisible (Desync)", "Invisible", 5, cheatsTab)

-- TELEPORT TAB
local tpContainer = Instance.new("Frame")
tpContainer.Size = UDim2.new(0.9, 0, 0, 70)
tpContainer.BackgroundTransparency = 1
tpContainer.LayoutOrder = 1
tpContainer.Parent = teleportTab

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.48, 0, 0, 30)
refreshBtn.Position = UDim2.new(0, 0, 0, 0)
refreshBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 12
refreshBtn.Text = "Refresh Player"
refreshBtn.Parent = tpContainer

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0.48, 0, 0, 30)
tpBtn.Position = UDim2.new(0.52, 0, 0, 0)
tpBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 12
tpBtn.Text = "Teleport"
tpBtn.Parent = tpContainer

local playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(1, 0, 0, 30)
playerDropdown.Position = UDim2.new(0, 0, 0, 35)
playerDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.TextSize = 12
playerDropdown.Text = "Pilih Pemain..."
playerDropdown.Parent = tpContainer

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, 0, 0, 200)
playerList.Position = UDim2.new(0, 0, 0, 68)
playerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerList.ScrollBarThickness = 4
playerList.Visible = false
playerList.ZIndex = 10
playerList.Parent = tpContainer

local listLayoutTP = Instance.new("UIListLayout")
listLayoutTP.Parent = playerList
listLayoutTP.SortOrder = Enum.SortOrder.Name

local selectedPlayer = nil

local function updatePlayerList()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local ySize = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Text = player.Name
            btn.Name = player.Name
            btn.ZIndex = 11
            btn.Parent = playerList
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                playerDropdown.Text = player.Name
                playerList.Visible = false
                tpContainer.Size = UDim2.new(0.9, 0, 0, 70)
            end)
            ySize = ySize + 25
        end
    end
    playerList.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

refreshBtn.MouseButton1Click:Connect(function()
    updatePlayerList()
    playerDropdown.Text = "Pilih Pemain..."
    selectedPlayer = nil
    if playerList.Visible then
        tpContainer.Size = UDim2.new(0.9, 0, 0, 270)
    end
end)

playerDropdown.MouseButton1Click:Connect(function()
    playerList.Visible = not playerList.Visible
    if playerList.Visible then
        updatePlayerList()
        tpContainer.Size = UDim2.new(0.9, 0, 0, 270)
    else
        tpContainer.Size = UDim2.new(0.9, 0, 0, 70)
    end
end)

tpBtn.MouseButton1Click:Connect(function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            myChar.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            logAction("TELEPORT", "Berhasil teleport ke " .. selectedPlayer.Name)
        end
    end
end)

-- BUILDER TAB
local SavedBase = {}

local copyBaseBtn = Instance.new("TextButton")
copyBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
copyBaseBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
copyBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBaseBtn.Font = Enum.Font.GothamBold
copyBaseBtn.TextSize = 13
copyBaseBtn.Text = "Copy Base (Radius 100)"
copyBaseBtn.LayoutOrder = 1
copyBaseBtn.Parent = builderTab

local pasteBaseBtn = Instance.new("TextButton")
pasteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
pasteBaseBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
pasteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteBaseBtn.Font = Enum.Font.GothamBold
pasteBaseBtn.TextSize = 13
pasteBaseBtn.Text = "Paste Base (Auto Build)"
pasteBaseBtn.LayoutOrder = 2
pasteBaseBtn.Parent = builderTab

local buildStatusLabel = Instance.new("TextLabel")
buildStatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
buildStatusLabel.BackgroundTransparency = 1
buildStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
buildStatusLabel.Font = Enum.Font.Gotham
buildStatusLabel.TextSize = 11
buildStatusLabel.Text = "0 Bangunan Tersimpan"
buildStatusLabel.LayoutOrder = 3
buildStatusLabel.Parent = builderTab

copyBaseBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    SavedBase = {}
    local originCFrame = root.CFrame

    -- Cari bangunan di sekitar
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Filter kasar: biasanya bangunan punya Health atau Owner
        if obj:IsA("Model") and (obj:FindFirstChild("Owner") or obj:FindFirstChild("Health")) then
            local primary = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildOfClass("BasePart")
            if primary then
                local dist = (primary.Position - originCFrame.Position).Magnitude
                if dist <= 100 then
                    -- Simpan tipe bangunan (berdasarkan nama Model) dan posisi relatif
                    local relCFrame = originCFrame:ToObjectSpace(primary.CFrame)
                    table.insert(SavedBase, {
                        Name = obj.Name,
                        RelativeCFrame = relCFrame
                    })
                end
            end
        end
    end
    
    buildStatusLabel.Text = #SavedBase .. " Bangunan Tersimpan"
    logAction("BUILDER", "Berhasil meng-copy " .. #SavedBase .. " bangunan!")
end)

pasteBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "Tidak ada bangunan yang di-copy!")
        return
    end
    
    -- Membutuhkan Log Spy Trace dari User!
    logAction("BUILDER", "MAAF! Sistem Paste belum aktif. Tolong berikan log Spy Trace saat kamu memasang bangunan!")
end)

--------------------------------------------------------------------------------
-- SISTEM DRAG GUI
--------------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    -- Memulai drag hanya saat di-klik/sentuh pada area yang tidak menutupi tombol
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

--------------------------------------------------------------------------------
-- SISTEM AURA & COLLECT
--------------------------------------------------------------------------------
local TARGET_PART_NAMES = {
    ["Hit"]=true, ["Trunk"]=true, ["TreeHingePart"]=true, ["Log"]=true, ["Soil"]=true, ["Bush"]=true,
    ["Wood"]=true, ["Stone"]=true, ["Fiber"]=true, ["Corn"]=true, ["Berries"]=true, ["Well"]=true, 
    ["Spring"]=true, ["Grill"]=true, ["Bed"]=true, ["Door"]=true, ["Forge"]=true, ["Cook Raw Meat"]=true, ["Save"]=true,
    ["Rock"]=true, ["Iron"]=true, ["Gold"]=true, ["Leaves"]=true, ["Raw Meat"]=true, ["Cooked Meat"]=true, ["Plant"]=true,
    -- Tambahan untuk mendeteksi Hewan (NPC) & Pemain secara universal
    ["Head"]=true, ["Torso"]=true, ["UpperTorso"]=true, ["LowerTorso"]=true, ["HumanoidRootPart"]=true,
    ["Right Arm"]=true, ["Left Arm"]=true, ["Right Leg"]=true, ["Left Leg"]=true,
    ["RightHand"]=true, ["LeftHand"]=true, ["RightFoot"]=true, ["LeftFoot"]=true, ["RightLowerArm"]=true, ["LeftLowerArm"]=true, ["RightUpperArm"]=true, ["LeftUpperArm"]=true, ["RightLowerLeg"]=true, ["LeftLowerLeg"]=true, ["RightUpperLeg"]=true, ["LeftUpperLeg"]=true
}

local lastAttackTime = 0
local lastLogTime = 0

-- Cache pintar untuk semua objek yang bisa diklik (0 LAG)
local cachedPrompts = {}

-- Pencarian awal dilakukan di background agar tidak membuat game freeze/crash saat script di-load
task.spawn(function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            cachedPrompts[obj] = true
        end
        count = count + 1
        if count % 1000 == 0 then
            task.wait() -- Mencegah script timeout pada map Booga Booga yang sangat besar
        end
    end
end)
-- Otomatis tambah/hapus jika ada objek baru yang muncul di game
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
            if p:IsA("BasePart") then
                pos = p.Position
            elseif p:IsA("Model") and p.PrimaryPart then
                pos = p.PrimaryPart.Position
            elseif p:IsA("Attachment") then
                pos = p.WorldPosition
            end
            
            if pos and (pos - rootPos).Magnitude <= State.AuraRadius then
                table.insert(nearby, obj)
            end
        end
    end
    return nearby
end

local function getEquippedWeapon()
    if not LocalPlayer.Character then return nil end
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then return tool end
    return nil
end

local function getTargetsInRadius()
    local targetParts = {}
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return targetParts end
    local rootPart = char.HumanoidRootPart

    -- Cek Pemain
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= State.AuraRadius then
                    -- Ambil beberapa part penting dari pemain (R6 dan R15)
                    local partsToHit = {"Torso", "UpperTorso", "Head", "Right Arm"}
                    for _, pName in ipairs(partsToHit) do
                        local p = player.Character:FindFirstChild(pName)
                        if p then table.insert(targetParts, p) end
                    end
                end
            end
        end
    end
    
    -- Cek Objek / Resource / ProximityPrompt
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local parts = workspace:GetPartBoundsInRadius(rootPart.Position, State.AuraRadius, params)
    for _, part in ipairs(parts) do
        local isTarget = false
        
        -- Cek nama part atau nama Parent (karena kadang item drop berupa Model bernama "Wood" yang berisi part bernama "Hitbox")
        if TARGET_PART_NAMES[part.Name] or (part.Parent and TARGET_PART_NAMES[part.Parent.Name]) then
            isTarget = true
        end
        
        -- Deteksi jika itu adalah Tool yang jatuh (Handle)
        if part.Name == "Handle" and part.Parent:IsA("Tool") then
            isTarget = true
        end

        if isTarget then
            table.insert(targetParts, part)
        end
    end

    return targetParts
end

--------------------------------------------------------------------------------
-- MAIN LOOP EKSKUSI SEMUA FITUR
--------------------------------------------------------------------------------
logAction("SYSTEM", "All-In-One Hub berhasil diluncurkan!")

track(RunService.RenderStepped:Connect(function()
    processLogQueue()
    local currentTime = tick()
    
    -- 1. AURA & COLLECT
    if State.AuraEnabled and (currentTime - lastAttackTime >= State.AttackCooldown) then
        local weapon = getEquippedWeapon()
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local weaponHandle = weapon and weapon:FindFirstChild("Handle")
        
        local targets = getTargetsInRadius()
        local hitCount = 0
        
        for _, tPart in ipairs(targets) do
            -- Sentuh dengan senjata (Damage)
            if weaponHandle and firetouchinterest then
                firetouchinterest(tPart, weaponHandle, 0)
                firetouchinterest(tPart, weaponHandle, 1)
            end
            
            -- Sentuh dengan badan (Collect drop items)
            if rootPart and firetouchinterest then
                firetouchinterest(tPart, rootPart, 0)
                firetouchinterest(tPart, rootPart, 1)
            end
            
            -- Trigger Attack Remote bawaan Tool jika ada
            if weapon then
                local atkEvt = weapon:FindFirstChild("AttackEvent")
                if atkEvt and atkEvt:IsA("RemoteEvent") then atkEvt:FireServer() end
            end
            
            hitCount = hitCount + 1
        end
        
        -- Eksekusi SEMUA ProximityPrompt & ClickDetector di radius
        if rootPart then
            local nearbyPrompts = getNearbyPrompts(rootPart.Position)
            for _, promptObj in ipairs(nearbyPrompts) do
                if promptObj:IsA("ProximityPrompt") and fireproximityprompt then
                    fireproximityprompt(promptObj)
                    hitCount = hitCount + 1
                elseif promptObj:IsA("ClickDetector") and fireclickdetector then
                    fireclickdetector(promptObj)
                    hitCount = hitCount + 1
                end
            end
        end
        
        if hitCount > 0 and (currentTime - lastLogTime > 4) then
            logAction("AURA", "Berhasil mengeksekusi " .. hitCount .. " objek dari kejauhan!")
            lastLogTime = currentTime
        end
        
        lastAttackTime = currentTime
    end
    
    -- 2. AUTO CLAIM REWARD
    if State.AutoClaimReward then
        local claim = ReplicatedStorage:FindFirstChild("ClaimReward")
        if claim and claim:IsA("RemoteEvent") then
            -- Hindari spam terlalu gila, gunakan probabilitas kecil tiap frame atau timer
            if math.random(1, 60) == 1 then
                claim:FireServer()
            end
        end
    end
    
    -- 3. AUTO RESPAWN
    if State.AutoRespawn then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then
            local respawn = ReplicatedStorage:FindFirstChild("Respawn")
            if respawn and respawn:IsA("RemoteEvent") then
                respawn:FireServer()
            end
        end
    end
end))

-- 4. NOCLIP & INVISIBLE
track(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        if State.Noclip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        
        -- Invisible (Desync/RootJoint Break)
        if State.Invisible then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local joint = root:FindFirstChild("RootJoint") or root:FindFirstChild("Root")
                if joint then 
                    joint:Destroy()
                    logAction("INVISIBLE", "RootJoint dihancurkan (Karakter menghilang dari server)")
                end
            end
        end
    end
end))

-- 5. UNIVERSAL NAMECALL HOOK (Anti Fall Damage & Spy Trace)
-- Game ini menggunakan ReplicatedStorage.GUIs.Vitals.FallDamageEvent
local fallDamageEvent = ReplicatedStorage:FindFirstChild("GUIs") 
    and ReplicatedStorage.GUIs:FindFirstChild("Vitals") 
    and ReplicatedStorage.GUIs.Vitals:FindFirstChild("FallDamageEvent")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Blokir Fall Damage jika aktif
    if State.AntiFallDamage and method == "FireServer" and self == fallDamageEvent then
        return
    end
    
    -- Infinite Drop / Duplication Exploit (Spoofing Drop Amount)
    if State.InfiniteDrop and method == "FireServer" and (self.Name == "Drop" or self.Name == "DropItem" or self.Name == "DropItems") then
        for i, v in ipairs(args) do
            if type(v) == "number" then
                args[i] = -999999 -- Underflow hack: Coba tipu server bahwa kita nge-drop minus
            end
        end
        return oldNamecall(self, unpack(args))
    end
    
    -- Sistem Trace & Logging
    if State.SpyTrace and (method == "FireServer" or method == "InvokeServer") then
        -- Hindari spam dari remote system/posisi
        if self.Name ~= "Sync" and self.Name ~= "RequestSync" and self.Name ~= "Update" and self.Name ~= "Mouse" and self.Name ~= "Ping" then
            local argsStr = ""
            for i, v in ipairs(args) do
                argsStr = argsStr .. tostring(v) .. (i < #args and ", " or "")
            end
            if string.len(argsStr) > 60 then argsStr = string.sub(argsStr, 1, 60) .. "..." end
            logAction("SPY-REMOTE", string.format("%s | Args: [%s]", self.Name, argsStr))
        end
    end
    
    return oldNamecall(self, ...)
end)

-- 6. EQUIP TOOL TRACKER
local function setupCharacterTracker(char)
    char.ChildAdded:Connect(function(child)
        if State.SpyTrace and child:IsA("Tool") then
            local durStr = "N/A"
            local durability = child:FindFirstChild("Durability") or child:FindFirstChild("Health") or child:FindFirstChild("Toughness") or child:FindFirstChild("Resource")
            if durability then
                durStr = tostring(durability.Value)
                if durability:IsA("NumberValue") or durability:IsA("IntValue") then
                    durStr = durStr .. "%" -- Asumsi persen atau angka solid
                end
            end
            logAction("SPY-ITEM", string.format("Memegang: %s | Sisa/Durability: %s", child.Name, durStr))
        end
    end)
end

if LocalPlayer.Character then setupCharacterTracker(LocalPlayer.Character) end
track(LocalPlayer.CharacterAdded:Connect(setupCharacterTracker))

logAction("SYSTEM", "Universal Hook & Tracker diaktifkan!")
