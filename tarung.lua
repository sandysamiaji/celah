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
    Fly = false,
    FlySpeed = 16,
    WebhookLogs = false, -- Default mati
    FlingAura = false,
    CopyRadius = 500,
    AuraRadius = 35,
    AttackCooldown = 0.2,
    SelectedPlayer = nil
}

-- Logging System
local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(logQueue, msg)
end

local function processLogQueue()
    if #logQueue == 0 then return end
    
    local payload = {
        content = table.concat(logQueue, "\n")
    }
    
    -- Clear queue
    logQueue = {}
    
    -- Jika toggle webhook dari depan (UI) dimatikan, batalkan pengiriman
    if not State.WebhookLogs then return end

    
    -- Ambil fungsi request exploit (synapse, krnl, fluxus, dll)
    local req = (syn and syn.request) or request or (http and http.request) or http_request
    if req then
        pcall(function()
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
end

-- Menjalankan processLogQueue setiap 5 detik agar terhindar dari spam/rate limit
coroutine.wrap(function()
    while true do
        wait(5)
        processLogQueue()
    end
end)()

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
frame.Size = UDim2.new(0, 330, 0, 380)
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
        frame.Size = UDim2.new(0, 330, 0, 40)
        minimizeBtn.Text = "+"
        bodyFrame.Visible = false
    else
        frame.Size = UDim2.new(0, 330, 0, 380)
        minimizeBtn.Text = "-"
        bodyFrame.Visible = true
    end
end)

local function createNavBtn(text, tabToOpen)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 35) -- Menyisakan sedikit margin

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
local noclipBtn = createToggle("NoclipToggle", "Noclip", "Noclip", 2, cheatsTab)
createToggle("SpyToggle", "Spy Trace", "SpyTrace", 3, cheatsTab)
createToggle("DropToggle", "Infinite Drop", "InfiniteDrop", 4, cheatsTab)
createToggle("FlyToggle", "Fly", "Fly", 5, cheatsTab)

local flySpeedContainer = Instance.new("Frame")
flySpeedContainer.Size = UDim2.new(0.9, 0, 0, 35)
flySpeedContainer.BackgroundTransparency = 1
flySpeedContainer.LayoutOrder = 6
flySpeedContainer.Parent = cheatsTab

local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Size = UDim2.new(0.55, 0, 1, 0)
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.Text = "Fly Speed:"
flySpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedLabel.Font = Enum.Font.GothamBold
flySpeedLabel.TextSize = 13
flySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
flySpeedLabel.Parent = flySpeedContainer

local flySpeedInput = Instance.new("TextBox")
flySpeedInput.Size = UDim2.new(0.4, 0, 0.8, 0)
flySpeedInput.Position = UDim2.new(0.6, 0, 0.1, 0)
flySpeedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedInput.Font = Enum.Font.Gotham
flySpeedInput.TextSize = 13
flySpeedInput.Text = tostring(State.FlySpeed)
flySpeedInput.PlaceholderText = "Speed"
flySpeedInput.Parent = flySpeedContainer

flySpeedInput.FocusLost:Connect(function()
    local num = tonumber(flySpeedInput.Text)
    if num then
        if num < 0 then num = 0 end
        if num > 500 then num = 500 end
        State.FlySpeed = num
        flySpeedInput.Text = tostring(num)
    else
        flySpeedInput.Text = tostring(State.FlySpeed)
    end
end)

createToggle("WebhookToggle", "Enable Webhook Log", "WebhookLogs", 7, cheatsTab)

-- TELEPORT TAB
local tpContainer = Instance.new("Frame")
tpContainer.Size = UDim2.new(0.9, 0, 0, 105)
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
refreshBtn.Text = "Refresh List"
refreshBtn.Parent = tpContainer

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0.48, 0, 0, 30)
tpBtn.Position = UDim2.new(0.52, 0, 0, 0)
tpBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 12
tpBtn.Text = "TP Ke Dia"
tpBtn.Parent = tpContainer

