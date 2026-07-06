local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local AURA_RADIUS = 20
local AURA_ENABLED = true
local ATTACK_COOLDOWN = 0.2 -- Atur sesuai kebutuhan agar tidak terlalu spammy

-- Konfigurasi Webhook
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local logQueue = {}
local lastLogSend = tick()

-- Target parts berdasarkan log untuk pohon, batu, tanaman, dll
local TARGET_PART_NAMES = {
    ["Hit"] = true,
    ["Trunk"] = true,
    ["TreeHingePart"] = true,
    ["Log"] = true,
    ["Soil"] = true,
    ["Bush"] = true
}

local lastAttackTime = 0
local lastLogTime = 0

--------------------------------------------------------------------------------
-- SISTEM LOGGING
--------------------------------------------------------------------------------
local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    
    if AURA_ENABLED then
        table.insert(logQueue, msg)
    end
end

local function processLogQueue()
    if not AURA_ENABLED then
        logQueue = {} -- Bersihkan antrean agar tidak menumpuk di memori
        return
    end
    
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
-- GUI SEDERHANA
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TarungAuraGUI"
gui.ResetOnSpawn = false

-- Proteksi GUI agar tidak mudah terdeteksi
if gethui then
    gui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(gui)
    gui.Parent = CoreGui
else
    gui.Parent = CoreGui
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 90)
frame.Position = UDim2.new(0.5, -100, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "Aura Multi-Tool"
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Text = "AURA: ON"
toggleBtn.Parent = frame

toggleBtn.MouseButton1Click:Connect(function()
    AURA_ENABLED = not AURA_ENABLED
    if AURA_ENABLED then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        toggleBtn.Text = "AURA: ON"
        logAction("SYSTEM", "Aura Damage & Gather dinyalakan.")
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        toggleBtn.Text = "AURA: OFF"
        logAction("SYSTEM", "Aura dimatikan. Berhenti otomatis.")
    end
end)

--------------------------------------------------------------------------------
-- FUNGSI UTAMA
--------------------------------------------------------------------------------
local function getEquippedWeapon()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then
        return tool
    end
    
    return nil
end

local function getTargetsInRadius()
    local targetParts = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return targetParts end
    local rootPart = character.HumanoidRootPart

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local distance = (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance <= AURA_RADIUS then
                    local part = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("HumanoidRootPart")
                    if part then
                        table.insert(targetParts, part)
                    end
                end
            end
        end
    end
    
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {character}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local partsInRadius = workspace:GetPartBoundsInRadius(rootPart.Position, AURA_RADIUS, overlapParams)
    
    for _, part in ipairs(partsInRadius) do
        if TARGET_PART_NAMES[part.Name] then
            table.insert(targetParts, part)
        end
    end

    return targetParts
end

-- Start First Log
logAction("SYSTEM", "Script Aura Berhasil Dieksekusi & Siap Digunakan!")

RunService.RenderStepped:Connect(function()
    processLogQueue() -- Panggil fungsi untuk mengirim log (delay 5 detik)
    
    if not AURA_ENABLED then return end
    
    local currentTime = tick()
    if currentTime - lastAttackTime < ATTACK_COOLDOWN then return end

    local weapon = getEquippedWeapon()
    if not weapon then return end
    
    local weaponHandle = weapon:FindFirstChild("Handle")
    if not weaponHandle then return end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    local targetParts = getTargetsInRadius()
    
    if #targetParts > 0 then
        local hitCount = 0
        
        for _, targetPart in ipairs(targetParts) do
            if targetPart and weaponHandle then
                if firetouchinterest then
                    firetouchinterest(targetPart, weaponHandle, 0)
                    firetouchinterest(targetPart, weaponHandle, 1)
                    
                    if rootPart then
                        firetouchinterest(targetPart, rootPart, 0)
                        firetouchinterest(targetPart, rootPart, 1)
                    end
                end

                if fireproximityprompt then
                    local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        fireproximityprompt(prompt)
                    end
                end
                
                local attackEvent = weapon:FindFirstChild("AttackEvent")
                if attackEvent and attackEvent:IsA("RemoteEvent") then
                    attackEvent:FireServer()
                end
                
                hitCount = hitCount + 1
            end
        end
        
        -- Catat ke log setiap 3 detik jika mengenai target agar tidak spam log
        if hitCount > 0 and (currentTime - lastLogTime > 3) then
            logAction("AURA", "Berhasil menyentuh/mengambil " .. hitCount .. " objek dari jarak jauh.")
            lastLogTime = currentTime
        end
        
        lastAttackTime = currentTime
    end
end)
