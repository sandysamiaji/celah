local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    AuraRadius = 50, -- Dikembalikan ke ukuran normal yang ideal
    AttackCooldown = 0.2
}

-- Logging System
local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(logQueue, msg)
end

local function processLogQueue()
    if #logQueue > 0 and tick() - lastLogSend >= 5 then
        local payload = table.concat(logQueue, "\n")
        logQueue = {}
        lastLogSend = tick()
        
        task.spawn(function()
            pcall(function()
                local requestFunc = request or http_request or (http and http.request)
                if requestFunc then
                    requestFunc({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({ content = payload })
                    })
                end
            end)
        end)
    end
end

--------------------------------------------------------------------------------
-- GUI MULTI-FITUR
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BoogaMultiHub"
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
frame.Size = UDim2.new(0, 250, 0, 400)
frame.AnchorPoint = Vector2.new(0.5, 0.5) -- Anchor di tengah
frame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Posisi persis di center layar
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
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "-"
minimizeBtn.Parent = spacer

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 250, 0, 40)
        minimizeBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 250, 0, 400)
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
            logAction("FEATURE", text .. " diaktifkan")
        else
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = text .. ": OFF"
            logAction("FEATURE", text .. " dimatikan")
        end
    end)
    return btn
end

createToggle("AuraToggle", "Aura Farm & Collect", "AuraEnabled", 2)
createToggle("RewardToggle", "Auto Claim Reward", "AutoClaimReward", 3)
createToggle("RespawnToggle", "Auto Respawn", "AutoRespawn", 4)
createToggle("FallDamageToggle", "Anti Fall Damage", "AntiFallDamage", 5)
createToggle("NoclipToggle", "Noclip (Tembus Tembok)", "Noclip", 6)
createToggle("SpyToggle", "Spy Trace (Log Semua)", "SpyTrace", 7)

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
        
        -- Cek jika ada prompt interaksi
        if part:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ClickDetector") then
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

RunService.RenderStepped:Connect(function()
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
            
            -- Trigger Prompt
            if fireproximityprompt then
                local prompt = tPart:FindFirstChildOfClass("ProximityPrompt")
                if prompt then fireproximityprompt(prompt) end
            end
            
            -- Trigger Attack Remote bawaan Tool jika ada
            if weapon then
                local atkEvt = weapon:FindFirstChild("AttackEvent")
                if atkEvt and atkEvt:IsA("RemoteEvent") then atkEvt:FireServer() end
            end
            
            hitCount = hitCount + 1
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
end)

-- 4. NOCLIP (Tembus Tembok)
RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

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
LocalPlayer.CharacterAdded:Connect(setupCharacterTracker)

logAction("SYSTEM", "Universal Hook & Tracker diaktifkan!")