local bringBtn = Instance.new("TextButton")
bringBtn.Size = UDim2.new(0.48, 0, 0, 30)
bringBtn.Position = UDim2.new(0, 0, 0, 35)
bringBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bringBtn.Font = Enum.Font.GothamBold
bringBtn.TextSize = 12
bringBtn.Text = "Belakang Dia"
bringBtn.Parent = tpContainer

local flingPlayerBtn = Instance.new("TextButton")
flingPlayerBtn.Size = UDim2.new(0.48, 0, 0, 30)
flingPlayerBtn.Position = UDim2.new(0.52, 0, 0, 35)
flingPlayerBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
flingPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingPlayerBtn.Font = Enum.Font.GothamBold
flingPlayerBtn.TextSize = 12
flingPlayerBtn.Text = "Nendang Pemain"
flingPlayerBtn.Parent = tpContainer

local playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(1, 0, 0, 30)
playerDropdown.Position = UDim2.new(0, 0, 0, 70)
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
                selectedPlayer = player.Name
                State.SelectedPlayer = player.Name
                playerDropdown.Text = player.Name
                playerList.Visible = false
                tpContainer.Size = UDim2.new(0.9, 0, 0, 105)
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
        tpContainer.Size = UDim2.new(0.9, 0, 0, 305)
    end
end)

playerDropdown.MouseButton1Click:Connect(function()
    playerList.Visible = not playerList.Visible
    if playerList.Visible then
        updatePlayerList()
        tpContainer.Size = UDim2.new(0.9, 0, 0, 305)
    else
        tpContainer.Size = UDim2.new(0.9, 0, 0, 105)
    end
end)

local function checkTeleportRequirements()
    if not selectedPlayer then
        logAction("TELEPORT", "Gagal: Kamu belum memilih pemain dari daftar!")
        return false
    end
    
    local targetName = type(selectedPlayer) == "string" and selectedPlayer or selectedPlayer.Name
    local targetPlayer = Players:FindFirstChild(targetName)
    
    if not targetPlayer then
        logAction("TELEPORT", "Gagal: Pemain " .. targetName .. " tidak ditemukan di server!")
        return false
    end

    local targetChar = targetPlayer.Character
    if not targetChar then
        logAction("TELEPORT", "Gagal: Pemain " .. targetName .. " belum spawn (Character nil)!")
        return false
    end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChildWhichIsA("BasePart", true)
    if not targetRoot then
        logAction("TELEPORT", "Gagal: Pemain " .. targetName .. " belum memiliki bagian tubuh (BasePart)!")
        return false
    end
    
    local myChar = LocalPlayer.Character
    if not myChar then
        logAction("TELEPORT", "Gagal: Karaktermu belum spawn!")
        return false
    end
    
    local root = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso") or myChar:FindFirstChildWhichIsA("BasePart", true)
    if not root then
        logAction("TELEPORT", "Gagal: Karaktermu tidak memiliki bagian tubuh (BasePart)!")
        return false
    end
    
    return true, root, targetRoot, targetName
end

tpBtn.MouseButton1Click:Connect(function()
    local success, root, targetRoot, targetName = checkTeleportRequirements()
    if success then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        logAction("TELEPORT", "Berhasil teleport INSTAN ke " .. targetName)
    end
end)

bringBtn.MouseButton1Click:Connect(function()
    local success, root, targetRoot, targetName = checkTeleportRequirements()
    if success then
        pcall(function()
            -- Teleport kita ke punggung/belakang musuh
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
            logAction("TELEPORT", "Berhasil teleport ke belakang " .. targetName)
        end)
    end
end)

flingPlayerBtn.MouseButton1Click:Connect(function()
    local success, root, targetRoot, targetName = checkTeleportRequirements()
    if success then
        coroutine.wrap(function()
            local char = LocalPlayer.Character
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            
            -- Deteksi otomatis senjata yang sedang di-equip atau ada di backpack
            local punchTool = nil
            -- Prioritas 1: Tool yang SEDANG di-equip di karakter
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then
                    punchTool = v
                    logAction("FLING", "Menggunakan senjata yang sedang di-equip: " .. v.Name)
                    break
                end
            end
            -- Prioritas 2: Tool pertama di backpack jika tidak ada yang di-equip
            if not punchTool and backpack then
                for _, v in ipairs(backpack:GetChildren()) do
                    if v:IsA("Tool") then
                        punchTool = v
                        logAction("FLING", "Senjata di-equip dari backpack: " .. v.Name)
                        break
                    end
                end
            end
            
            if not punchTool then
                logAction("FLING", "Gagal: Tidak ada tool di backpack! Ambil Punch dulu.")
                return
            end
            
            logAction("FLING", "Auto-Punch ke " .. targetName .. " menggunakan " .. punchTool.Name)
            
            -- Equip tool ke karakter
            punchTool.Parent = char
            wait(0.15)
            
            -- Simpan posisi awal
            local oldPos = root.CFrame
            
            -- Auto-punch 5x: setiap iterasi, TP ke samping target, hadap dia, pukul
            for i = 1, 5 do
                if not (targetRoot and targetRoot.Parent) then break end
                
                -- Berdiri tepat di depan target (jarak 2.5 stud)
                local targetCF = targetRoot.CFrame
                root.CFrame = CFrame.lookAt(
                    targetCF.Position + targetCF.LookVector * 2.5,
                    targetCF.Position
                )
                wait(0.05)
                punchTool:Activate()
                wait(0.12)
            end
            
            -- Kembali ke posisi awal
            root.CFrame = oldPos
            
            -- Kembalikan tool ke backpack
            if punchTool and punchTool.Parent == char then
                punchTool.Parent = backpack
            end
            
            logAction("FLING", "Auto-Punch ke " .. targetName .. " selesai!")
        end)()
    end
end)

-- BUILDER TAB
local SavedBase = {}
local BaseDatabase = {}
local selectedBaseName = nil

local builderRadiusInput = Instance.new("TextBox")
builderRadiusInput.Size = UDim2.new(0.9, 0, 0, 30)
builderRadiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
builderRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
builderRadiusInput.Font = Enum.Font.Gotham
builderRadiusInput.TextSize = 13
builderRadiusInput.Text = tostring(State.CopyRadius)
builderRadiusInput.PlaceholderText = "Radius (Studs)"
builderRadiusInput.LayoutOrder = 1
builderRadiusInput.Parent = builderTab

local copyBaseBtn = Instance.new("TextButton")
copyBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
copyBaseBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
copyBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBaseBtn.Font = Enum.Font.GothamBold
copyBaseBtn.TextSize = 13
copyBaseBtn.Text = "Copy Base (Radius " .. State.CopyRadius .. ")"
copyBaseBtn.LayoutOrder = 2
copyBaseBtn.Parent = builderTab

builderRadiusInput.FocusLost:Connect(function()
    local num = tonumber(builderRadiusInput.Text)
    if num then
        if num < 10 then num = 10 end
        if num > 5000 then num = 5000 end
        State.CopyRadius = num
        builderRadiusInput.Text = tostring(num)
        copyBaseBtn.Text = "Copy Base (Radius " .. num .. ")"
    else
        builderRadiusInput.Text = tostring(State.CopyRadius)
    end
end)

local buildStatusLabel = Instance.new("TextLabel")
buildStatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
buildStatusLabel.BackgroundTransparency = 1
buildStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
buildStatusLabel.Font = Enum.Font.Gotham
buildStatusLabel.TextSize = 11
buildStatusLabel.Text = "0 Bangunan Tersimpan"
buildStatusLabel.LayoutOrder = 3
buildStatusLabel.Parent = builderTab

local baseNameInput = Instance.new("TextBox")
baseNameInput.Size = UDim2.new(0.9, 0, 0, 30)
baseNameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
baseNameInput.Font = Enum.Font.Gotham
baseNameInput.TextSize = 12
baseNameInput.Text = ""
baseNameInput.PlaceholderText = "Nama Base (Contoh: rumah panda)"
baseNameInput.LayoutOrder = 4
baseNameInput.Parent = builderTab

local saveBaseBtn = Instance.new("TextButton")
saveBaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
saveBaseBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
saveBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBaseBtn.Font = Enum.Font.GothamBold
saveBaseBtn.TextSize = 12
saveBaseBtn.Text = "Simpan Base ke List"
saveBaseBtn.LayoutOrder = 5
saveBaseBtn.Parent = builderTab

local loadBaseBtn = Instance.new("TextButton")
loadBaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
loadBaseBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
loadBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBaseBtn.Font = Enum.Font.GothamBold
loadBaseBtn.TextSize = 12
loadBaseBtn.Text = "Muat Semua Data dari File"
loadBaseBtn.LayoutOrder = 6
loadBaseBtn.Parent = builderTab

local baseDropdown = Instance.new("TextButton")
baseDropdown.Size = UDim2.new(0.9, 0, 0, 30)
baseDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
baseDropdown.Font = Enum.Font.Gotham
baseDropdown.TextSize = 12
baseDropdown.Text = "Pilih Base dari List..."
baseDropdown.LayoutOrder = 7
baseDropdown.Parent = builderTab

local baseList = Instance.new("ScrollingFrame")
baseList.Size = UDim2.new(0.9, 0, 0, 0)
baseList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
baseList.BorderSizePixel = 0
baseList.ScrollBarThickness = 4
baseList.Visible = false
baseList.LayoutOrder = 8
baseList.Parent = builderTab

local baseListLayout = Instance.new("UIListLayout")
baseListLayout.Parent = baseList
baseListLayout.SortOrder = Enum.SortOrder.Name

local pasteBaseBtn = Instance.new("TextButton")
pasteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
pasteBaseBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
pasteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteBaseBtn.Font = Enum.Font.GothamBold
pasteBaseBtn.TextSize = 13
pasteBaseBtn.Text = "Paste Base Terpilih"
pasteBaseBtn.LayoutOrder = 9
pasteBaseBtn.Parent = builderTab

local function updateBaseList()
    for _, child in ipairs(baseList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local ySize = 0
    for bName, _ in pairs(BaseDatabase) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Text = bName
        btn.Name = bName
        btn.Parent = baseList
        
        btn.MouseButton1Click:Connect(function()
            selectedBaseName = bName
            baseDropdown.Text = bName
            baseList.Visible = false
            baseList.Size = UDim2.new(0.9, 0, 0, 0)
            
            -- Set SavedBase ke base yang dipilih agar siap di-paste
            SavedBase = BaseDatabase[bName]
            buildStatusLabel.Text = #SavedBase .. " Bangunan (" .. bName .. ") Siap Di-paste"
        end)
        ySize = ySize + 25
    end
    baseList.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

baseDropdown.MouseButton1Click:Connect(function()
    baseList.Visible = not baseList.Visible
    if baseList.Visible then
        updateBaseList()
        baseList.Size = UDim2.new(0.9, 0, 0, 100)
    else
        baseList.Size = UDim2.new(0.9, 0, 0, 0)
    end
end)

copyBaseBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    SavedBase = {}
    -- Mengambil posisi murni karakter (XYZ)
    local originPos = root.Position

    -- Cari bangunan di sekitar
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local isBuilding = false
            
            -- Indikator kuat: Jika punya Owner/Creator
            if obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Placer") then
                isBuilding = true
            end
            
            -- Filter berdasarkan kata kunci nama (Wall, Foundation, dll)
            local n = obj.Name:lower()
            if not isBuilding then
                if (string.find(n, "wall") or string.find(n, "foundation") or string.find(n, "stairs") or 
                    string.find(n, "door") or string.find(n, "window") or string.find(n, "bed") or 
                    string.find(n, "fire") or string.find(n, "well") or string.find(n, "torch") or 
                    string.find(n, "chest") or string.find(n, "gate") or string.find(n, "bridge")) then
                    
                    -- Pastikan BUKAN sumber daya alam
                    if not string.find(n, "tree") and not string.find(n, "rock") and not string.find(n, "ore") and not string.find(n, "bush") then
                        isBuilding = true
                    end
                end
            end

            if isBuilding then
                local primary = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildOfClass("BasePart")
                if primary then
                    local dist = (primary.Position - originPos).Magnitude
                    if dist <= State.CopyRadius then
                        -- Simpan jarak (Offset) dari karakter dan rotasi murni bangunannya
                        local offset = primary.Position - originPos
                        local rotCFrame = primary.CFrame - primary.Position
                        table.insert(SavedBase, {
                            Name = obj.Name,
                            Offset = offset,
                            Rotation = rotCFrame
                        })
                    end
                end
            end
        end
    end
    
    buildStatusLabel.Text = #SavedBase .. " Bangunan Tersimpan"
    logAction("BUILDER", "Berhasil meng-copy " .. #SavedBase .. " bangunan!")
end)

saveBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "Gagal: Tidak ada base yang sedang di-copy!")
        return
    end
    local bName = baseNameInput.Text
    if bName == "" or bName:match("^%s*$") then
        logAction("BUILDER", "Gagal: Masukkan nama base dulu! (Contoh: rumah panda)")
        return
    end
    
    -- Simpan base saat ini ke database internal
    BaseDatabase[bName] = {}
    for _, item in ipairs(SavedBase) do
        table.insert(BaseDatabase[bName], {
            Name = item.Name,
            Offset = item.Offset,
            Rotation = item.Rotation
        })
    end
    
    if writefile and HttpService then
        local serializedDB = {}
        for key, baseArr in pairs(BaseDatabase) do
            local sArr = {}
            for _, item in ipairs(baseArr) do
                table.insert(sArr, {
                    Name = item.Name,
                    OffsetX = item.Offset.X,
                    OffsetY = item.Offset.Y,
                    OffsetZ = item.Offset.Z,
                    RotComponents = {item.Rotation:components()}
                })
            end
            serializedDB[key] = sArr
        end
        local success, err = pcall(function()
            local jsonString = HttpService:JSONEncode(serializedDB)
            writefile("PandaBooga_BasesDB.json", jsonString)
        end)
        if success then
            logAction("BUILDER", "Base '" .. bName .. "' berhasil disimpan ke list!")
            updateBaseList()
        else
            logAction("BUILDER", "Gagal menyimpan file: " .. tostring(err))
        end
    else
        logAction("BUILDER", "Disimpan di list sementara (Executor tidak mendukung writefile).")
        updateBaseList()
    end
end)

loadBaseBtn.MouseButton1Click:Connect(function()
    if readfile and isfile and HttpService then
        if not isfile("PandaBooga_BasesDB.json") then
            -- Fallback jika file versi sebelumnya yang ada
            if isfile("PandaBooga_SavedBase.json") then
                logAction("BUILDER", "INFO: Ditemukan file lama, harap Copy dan Save ulang dengan nama baru.")
            else
                logAction("BUILDER", "Gagal: File PandaBooga_BasesDB.json tidak ditemukan!")
            end
            return
        end
        local success, err = pcall(function()
            local jsonString = readfile("PandaBooga_BasesDB.json")
            local serializedDB = HttpService:JSONDecode(jsonString)
            BaseDatabase = {}
            for key, baseArr in pairs(serializedDB) do
                local arr = {}
                for _, item in ipairs(baseArr) do
                    table.insert(arr, {
                        Name = item.Name,
                        Offset = Vector3.new(item.OffsetX, item.OffsetY, item.OffsetZ),
                        Rotation = CFrame.new(unpack(item.RotComponents))
                    })
                end
                BaseDatabase[key] = arr
            end
        end)
        if success then
            logAction("BUILDER", "Berhasil memuat list base dari file! Silakan pilih di dropdown.")
            updateBaseList()
        else
            logAction("BUILDER", "Gagal memuat file: " .. tostring(err))
        end
    else
        logAction("BUILDER", "Gagal: Executor kamu tidak mendukung fungsi readfile/isfile!")
    end
end)

pasteBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "Tidak ada bangunan yang di-copy!")
        return
    end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Mengambil titik posisi karakter saat tombol paste ditekan
    local currentPos = root.Position
    
    -- Cari remote PlaceBuild sekali saja
    local placeEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "PlaceBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            placeEvent = desc
            break
        end
    end
    
    if not placeEvent then
        logAction("BUILDER", "Gagal! Remote 'PlaceBuild' tidak ditemukan!")
        return
    end
    
    logAction("BUILDER", "Memulai proses Paste Skybase " .. #SavedBase .. " bangunan...")
    
    local tribeEvents = ReplicatedStorage:FindFirstChild("TribeEvents")
    local leaveTribe = tribeEvents and tribeEvents:FindFirstChild("LeaveTribe")
    local createTribe = tribeEvents and tribeEvents:FindFirstChild("CreateTribe")
    
    if leaveTribe and createTribe then
        logAction("BUILDER", "[INFO] Fitur Auto Tribe-Hop Ditemukan & Aktif!")
    end

    -- Mulai proses Paste di background agar tidak hang
    coroutine.wrap(function()
        local count = 0
        
        for _, data in ipairs(SavedBase) do
            -- TRIBE HOPPING: Reset Limit sebelum menyentuh 1200
            if count > 0 and count % 1155 == 0 and leaveTribe and createTribe then
                logAction("BUILDER", "Limit hampir penuh (1150). Mengeksekusi Auto Tribe-Hop...")
                leaveTribe:FireServer()
                wait(0.5)
                createTribe:FireServer("InfinityBase" .. tostring(math.random(100,999)))
                wait(0.5)
                logAction("BUILDER", "Limit berhasil direset! Melanjutkan pembangunan...")
            end

            -- Logika Murni: (Posisi Karakter Saat Ini) + (Naik 20 Studs) + (Jarak Bangunan Waktu Dicopy)
            local targetPos = currentPos + Vector3.new(0, 20, 0) + data.Offset
            local targetCFrame = CFrame.new(targetPos) * data.Rotation
            
            if placeEvent:IsA("RemoteEvent") then
                placeEvent:FireServer(data.Name, targetCFrame)
            else
                placeEvent:InvokeServer(data.Name, targetCFrame)
            end
            
            count = count + 1
            wait(0.3) -- Jeda kecepatan naruh barang agar tidak terdeteksi rate limit server
        end
        
        logAction("BUILDER", "Berhasil membangun Skybase berisi " .. count .. " bangunan (Limit By-passed)!")
    end)()
end)

-- TOMBOL DUPE LIMIT (GLITCH SERVER)
local dupeLimitBtn = Instance.new("TextButton")
dupeLimitBtn.Size = UDim2.new(0.9, 0, 0, 35)
dupeLimitBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
dupeLimitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dupeLimitBtn.Font = Enum.Font.GothamBold
dupeLimitBtn.TextSize = 13
dupeLimitBtn.Text = "GLITCH / DUPE LIMIT (-3000)"
dupeLimitBtn.LayoutOrder = 5
dupeLimitBtn.Parent = builderTab

dupeLimitBtn.MouseButton1Click:Connect(function()
    local deleteEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "DeleteBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            deleteEvent = desc
            break
        end
    end
    
    if not deleteEvent then
        logAction("BUILDER", "Gagal! Remote 'DeleteBuild' tidak ditemukan!")
        return
    end

    -- Cari SEMBARANG bangunan yang ada di map untuk dikorbankan sebagai tumbal spam
    local tumbalObj = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == "Wood Wall" or obj.Name == "Stone Wall" or obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator")) then
            tumbalObj = obj
            break
        end
    end

    if not tumbalObj then
        logAction("BUILDER", "Gagal! Kamu butuh minimal 1 bangunan (Wood Wall) di tanah sebagai tumbal.")
        return
    end

    logAction("BUILDER", "Mengeksekusi EXTREME SPAM pada DeleteBuild (Menembus Limit)...")
    
    -- Eksekusi bom 10000 sinyal bersamaan TANPA JEDA (Race Condition)
    for i = 1, 10000 do
        coroutine.wrap(function()
            if deleteEvent:IsA("RemoteEvent") then
                deleteEvent:FireServer(tumbalObj)
            else
                deleteEvent:InvokeServer(tumbalObj)
            end
        end)()
    end
    
    logAction("BUILDER", "Serangan 10000 request selesai! Limitmu sekarang Minus drastis/Infinite!")
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
coroutine.wrap(function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            cachedPrompts[obj] = true
        end
        count = count + 1
        if count % 1000 == 0 then
            wait() -- Mencegah script timeout pada map Booga Booga yang sangat besar
        end
    end
end)()
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

-- 4. NOCLIP & FLY
local bbg, bve
local wasNoclipping = false

track(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        -- Noclip
        if State.Noclip or State.Fly then
            wasNoclipping = true
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        elseif wasNoclipping then
            wasNoclipping = false
            -- Kembalikan tabrakan (collision) ke bagian tubuh utama agar tidak nembus lagi
            local mainParts = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
            for _, name in ipairs(mainParts) do
                local p = char:FindFirstChild(name)
                if p and p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end
end))

local camera = workspace.CurrentCamera
local getMoveVector
pcall(function()
    local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
    local controls = PlayerModule:GetControls()
    getMoveVector = function()
        return controls:GetMoveVector()
    end
end)

if not getMoveVector then
    local control = {w=0, a=0, s=0, d=0}
    track(UserInputService.InputBegan:Connect(function(input, gp)
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.W then control.w = 1
        elseif input.KeyCode == Enum.KeyCode.S then control.s = -1
        elseif input.KeyCode == Enum.KeyCode.A then control.a = -1
        elseif input.KeyCode == Enum.KeyCode.D then control.d = 1
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.W then control.w = 0
        elseif input.KeyCode == Enum.KeyCode.S then control.s = 0
        elseif input.KeyCode == Enum.KeyCode.A then control.a = 0
        elseif input.KeyCode == Enum.KeyCode.D then control.d = 0
        end
    end))
    getMoveVector = function()
        return Vector3.new(control.d + control.a, 0, -(control.w + control.s))
    end
end

local fakeFloor = nil
track(RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if State.Fly and root and hum then
            if not fakeFloor then
                fakeFloor = Instance.new("Part")
                fakeFloor.Size = Vector3.new(5, 1, 5)
                fakeFloor.Anchored = true
                fakeFloor.Transparency = 1
                fakeFloor.CanCollide = true
                fakeFloor.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                fakeFloor.Parent = workspace
            end
            if not bbg then
                bbg = Instance.new("BodyGyro")
                bbg.P = 9e4
                bbg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                bbg.Parent = root
            end
            if not bve then
                bve = Instance.new("BodyVelocity")
                bve.maxForce = Vector3.new(9e9, 9e9, 9e9)
                bve.Parent = root
            end
            
            hum.PlatformStand = false
            
            -- Pasang lantai di bawah kaki agar animasi jalan/idle tetap berjalan
            fakeFloor.CFrame = root.CFrame - Vector3.new(0, 3.2, 0)
            
            -- Arahkan badan karakter mengikuti kamera secara horizontal (agar tidak nungging)
            local look = camera.CFrame.LookVector
            bbg.cframe = CFrame.new(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))
            
            local moveVec = getMoveVector()
            local dir = camera.CFrame.LookVector * -moveVec.Z + camera.CFrame.RightVector * moveVec.X
            if dir.Magnitude > 0 then
                dir = dir.Unit
            end
            
            bve.velocity = dir * State.FlySpeed
        else
            if fakeFloor then fakeFloor:Destroy(); fakeFloor = nil end
            if bbg then bbg:Destroy(); bbg = nil end
            if bve then bve:Destroy(); bve = nil end
            if hum and hum.PlatformStand then
                hum.PlatformStand = false
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
        if self.Name ~= "Sync" and self.Name ~= "RequestSync" and self.Name ~= "Update" and self.Name ~= "Mouse" and self.Name ~= "Ping" then
            local argsStr = ""
            for i, v in ipairs(args) do
                -- Tangkap tipe data asli (berguna untuk melihat CFrame/Vector3/String)
                local vStr = type(v) == "userdata" and typeof(v) .. "(" .. tostring(v) .. ")" or tostring(v)
                argsStr = argsStr .. vStr .. (i < #args and ", " or "")
            end
            if string.len(argsStr) > 500 then argsStr = string.sub(argsStr, 1, 500) .. "..." end
            logAction("SPY-REMOTE", string.format("%s | Args: [%s]", self.Name, argsStr))
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    -- Jika di masa depan ada manipulasi Index lainnya bisa ditambah di sini
    return oldIndex(self, key)
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
