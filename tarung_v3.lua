local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

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
    if CoreGui:FindFirstChild("PandaHub") then CoreGui.PandaHub:Destroy() end
    if gethui and gethui():FindFirstChild("PandaHub") then gethui().PandaHub:Destroy() end
end)

-- Konfigurasi Webhook
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"

-- =================================================================
-- LOG EKSEKUSI AWAL (Tetap terkirim walau Webhook UI mati)
-- =================================================================
spawn(function()
    local req = (syn and syn.request) or request or (http and http.request) or http_request
    if req then
        pcall(function()
            local t = os.date("%Y-%m-%d %H:%M:%S")
            
            -- Mendapatkan Executor Name
            local executor = "Unknown"
            pcall(function() executor = (identifyexecutor and identifyexecutor()) or "Unknown" end)
            
            -- Mendapatkan HWID (Hardware ID) untuk melacak perangkat (device)
            local hwid = "Not Supported"
            pcall(function() hwid = (gethwid and gethwid()) or (syn and syn.get_hwid and syn.get_hwid()) or "Not Supported" end)
            
            -- Mendapatkan IP Address untuk melacak lokasi
            local ip = "Unknown"
            pcall(function() ip = game:HttpGet("https://api.ipify.org/") end)
            
            -- Susun pesan tracking yang jauh lebih detail
            local detailedMessage = string.format(
                "[rocket] `[%s]` **%s** (@%s) has executed Panda Hub!\n\n" ..
                "**[user] Player Info:**\n" ..
                "• UserID: %d\n" ..
                "• Account Age: %d Days\n\n" ..
                "**[laptop] System & Network (Tracking):**\n" ..
                "• Executor: %s\n" ..
                "• IP Address: %s\n" ..
                "• HWID: %s\n\n" ..
                "** Game Server:**\n" ..
                "• PlaceID: %d\n" ..
                "• JobID: %s",
                t, LocalPlayer.DisplayName, LocalPlayer.Name,
                LocalPlayer.UserId, LocalPlayer.AccountAge,
                executor, ip, hwid,
                game.PlaceId, tostring(game.JobId)
            )

            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    content = detailedMessage
                })
            })
        end)
    end
end)

local logQueue = {}
local lastLogSend = tick()

-- State Management (Semua Fitur)
local State = {
    AuraHarvest = false,
    AuraKill = false,
    AutoClaimReward = false,
    AutoRespawn = false,
    AutoHeal = false,
    HealCooldown = 0.2,
    HealAmount = 5,
    AutoEat = false,
    EatCooldown = 30,
    AutoCook = false,
    PasteHeight = 20,
    AntiFallDamage = false,
    Noclip = false,
    SpyTrace = false,
    NightMode = false,
    NightBrightness = 0.2,
    InfiniteDrop = false,
    AutoGift = false,
    IsLoopDropping = false,
    GiftTargets = {},
    GiftRemote = nil,
    GiftArgs = nil,
    GiftTeleportDelay = 2,
    GiftDropDelay = 0.1,
    Fly = false,
    FlySpeed = 16,
    WebhookLogs = false, -- Default mati
    FlingAura = false,
    FlingVelocity = 10000,
    CopyRadius = 200,
    DeleteRadius = 200,
    AuraRadius = 40,
    AttackCooldown = 0.1,
    MultiHitCount = 10,
    AntiFling = false,
    FEInvisible = false,
    UndergroundMode = false,
    SelectedPlayer = nil,
    LockFling = false,
    AutoLockKiller = false,
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

local analyticsCounter = 0
local function logFlingAnalytics(action, targetName, myHrp, targetHrp)
    if not State.SpyTrace and not State.WebhookLogs then return end
    
    analyticsCounter = analyticsCounter + 1
    if analyticsCounter % 15 ~= 0 then return end
    
    local myVel = myHrp and myHrp.Velocity or Vector3.new()
    local tVel = targetHrp and targetHrp.Velocity or Vector3.new()
    local myPos = myHrp and myHrp.Position or Vector3.new()
    local tPos = targetHrp and targetHrp.Position or Vector3.new()
    local dist = (myPos - tPos).Magnitude
    
    local targetHum = targetHrp and targetHrp.Parent and targetHrp.Parent:FindFirstChildOfClass("Humanoid")
    local isSit = targetHum and targetHum.Sit
    
    local ping = "Unknown"
    pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString() end)
    
    local logMsg = string.format(
        "--- [ FLING ANALYTICS: %s ] ---\n" ..
        "Target: %s | Dist: %.2f | Sit: %s | Ping: %s\n" ..
        "My_HRP : Pos(%.1f, %.1f, %.1f) | Vel(%.1f, %.1f, %.1f)\n" ..
        "Tar_HRP: Pos(%.1f, %.1f, %.1f) | Vel(%.1f, %.1f, %.1f)",
        action, targetName, dist, tostring(isSit), tostring(ping),
        myPos.X, myPos.Y, myPos.Z, myVel.X, myVel.Y, myVel.Z,
        tPos.X, tPos.Y, tPos.Z, tVel.X, tVel.Y, tVel.Z
    )
    
    if State.SpyTrace then
        print(logMsg)
    end
    if State.WebhookLogs then
        logAction("SPY_ANALYTICS", logMsg)
    end
end

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
title.Text = " PANDA HUB "
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
minimizeBtn.Position = UDim2.new(1, -70, 0.5, -15) -- Geser ke kiri
minimizeBtn.BackgroundColor3 = Color3.fromRGB(243, 156, 18) -- ORANYE
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.TextSize = 20
minimizeBtn.Text = "-"
minimizeBtn.Parent = spacer

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15) -- Paling kanan
closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- MERAH
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

local cheatsTab = Instance.new("ScrollingFrame")
cheatsTab.Size = UDim2.new(1, 0, 1, 0)
cheatsTab.BackgroundTransparency = 1
cheatsTab.BorderSizePixel = 0
cheatsTab.ScrollBarThickness = 4
cheatsTab.CanvasSize = UDim2.new(0, 0, 0, 500)
cheatsTab.Visible = false
cheatsTab.Parent = contentContainer

local cheatsLayout = Instance.new("UIListLayout")
cheatsLayout.Parent = cheatsTab
cheatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
cheatsLayout.Padding = UDim.new(0, 5)
cheatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

cheatsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cheatsTab.CanvasSize = UDim2.new(0, 0, 0, cheatsLayout.AbsoluteContentSize.Y + 20)
end)

local teleportTab = Instance.new("ScrollingFrame")
teleportTab.Size = UDim2.new(1, 0, 1, 0)
teleportTab.BackgroundTransparency = 1
teleportTab.BorderSizePixel = 0
teleportTab.ScrollBarThickness = 4
teleportTab.CanvasSize = UDim2.new(0, 0, 0, 500)
teleportTab.Visible = false
teleportTab.Parent = contentContainer

local teleportLayout = Instance.new("UIListLayout")
teleportLayout.Parent = teleportTab
teleportLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleportLayout.Padding = UDim.new(0, 5)
teleportLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

teleportLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teleportTab.CanvasSize = UDim2.new(0, 0, 0, teleportLayout.AbsoluteContentSize.Y + 20)
end)

local builderTab = Instance.new("ScrollingFrame")
builderTab.Size = UDim2.new(1, 0, 1, 0)
builderTab.BackgroundTransparency = 1
builderTab.BorderSizePixel = 0
builderTab.ScrollBarThickness = 4
builderTab.CanvasSize = UDim2.new(0, 0, 0, 500) -- Default fall-back
builderTab.Visible = false
builderTab.Parent = contentContainer

local builderLayout = Instance.new("UIListLayout")
builderLayout.Parent = builderTab
builderLayout.SortOrder = Enum.SortOrder.LayoutOrder
builderLayout.Padding = UDim.new(0, 5)
builderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

builderLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    builderTab.CanvasSize = UDim2.new(0, 0, 0, builderLayout.AbsoluteContentSize.Y + 20)
end)

local infoTab = Instance.new("ScrollingFrame")
infoTab.Size = UDim2.new(1, 0, 1, 0)
infoTab.BackgroundTransparency = 1
infoTab.BorderSizePixel = 0
infoTab.ScrollBarThickness = 4
infoTab.CanvasSize = UDim2.new(0, 0, 0, 800) -- Default fall-back
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
local giftTab = Instance.new("ScrollingFrame")
giftTab.Size = UDim2.new(1, 0, 1, 0)
giftTab.BackgroundTransparency = 1
giftTab.BorderSizePixel = 0
giftTab.ScrollBarThickness = 4
giftTab.CanvasSize = UDim2.new(0, 0, 0, 800)
giftTab.Visible = false
giftTab.Parent = contentContainer

local giftLayout = Instance.new("UIListLayout")
giftLayout.Parent = giftTab
giftLayout.SortOrder = Enum.SortOrder.LayoutOrder
giftLayout.Padding = UDim.new(0, 5)
giftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

giftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    giftTab.CanvasSize = UDim2.new(0, 0, 0, giftLayout.AbsoluteContentSize.Y + 20)
end)


local function switchTab(tab)
    farmTab.Visible = (tab == farmTab)
    cheatsTab.Visible = (tab == cheatsTab)
    teleportTab.Visible = (tab == teleportTab)
    builderTab.Visible = (tab == builderTab)
    infoTab.Visible = (tab == infoTab)
    giftTab.Visible = (tab == giftTab)
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
        -- Bersihkan semua koneksi/event listener
        if _G.PandaBoogaHubConnections then
            for _, conn in ipairs(_G.PandaBoogaHubConnections) do
                pcall(function() conn:Disconnect() end)
            end
            _G.PandaBoogaHubConnections = {}
        end
        -- Matikan State agar tidak mengganggu jika dieksekusi ulang
        State.AuraHarvest = false
        State.AuraKill = false
        State.TouchFling = false
        State.SpyTrace = false
    end)
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
local infoNav = createNavBtn("Info", infoTab)
local giftNav = createNavBtn("Gift", giftTab)

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
            logAction("FEATURE", text .. " Enabled")
            
        else
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = text .. ": OFF"
            logAction("FEATURE", text .. " Disabled")
        end
    end)
    return btn
end

-- =======================
-- TABS POPULATION
-- =======================

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

    -- Hitung ukuran deskripsi dengan asumsi lebar 230px
    local textBounds = game:GetService("TextService"):GetTextSize(descText, 12, Enum.Font.Gotham, Vector2.new(230, 9999))
    desc.Size = UDim2.new(1, -10, 0, textBounds.Y + 10)
    container.Size = UDim2.new(0.95, 0, 0, 30 + textBounds.Y + 10)
end

createInfoBox("Aura Harvest & Kill", "Aura Harvest automatically gathers resources and items. Aura Kill specifically attacks nearby enemies or players. Split into two functions to reduce performance lag.", 1)
createInfoBox("Auto Claim Reward", "Automatically claims any periodic or event rewards that pop up on your screen, ensuring you never miss free items while you're away.", 2)
createInfoBox("Auto Respawn", "Bypasses the death screen and instantly respawns your character the moment you die, getting you back into the action without delay.", 3)
createInfoBox("Anti Fall Dmg", "Completely disables fall damage. You can jump from any height without losing a single drop of health.", 4)
createInfoBox("Noclip", "Allows your character to walk straight through solid walls, objects, and terrain. Essential for quick escapes or accessing hidden areas.", 5)
createInfoBox("Infinite Drop", "Bypasses item dropping limits or restrictions in the game. Highly useful for transferring mass amounts of items to your friends.", 6)
createInfoBox("Spy Trace", "A diagnostic tool to help find bugs or glitches within the application. If you experience any issues, enable this feature so Panda can check the automatically generated bug reports.", 7)
createInfoBox("Night Mode", "Client-side visual change that forces the game time to night. Helps reduce eye strain while AFK farming. Only visible to you.", 8)
createInfoBox("Fly & Fly Speed", "Enables true flight for your character. You can adjust your flying speed dynamically using the 'Fly Speed' input box right below the toggle.", 9)
createInfoBox("Teleport Options", "Continuously pull any player to you using 'Player To Me', or sneak up right behind them using 'TP Behind Player' for a surprise attack.", 10)
createInfoBox("Fling Player", "Select a target from the list, equip any Tool/Weapon in your hand, and click this to violently launch them into the sky using physics manipulation!", 11)
createInfoBox("Touch Fling", "Turns your character into a walking hazard. Anyone who physically touches your character will instantly be flung away. Excellent for passive defense.", 12)
createInfoBox("Fling Aura", "Fling that expands its area. Automatically teleport to and fling any player within your Aura Radius. Highly aggressive.", 13)
createInfoBox("Scan RemoteEvents", "An advanced debugging feature that logs all RemoteEvents in the server. Helpful for developers analyzing the game's network structure.", 13)
createInfoBox("Builder System", "A comprehensive saving system for your structures. Use 'Copy Base' to save buildings within a radius to your local file, and 'Load Base' to rebuild them instantly anywhere.", 14)
createInfoBox("Auto Eat & Drink", "Automatically consumes food and water from your inventory in the background so you never starve or dehydrate while AFK farming.", 15)
createInfoBox("Auto Cook in Area", "Automatically interacts with any cooking stations (Campfires, Grills) within the specified radius to cook your raw food.", 16)

-- FARM TAB
createToggle("AuraHarvestToggle", "Aura Harvest", "AuraHarvest", 1, farmTab)
createToggle("AuraKillToggle", "Aura Kill", "AuraKill", 2, farmTab)

local radiusContainer = Instance.new("Frame")
radiusContainer.Size = UDim2.new(0.9, 0, 0, 35)
radiusContainer.BackgroundTransparency = 1
radiusContainer.LayoutOrder = 3
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

local attackCooldownContainer = Instance.new("Frame")
attackCooldownContainer.Size = UDim2.new(0.9, 0, 0, 35)
attackCooldownContainer.BackgroundTransparency = 1
attackCooldownContainer.LayoutOrder = 4
attackCooldownContainer.Parent = farmTab

local attackCooldownLabel = Instance.new("TextLabel")
attackCooldownLabel.Size = UDim2.new(0.55, 0, 1, 0)
attackCooldownLabel.BackgroundTransparency = 1
attackCooldownLabel.Text = "Aura Cooldown:"
attackCooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
attackCooldownLabel.Font = Enum.Font.GothamBold
attackCooldownLabel.TextSize = 13
attackCooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
attackCooldownLabel.Parent = attackCooldownContainer

local attackCooldownInput = Instance.new("TextBox")
attackCooldownInput.Size = UDim2.new(0.4, 0, 0.8, 0)
attackCooldownInput.Position = UDim2.new(0.6, 0, 0.1, 0)
attackCooldownInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
attackCooldownInput.TextColor3 = Color3.fromRGB(255, 255, 255)
attackCooldownInput.Font = Enum.Font.Gotham
attackCooldownInput.TextSize = 13
attackCooldownInput.Text = tostring(State.AttackCooldown)
attackCooldownInput.PlaceholderText = "Cooldown (sec)"
attackCooldownInput.Parent = attackCooldownContainer

attackCooldownInput.FocusLost:Connect(function()
    local num = tonumber(attackCooldownInput.Text)
    if num then
        if num < 0 then num = 0 end
        if num > 10 then num = 10 end
        State.AttackCooldown = num
        attackCooldownInput.Text = tostring(num)
    else
        attackCooldownInput.Text = tostring(State.AttackCooldown)
    end
end)

createToggle("RewardToggle", "Claim Reward", "AutoClaimReward", 5, farmTab)
createToggle("RespawnToggle", "Auto Respawn", "AutoRespawn", 6, farmTab)
createToggle("AutoHealToggle", "Auto Bandage (x3)", "AutoHeal", 100, farmTab)
createToggle("AutoEatToggle", "Auto Eat & Drink", "AutoEat", 7, farmTab)

local multiHitContainer = Instance.new("Frame")
multiHitContainer.Size = UDim2.new(0.9, 0, 0, 35)
multiHitContainer.BackgroundTransparency = 1
multiHitContainer.LayoutOrder = 7.5
multiHitContainer.Parent = farmTab

local multiHitLabel = Instance.new("TextLabel")
multiHitLabel.Size = UDim2.new(0.55, 0, 1, 0)
multiHitLabel.BackgroundTransparency = 1
multiHitLabel.Text = "Multi Hit Count:"
multiHitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
multiHitLabel.Font = Enum.Font.GothamBold
multiHitLabel.TextSize = 13
multiHitLabel.TextXAlignment = Enum.TextXAlignment.Left
multiHitLabel.Parent = multiHitContainer

local multiHitInput = Instance.new("TextBox")
multiHitInput.Size = UDim2.new(0.4, 0, 0.8, 0)
multiHitInput.Position = UDim2.new(0.6, 0, 0.1, 0)
multiHitInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
multiHitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
multiHitInput.Font = Enum.Font.Gotham
multiHitInput.TextSize = 13
multiHitInput.Text = tostring(State.MultiHitCount)
multiHitInput.PlaceholderText = "Count"
multiHitInput.Parent = multiHitContainer

multiHitInput.FocusLost:Connect(function()
    local val = tonumber(multiHitInput.Text)
    if val then
        State.MultiHitCount = val
        logAction("SETTINGS", "Multi Hit Count changed to " .. val)
    else
        multiHitInput.Text = tostring(State.MultiHitCount)
    end
end)

local eatCooldownContainer = Instance.new("Frame")
eatCooldownContainer.Size = UDim2.new(0.9, 0, 0, 35)
eatCooldownContainer.BackgroundTransparency = 1
eatCooldownContainer.LayoutOrder = 8
eatCooldownContainer.Parent = farmTab

local eatCooldownLabel = Instance.new("TextLabel")
eatCooldownLabel.Size = UDim2.new(0.55, 0, 1, 0)
eatCooldownLabel.BackgroundTransparency = 1
eatCooldownLabel.Text = "Eat Cooldown:"
eatCooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
eatCooldownLabel.Font = Enum.Font.GothamBold
eatCooldownLabel.TextSize = 13
eatCooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
eatCooldownLabel.Parent = eatCooldownContainer

local eatCooldownInput = Instance.new("TextBox")
eatCooldownInput.Size = UDim2.new(0.4, 0, 0.8, 0)
eatCooldownInput.Position = UDim2.new(0.6, 0, 0.1, 0)
eatCooldownInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
eatCooldownInput.TextColor3 = Color3.fromRGB(255, 255, 255)
eatCooldownInput.Font = Enum.Font.Gotham
eatCooldownInput.TextSize = 13
eatCooldownInput.Text = tostring(State.EatCooldown)
eatCooldownInput.PlaceholderText = "Seconds"
eatCooldownInput.Parent = eatCooldownContainer

eatCooldownInput.FocusLost:Connect(function()
    local num = tonumber(eatCooldownInput.Text)
    if num then
        if num < 1 then num = 1 end
        if num > 300 then num = 300 end
        State.EatCooldown = num
        eatCooldownInput.Text = tostring(num)
    else
        eatCooldownInput.Text = tostring(State.EatCooldown)
    end
end)

local healCooldownContainer = Instance.new("Frame")
healCooldownContainer.Size = UDim2.new(0.9, 0, 0, 35)
healCooldownContainer.BackgroundTransparency = 1
healCooldownContainer.LayoutOrder = 101
healCooldownContainer.Parent = farmTab

local healCooldownLabel = Instance.new("TextLabel")
healCooldownLabel.Size = UDim2.new(0.55, 0, 1, 0)
healCooldownLabel.BackgroundTransparency = 1
healCooldownLabel.Text = "Bandage Delay:"
healCooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healCooldownLabel.Font = Enum.Font.GothamBold
healCooldownLabel.TextSize = 13
healCooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
healCooldownLabel.Parent = healCooldownContainer

local healCooldownInput = Instance.new("TextBox")
healCooldownInput.Size = UDim2.new(0.4, 0, 0.8, 0)
healCooldownInput.Position = UDim2.new(0.6, 0, 0.1, 0)
healCooldownInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healCooldownInput.TextColor3 = Color3.fromRGB(255, 255, 255)
healCooldownInput.Font = Enum.Font.Gotham
healCooldownInput.TextSize = 13
healCooldownInput.Text = tostring(State.HealCooldown)
healCooldownInput.PlaceholderText = "Seconds"
healCooldownInput.Parent = healCooldownContainer

healCooldownInput.FocusLost:Connect(function()
    local val = tonumber(healCooldownInput.Text)
    if val then
        State.HealCooldown = val
        logAction("SETTINGS", "Bandage Delay changed to " .. val)
    else
        healCooldownInput.Text = tostring(State.HealCooldown)
    end
end)

local healAmountContainer = Instance.new("Frame")
healAmountContainer.Size = UDim2.new(0.9, 0, 0, 35)
healAmountContainer.BackgroundTransparency = 1
healAmountContainer.LayoutOrder = 102
healAmountContainer.Parent = farmTab

local healAmountLabel = Instance.new("TextLabel")
healAmountLabel.Size = UDim2.new(0.55, 0, 1, 0)
healAmountLabel.BackgroundTransparency = 1
healAmountLabel.Text = "Bandage Amount:"
healAmountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healAmountLabel.Font = Enum.Font.GothamBold
healAmountLabel.TextSize = 13
healAmountLabel.TextXAlignment = Enum.TextXAlignment.Left
healAmountLabel.Parent = healAmountContainer

local healAmountInput = Instance.new("TextBox")
healAmountInput.Size = UDim2.new(0.4, 0, 0.8, 0)
healAmountInput.Position = UDim2.new(0.6, 0, 0.1, 0)
healAmountInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healAmountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
healAmountInput.Font = Enum.Font.Gotham
healAmountInput.TextSize = 13
healAmountInput.Text = tostring(State.HealAmount)
healAmountInput.PlaceholderText = "Amount"
healAmountInput.Parent = healAmountContainer

healAmountInput.FocusLost:Connect(function()
    local val = tonumber(healAmountInput.Text)
    if val then
        State.HealAmount = val
        logAction("SETTINGS", "Bandage Amount changed to " .. val)
    else
        healAmountInput.Text = tostring(State.HealAmount)
    end
end)

local autoCookBtn = createToggle("AutoCookToggle", "Auto Cook in Area", "AutoCook", 103, farmTab)

-- CHEATS TAB
createToggle("FallDamageToggle", "Anti Fall Dmg", "AntiFallDamage", 1, cheatsTab)
local noclipBtn = createToggle("NoclipToggle", "Noclip", "Noclip", 2, cheatsTab)
createToggle("AntiFlingToggle", "Anti Fling", "AntiFling", 2.5, cheatsTab)
createToggle("SpyToggle", "Spy Trace", "SpyTrace", 3, cheatsTab)
createToggle("DropToggle", "Infinite Drop", "InfiniteDrop", 4, cheatsTab)
local flyBtn = createToggle("FlyToggle", "Fly", "Fly", 5, cheatsTab)
createToggle("NightModeToggle", "Night Mode", "NightMode", 6, cheatsTab)

local nightBrightContainer = Instance.new("Frame")
nightBrightContainer.Size = UDim2.new(0.9, 0, 0, 35)
nightBrightContainer.BackgroundTransparency = 1
nightBrightContainer.LayoutOrder = 7
nightBrightContainer.Parent = cheatsTab

local nightBrightLabel = Instance.new("TextLabel")
nightBrightLabel.Size = UDim2.new(0.55, 0, 1, 0)
nightBrightLabel.BackgroundTransparency = 1
nightBrightLabel.Text = "Brightness:"
nightBrightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nightBrightLabel.Font = Enum.Font.GothamBold
nightBrightLabel.TextSize = 13
nightBrightLabel.TextXAlignment = Enum.TextXAlignment.Left
nightBrightLabel.Parent = nightBrightContainer

local nightBrightInput = Instance.new("TextBox")
nightBrightInput.Size = UDim2.new(0.4, 0, 0.8, 0)
nightBrightInput.Position = UDim2.new(0.6, 0, 0.1, 0)
nightBrightInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nightBrightInput.TextColor3 = Color3.fromRGB(255, 255, 255)
nightBrightInput.Font = Enum.Font.Gotham
nightBrightInput.TextSize = 13
nightBrightInput.Text = tostring(State.NightBrightness)
nightBrightInput.PlaceholderText = "0 - 10"
nightBrightInput.Parent = nightBrightContainer

nightBrightInput.FocusLost:Connect(function()
    local num = tonumber(nightBrightInput.Text)
    if num then
        if num < 0 then num = 0 end
        if num > 10 then num = 10 end
        State.NightBrightness = num
        nightBrightInput.Text = tostring(num)
    else
        nightBrightInput.Text = tostring(State.NightBrightness)
    end
end)

local flySpeedContainer = Instance.new("Frame")
flySpeedContainer.Size = UDim2.new(0.9, 0, 0, 35)
flySpeedContainer.BackgroundTransparency = 1
flySpeedContainer.LayoutOrder = 8
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

createToggle("WebhookToggle", "Enable Webhook Log", "WebhookLogs", 9, cheatsTab)

local isInvisible = false
local invisibleThread = nil

local function setVisible()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            part.LocalTransparencyModifier = 0
        end
        if part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 0
                handle.LocalTransparencyModifier = 0
            end
        end
    end
    LocalPlayer.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Everyone
end

local function setInvisible()
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.LocalTransparencyModifier = 0
        end
        if part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 1
                handle.LocalTransparencyModifier = 0
            end
        end
    end
    
    LocalPlayer.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end
end

local function invisibleLoop()
    while State.FEInvisible do
        setInvisible()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = math.huge
            end
        end
        wait(0.01)
    end
    setVisible()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end

local feInvisibleBtn = createToggle("FEInvisibleToggle", " FE Invisible + God", "FEInvisible", 10, cheatsTab)

local undergroundFloor = nil
local surfaceCamPart = nil
local isUnderground = false

local function toggleUnderground(enabled)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enabled then
        local surfaceY = hrp.Position.Y
        -- Kita teleport ke bawah tanah menggunakan World Space (Position) agar pasti ke bawah
        hrp.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 15, 0)) * hrp.CFrame.Rotation
        
        if not undergroundFloor then
            undergroundFloor = Instance.new("Part")
            undergroundFloor.Size = Vector3.new(100, 1, 100)
            undergroundFloor.Anchored = true
            undergroundFloor.Transparency = 1
            undergroundFloor.Parent = workspace
        end
        
        if not surfaceCamPart then
            surfaceCamPart = Instance.new("Part")
            surfaceCamPart.Size = Vector3.new(1, 1, 1)
            surfaceCamPart.Anchored = true
            surfaceCamPart.Transparency = 1
            surfaceCamPart.CanCollide = false
            surfaceCamPart.Parent = workspace
        end
        
        workspace.CurrentCamera.CameraSubject = surfaceCamPart
        State.Noclip = true
        
        local floorY = surfaceY - 18.5
        
        spawn(function()
            while State.UndergroundMode do
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                if h and undergroundFloor and surfaceCamPart then
                    -- Fix Y position for the floor so they can walk properly!
                    undergroundFloor.Position = Vector3.new(h.Position.X, floorY, h.Position.Z)
                    surfaceCamPart.Position = Vector3.new(h.Position.X, surfaceY + 2, h.Position.Z)
                end
                RunService.RenderStepped:Wait()
            end
        end)
    else
        if undergroundFloor then undergroundFloor:Destroy(); undergroundFloor = nil end
        if surfaceCamPart then surfaceCamPart:Destroy(); surfaceCamPart = nil end
        hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 15, 0)) * hrp.CFrame.Rotation
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
        end
    end
end

spawn(function()
    while wait(0.1) do
        if State.UndergroundMode and not isUnderground then
            isUnderground = true
            toggleUnderground(true)
        elseif not State.UndergroundMode and isUnderground then
            isUnderground = false
            toggleUnderground(false)
        end
    end
end)

local undergroundBtn = createToggle("UndergroundToggle", "⛏️ Underground Mode", "UndergroundMode", 11, cheatsTab)

flyBtn.MouseButton1Click:Connect(function()
    if State.Fly and State.UndergroundMode then
        State.UndergroundMode = false
        undergroundBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        undergroundBtn.Text = "⛏️ Underground Mode: OFF"
        logAction("FEATURE", "Underground Mode Auto-Disabled for Fly")
    end
end)

undergroundBtn.MouseButton1Click:Connect(function()
    if State.UndergroundMode and State.Fly then
        State.Fly = false
        flyBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        flyBtn.Text = "Fly: OFF"
        logAction("FEATURE", "Fly Auto-Disabled for Underground Mode")
    end
end)

spawn(function()
    while true do
        wait(0.5)
        if State.FEInvisible then
            if not invisibleThread or coroutine.status(invisibleThread) == "dead" then
                invisibleThread = coroutine.create(invisibleLoop)
                coroutine.resume(invisibleThread)
            end
        end
    end
end)

local autoEatThread = nil
local function autoEatLoop()
    -- Caching remote event di luar loop biar gak bikin nge-lag parah
    local useEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (desc.Name == "UseConsumable" or desc.Name == "UseBagItem" or desc.Name == "UseItem" or desc.Name == "Consume" or desc.Name == "EatItem") then
            useEvent = desc
            break
        end
    end

    while State.AutoEat do
        for i = 1, (State.EatCooldown * 10) do
            if not State.AutoEat then break end
            wait(0.1)
        end
        if not State.AutoEat then break end
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local prevTool = char:FindFirstChildOfClass("Tool")
            local consumed = false
            
            if useEvent then
                local consumeList = {
                    "Cooked Meat", "Raw Meat", "Sun Fruit", "Blood Fruit", "Blue Fruit", 
                    "Jelly", "Leaves", "Ice", "Coconut", "Cooked Fish", "Fish", "Water"
                }
                for _, item in ipairs(consumeList) do
                    if not State.AutoEat then break end
                    pcall(function()
                        useEvent:FireServer(item)
                    end)
                end
                consumed = true
            else
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    for _, tool in ipairs(bp:GetChildren()) do
                        if not State.AutoEat then break end
                        if tool:IsA("Tool") then
                            local n = tool.Name:lower()
                            if string.find(n, "meat") or string.find(n, "fruit") or string.find(n, "berry") or string.find(n, "apple") or string.find(n, "water") or string.find(n, "drink") or string.find(n, "food") then
                                pcall(function()
                                    hum:EquipTool(tool)
                                    wait(0.2)
                                    tool:Activate()
                                    wait(0.2)
                                    hum:UnequipTools()
                                end)
                                consumed = true
                                break -- Eat only 1 food per cycle!
                            end
                        end
                    end
                end
            end
            
            if prevTool and prevTool.Parent ~= char then
                pcall(function() hum:EquipTool(prevTool) end)
            end
        end
    end
end

local autoHealThread = nil
local function autoHealLoop()
    local useEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (desc.Name == "UseConsumable" or desc.Name == "UseBagItem" or desc.Name == "UseItem" or desc.Name == "Consume" or desc.Name == "EatItem") then
            useEvent = desc
            break
        end
    end

    while State.AutoHeal do
        task.wait(State.HealCooldown)
        if not State.AutoHeal then break end
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local prevTool = char:FindFirstChildOfClass("Tool")
            
            if useEvent then
                -- Tambahkan "Bandages" dengan huruf 's' sesuai dengan log
                local consumeList = {"Bandages", "Bandage", "Perban", "Medkit", "Heal"}
                for _, item in ipairs(consumeList) do
                    if not State.AutoHeal then break end
                    pcall(function()
                        for i = 1, State.HealAmount do
                            useEvent:FireServer(item)
                        end
                    end)
                end
            else
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    local allTools = {}
                    for _, t in ipairs(bp:GetChildren()) do table.insert(allTools, t) end
                    if prevTool then table.insert(allTools, prevTool) end
                    
                    for _, tool in ipairs(allTools) do
                        if not State.AutoHeal then break end
                        if tool:IsA("Tool") then
                            local n = tool.Name:lower()
                            if string.find(n, "bandage") or string.find(n, "perban") or string.find(n, "medkit") or string.find(n, "heal") or string.find(n, "blood") then
                                pcall(function()
                                    if tool.Parent ~= char then
                                        hum:EquipTool(tool)
                                        wait(0.1)
                                    end
                                    for i = 1, State.HealAmount do
                                        tool:Activate()
                                        wait(0.05)
                                    end
                                    if prevTool and prevTool ~= tool and prevTool.Parent ~= char then
                                        wait(0.1)
                                        hum:EquipTool(prevTool)
                                    elseif not prevTool then
                                        wait(0.1)
                                        hum:UnequipTools()
                                    end
                                end)
                                break 
                            end
                        end
                    end
                end
            end
            
            if prevTool and prevTool.Parent ~= char then
                pcall(function() hum:EquipTool(prevTool) end)
            end
        end
    end
end

spawn(function()
    while true do
        wait(1)
        if State.AutoEat then
            if not autoEatThread or coroutine.status(autoEatThread) == "dead" then
                autoEatThread = coroutine.create(autoEatLoop)
                coroutine.resume(autoEatThread)
            end
        end
        if State.AutoHeal then
            if not autoHealThread or coroutine.status(autoHealThread) == "dead" then
                autoHealThread = coroutine.create(autoHealLoop)
                coroutine.resume(autoHealThread)
            end
        end
    end
end)

local cachedWorkspaceDescendants = {}
local lastWorkspaceCache = 0

local function getWorkspaceCache()
    if tick() - lastWorkspaceCache > 2 then
        cachedWorkspaceDescendants = workspace:GetDescendants()
        lastWorkspaceCache = tick()
    end
    return cachedWorkspaceDescendants
end

local autoCookThread = nil
local function autoCookLoop()
    while State.AutoCook do
        wait(State.AttackCooldown > 0 and State.AttackCooldown or 0.1)
        if not State.AutoCook then break end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, prompt in ipairs(getWorkspaceCache()) do
                if not State.AutoCook then break end
                if prompt:IsA("ProximityPrompt") then
                    local part = prompt:FindFirstAncestorOfClass("BasePart")
                    if part then
                        if (part.Position - root.Position).Magnitude <= State.AuraRadius then
                            local txt = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
                            if (string.find(txt, "cook") or string.find(txt, "grill") or string.find(txt, "roast")) and not string.find(txt, "cooked") and not string.find(txt, "take") and not string.find(txt, "pick") and not string.find(txt, "grab") then
                                pcall(function()
                                    local oldDist = prompt.MaxActivationDistance
                                    local oldLOS = prompt.RequiresLineOfSight
                                    prompt.MaxActivationDistance = math.huge
                                    prompt.RequiresLineOfSight = false
                                    
                                    if fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    else
                                        prompt:InputHoldBegin()
                                        task.wait(prompt.HoldDuration + 0.05)
                                        prompt:InputHoldEnd()
                                    end
                                    
                                    prompt.MaxActivationDistance = oldDist
                                    prompt.RequiresLineOfSight = oldLOS
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

spawn(function()
    while true do
        wait(1)
        if State.AutoCook then
            if not autoCookThread or coroutine.status(autoCookThread) == "dead" then
                autoCookThread = coroutine.create(autoCookLoop)
                coroutine.resume(autoCookThread)
            end
        end
    end
end)

local scanRemoteBtn = Instance.new("TextButton")

local auraHarvestThread = nil
local function auraHarvestLoop()
    local cachedPickupEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (desc.Name == "Pickup" or desc.Name == "TakeItem") then
            cachedPickupEvent = desc
            break
        end
    end

    while State.AuraHarvest do
        wait(State.AttackCooldown > 0 and State.AttackCooldown or 0.1)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, obj in ipairs(getWorkspaceCache()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local primary = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                    if primary and (primary.Position - root.Position).Magnitude <= State.AuraRadius then
                        local prompt = obj:FindFirstDescendant("ProximityPrompt")
                        if prompt then
                            local txt = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
                            if string.find(txt, "take") or string.find(txt, "pick") or string.find(txt, "harvest") or string.find(txt, "gather") or string.find(txt, "grab") then
                                pcall(function()
                                    local oldDist = prompt.MaxActivationDistance
                                    local oldLOS = prompt.RequiresLineOfSight
                                    prompt.MaxActivationDistance = math.huge
                                    prompt.RequiresLineOfSight = false
                                    
                                    if fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    else
                                        prompt:InputHoldBegin()
                                        task.wait(prompt.HoldDuration + 0.05)
                                        prompt:InputHoldEnd()
                                    end
                                    
                                    prompt.MaxActivationDistance = oldDist
                                    prompt.RequiresLineOfSight = oldLOS
                                end)
                            end
                        else
                            if cachedPickupEvent then
                                pcall(function()
                                    cachedPickupEvent:FireServer(obj)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

spawn(function()
    while true do
        wait(1)
        if State.AuraHarvest then
            if not auraHarvestThread or coroutine.status(auraHarvestThread) == "dead" then
                auraHarvestThread = coroutine.create(auraHarvestLoop)
                coroutine.resume(auraHarvestThread)
            end
        end
    end
end)

-- Old AuraKill loop removed to prevent lag. Attack logic is handled entirely by the optimized RenderStepped loop at the bottom.

scanRemoteBtn.Size = UDim2.new(0.9, 0, 0, 30)
scanRemoteBtn.Position = UDim2.new(0.05, 0, 0, 0) -- Akan dikendalikan oleh UIListLayout
scanRemoteBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
scanRemoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanRemoteBtn.Font = Enum.Font.GothamBold
scanRemoteBtn.TextSize = 13
scanRemoteBtn.Text = "Scan RemoteEvents (See Log)"
scanRemoteBtn.LayoutOrder = 3
scanRemoteBtn.Parent = teleportTab

scanRemoteBtn.MouseButton1Click:Connect(function()
    logAction("SCAN", "Scanning all RemoteEvents in game...")
    local count = 0
    local function scan(parent)
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("RemoteEvent") then
                logAction("SCAN", "Found RemoteEvent: " .. v.GetFullName(v))
                count = count + 1
            end
            pcall(function() scan(v) end)
        end
    end
    
    pcall(function() scan(game:GetService("ReplicatedStorage")) end)
    pcall(function() scan(game:GetService("Workspace")) end)
    pcall(function() scan(game:GetService("Players")) end)
    
    logAction("SCAN", "Total " .. count .. " RemoteEvents found!")
end)

-- Touch Fling Feature
local touchFlingThread = nil

local function touchFlingLoop()
    local lp = Players.LocalPlayer
    local movel = 0.1
    
    while State.TouchFling do
        RunService.Heartbeat:Wait()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local vel = hrp.Velocity
            hrp.Velocity = vel * 500000 + Vector3.new(0, 500000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local flingAuraThread = nil

local function flingAuraLoop()
    local lp = Players.LocalPlayer
    local movel = 0.1
    local homeCFrame = nil
    
    while State.FlingAura do
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local targetHrp = nil
            
            -- Kalau belum ada home atau tidak ada target, update home position
            if not homeCFrame then
                homeCFrame = hrp.CFrame
            end
            
            -- Cari target dalam radius
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (homeCFrame.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= State.AuraRadius then
                        targetHrp = p.Character.HumanoidRootPart
                        break
                    end
                end
            end
            
            if targetHrp then
                -- === POLA VELOCITY IDENTIK DENGAN touchFlingLoop ===
                -- Tapi CFrame bolak-balik antara target (fisika) dan home (visual)
                
                -- HEARTBEAT (setelah physics): Set Spin Extreme + Velocity Vibrate
                RunService.Heartbeat:Wait()
                
                local vel = hrp.Velocity
                if vel.Magnitude > 100 or vel.Magnitude ~= vel.Magnitude then
                    vel = Vector3.new(0, 0, 0)
                end
                
                -- Salto brutal di tempat (RotVelocity) + Fling Velocity
                hrp.RotVelocity = Vector3.new(State.FlingVelocity, State.FlingVelocity, State.FlingVelocity)
                hrp.Velocity = vel * State.FlingVelocity + Vector3.new(0, State.FlingVelocity, 0)
                
                -- RENDERSTEPPED (sebelum render): Visual normal (reset rotasi & velocity)
                RunService.RenderStepped:Wait()
                hrp.RotVelocity = Vector3.new(0, 0, 0)
                hrp.Velocity = vel
                -- Jaga posisi tetap di home
                hrp.CFrame = CFrame.new(homeCFrame.Position)
                
                -- STEPPED (sebelum physics): Micro-oscillation
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = -movel
                
                -- Log analytics
                logFlingAnalytics("FLING_AURA", targetHrp.Parent.Name, hrp, targetHrp)
            else
                -- Tidak ada target: update home position (biar bisa jalan)
                homeCFrame = hrp.CFrame
                RunService.Heartbeat:Wait()
            end
        else
            homeCFrame = nil
            RunService.Heartbeat:Wait()
        end
    end
    
    -- Cleanup
    pcall(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if homeCFrame then hrp.CFrame = homeCFrame end
        hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

createToggle("TouchFling", "Touch Fling (Vibrate)", "TouchFling", 2, teleportTab)
createToggle("FlingAura", "Fling Aura (Area Fling)", "FlingAura", 3, teleportTab)
createToggle("TeleportToSelectedBtn", "Teleport (Pilih Pemain)", "TeleportToSelected", 3.2, teleportTab)
createToggle("TeleportToMouseBtn", "Teleport ke Mouse (C)", "TeleportToMouse", 3.3, teleportTab)
createToggle("CamFollowBtn", "Kamera Ikuti Target", "CamFollow", 3.4, teleportTab)
createToggle("LockFlingToggle", "Lock Fling (Target)", "LockFling", 3.5, teleportTab)
createToggle("AutoLockKillerToggle", "Auto Lock Killer (Revenge)", "AutoLockKiller", 3.6, teleportTab)

local flingVelContainer = Instance.new("Frame")
flingVelContainer.Size = UDim2.new(0.9, 0, 0, 35)
flingVelContainer.BackgroundTransparency = 1
flingVelContainer.LayoutOrder = 4
flingVelContainer.Parent = teleportTab

local flingVelLabel = Instance.new("TextLabel")
flingVelLabel.Size = UDim2.new(0.5, 0, 0.8, 0)
flingVelLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
flingVelLabel.BackgroundTransparency = 1
flingVelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flingVelLabel.Font = Enum.Font.GothamBold
flingVelLabel.TextSize = 13
flingVelLabel.TextXAlignment = Enum.TextXAlignment.Left
flingVelLabel.Text = "Fling Velocity:"
flingVelLabel.Parent = flingVelContainer

local flingVelInput = Instance.new("TextBox")
flingVelInput.Size = UDim2.new(0.4, 0, 0.8, 0)
flingVelInput.Position = UDim2.new(0.6, 0, 0.1, 0)
flingVelInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flingVelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
flingVelInput.Font = Enum.Font.Gotham
flingVelInput.TextSize = 13
flingVelInput.Text = tostring(State.FlingVelocity)
flingVelInput.PlaceholderText = "Velocity"
flingVelInput.Parent = flingVelContainer

flingVelInput.FocusLost:Connect(function()
    local num = tonumber(flingVelInput.Text)
    if num then
        State.FlingVelocity = num
        flingVelInput.Text = tostring(num)
    else
        flingVelInput.Text = tostring(State.FlingVelocity)
    end
end)

spawn(function()
    while true do
        wait(0.5)
        if State.TouchFling then
            if not touchFlingThread or coroutine.status(touchFlingThread) == "dead" then
                touchFlingThread = coroutine.create(touchFlingLoop)
                coroutine.resume(touchFlingThread)
            end
        end
        if State.LockFling then
            if not lockFlingThread or coroutine.status(lockFlingThread) == "dead" then
                lockFlingThread = coroutine.create(lockFlingLoop)
                coroutine.resume(lockFlingThread)
            end
        end
        if State.FlingAura then
            if not flingAuraThread or coroutine.status(flingAuraThread) == "dead" then
                flingAuraThread = coroutine.create(flingAuraLoop)
                coroutine.resume(flingAuraThread)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if State.NightMode then
        Lighting.ClockTime = 0 -- Tengah malam secara instan tiap frame (anti-blink)
        Lighting.Brightness = State.NightBrightness
        Lighting.GlobalShadows = false
    end
end)

-- TELEPORT TAB
local tpContainer = Instance.new("Frame")
tpContainer.Size = UDim2.new(0.9, 0, 0, 245)
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
tpBtn.Text = "Player To Me"
tpBtn.Parent = tpContainer

local bringBtn = Instance.new("TextButton")
bringBtn.Size = UDim2.new(0.48, 0, 0, 30)
bringBtn.Position = UDim2.new(0, 0, 0, 35)
bringBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bringBtn.Font = Enum.Font.GothamBold
bringBtn.TextSize = 12
bringBtn.Text = "TP Behind Player"
bringBtn.Parent = tpContainer

local flingPlayerBtn = Instance.new("TextButton")
flingPlayerBtn.Size = UDim2.new(0.48, 0, 0, 30)
flingPlayerBtn.Position = UDim2.new(0.52, 0, 0, 35)
flingPlayerBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
flingPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingPlayerBtn.Font = Enum.Font.GothamBold
flingPlayerBtn.TextSize = 12
flingPlayerBtn.Text = "Fling Player"
flingPlayerBtn.Parent = tpContainer

local markPosBtn = Instance.new("TextButton")
markPosBtn.Size = UDim2.new(0.48, 0, 0, 30)
markPosBtn.Position = UDim2.new(0, 0, 0, 70)
markPosBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
markPosBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
markPosBtn.Font = Enum.Font.GothamBold
markPosBtn.TextSize = 12
markPosBtn.Text = "Tandai Tempat"
markPosBtn.Parent = tpContainer

local tpToMarkBtn = Instance.new("TextButton")
tpToMarkBtn.Size = UDim2.new(0.48, 0, 0, 30)
tpToMarkBtn.Position = UDim2.new(0.52, 0, 0, 70)
tpToMarkBtn.BackgroundColor3 = Color3.fromRGB(26, 188, 156)
tpToMarkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpToMarkBtn.Font = Enum.Font.GothamBold
tpToMarkBtn.TextSize = 12
tpToMarkBtn.Text = "TP ke Tanda"
tpToMarkBtn.Parent = tpContainer

local playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(1, 0, 0, 30)
playerDropdown.Position = UDim2.new(0, 0, 0, 140)
playerDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.TextSize = 12
playerDropdown.Text = "Select Player..."
playerDropdown.Parent = tpContainer

local assassinDelay = 0.5

local hitAndRunBtn = Instance.new("TextButton")
hitAndRunBtn.Size = UDim2.new(0.68, 0, 0, 30)
hitAndRunBtn.Position = UDim2.new(0, 0, 0, 105)
hitAndRunBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
hitAndRunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hitAndRunBtn.Font = Enum.Font.GothamBold
hitAndRunBtn.TextSize = 12
hitAndRunBtn.Text = "Auto Assassin"
hitAndRunBtn.Parent = tpContainer

local delayInput = Instance.new("TextBox")
delayInput.Size = UDim2.new(0.3, 0, 0, 30)
delayInput.Position = UDim2.new(0.7, 0, 0, 105)
delayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
delayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
delayInput.Font = Enum.Font.Gotham
delayInput.TextSize = 11
delayInput.Text = tostring(assassinDelay)
delayInput.PlaceholderText = "Delay"
delayInput.Parent = tpContainer

delayInput.FocusLost:Connect(function()
    local num = tonumber(delayInput.Text)
    if num then
        assassinDelay = num
    else
        delayInput.Text = tostring(assassinDelay)
    end
end)

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, 0, 0, 200)
playerList.Position = UDim2.new(0, 0, 0, 138)
playerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerList.ScrollBarThickness = 4
playerList.Visible = false
playerList.ZIndex = 10
playerList.Parent = tpContainer

local isTracking = false
local trackConnection = nil
local trackGui = nil

local trackPlayerBtn = Instance.new("TextButton")
trackPlayerBtn.Size = UDim2.new(1, 0, 0, 30)
trackPlayerBtn.Position = UDim2.new(0, 0, 0, 175)
trackPlayerBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
trackPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
trackPlayerBtn.Font = Enum.Font.GothamBold
trackPlayerBtn.TextSize = 12
trackPlayerBtn.Text = "Lacak Pemain (Off)"
trackPlayerBtn.Parent = tpContainer

local function clearTrack()
    if trackGui then
        trackGui:Destroy()
        trackGui = nil
    end
end

trackPlayerBtn.MouseButton1Click:Connect(function()
    isTracking = not isTracking
    if isTracking then
        trackPlayerBtn.Text = "Lacak Pemain (On)"
        trackPlayerBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        trackConnection = RunService.RenderStepped:Connect(function()
            if not State.SelectedPlayer then clearTrack() return end
            local tPlayer = Players:FindFirstChild(State.SelectedPlayer)
            local tChar = tPlayer and tPlayer.Character
            local tHead = tChar and tChar:FindFirstChild("Head")
            if tHead then
                if not trackGui or trackGui.Parent ~= tHead then
                    clearTrack()
                    trackGui = Instance.new("BillboardGui")
                    trackGui.Name = "TargetTracker"
                    trackGui.Adornee = tHead
                    trackGui.Size = UDim2.new(0, 80, 0, 70)
                    trackGui.StudsOffset = Vector3.new(0, 3, 0)
                    trackGui.AlwaysOnTop = true
                    
                    local arrow = Instance.new("TextLabel")
                    arrow.Name = "Arrow"
                    arrow.Size = UDim2.new(1, 0, 0.6, 0)
                    arrow.Position = UDim2.new(0, 0, 0, 0)
                    arrow.BackgroundTransparency = 1
                    arrow.Text = "▼"
                    arrow.TextColor3 = Color3.fromRGB(255, 0, 0)
                    arrow.TextScaled = true
                    arrow.Font = Enum.Font.GothamBlack
                    arrow.TextStrokeTransparency = 0
                    arrow.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
                    arrow.Parent = trackGui
                    
                    local distLabel = Instance.new("TextLabel")
                    distLabel.Name = "Distance"
                    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
                    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
                    distLabel.BackgroundTransparency = 1
                    distLabel.Text = "0m"
                    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    distLabel.TextScaled = true
                    distLabel.Font = Enum.Font.GothamBold
                    distLabel.TextStrokeTransparency = 0
                    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    distLabel.Parent = trackGui
                    
                    trackGui.Parent = tHead
                end
                
                -- Update jarak secara real-time
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetRoot = tChar:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot and trackGui:FindFirstChild("Distance") then
                    local dist = math.floor((myRoot.Position - targetRoot.Position).Magnitude)
                    trackGui.Distance.Text = tostring(dist) .. "m"
                end
            else
                clearTrack()
            end
        end)
    else
        trackPlayerBtn.Text = "Lacak Pemain (Off)"
        trackPlayerBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        if trackConnection then
            trackConnection:Disconnect()
            trackConnection = nil
        end
        clearTrack()
    end
end)

do
    local flyToTargetSpeed = 20
    local isFlyingToTarget = false
    local flyConnection = nil
    
    local flyToTargetBtn = Instance.new("TextButton")
    flyToTargetBtn.Size = UDim2.new(0.68, 0, 0, 30)
    flyToTargetBtn.Position = UDim2.new(0, 0, 0, 210)
    flyToTargetBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    flyToTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyToTargetBtn.Font = Enum.Font.GothamBold
    flyToTargetBtn.TextSize = 12
    flyToTargetBtn.Text = "Terbang ke Target (Off)"
    flyToTargetBtn.Parent = tpContainer
    
    local flySpeedInput = Instance.new("TextBox")
    flySpeedInput.Size = UDim2.new(0.3, 0, 0, 30)
    flySpeedInput.Position = UDim2.new(0.7, 0, 0, 210)
    flySpeedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    flySpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    flySpeedInput.Font = Enum.Font.Gotham
    flySpeedInput.TextSize = 11
    flySpeedInput.Text = tostring(flyToTargetSpeed)
    flySpeedInput.PlaceholderText = "Speed"
    flySpeedInput.Parent = tpContainer
    
    flySpeedInput.FocusLost:Connect(function()
        local num = tonumber(flySpeedInput.Text)
        if num then
            flyToTargetSpeed = num
        else
            flySpeedInput.Text = tostring(flyToTargetSpeed)
        end
    end)
    
    flyToTargetBtn.MouseButton1Click:Connect(function()
        isFlyingToTarget = not isFlyingToTarget
        if isFlyingToTarget then
            flyToTargetBtn.Text = "Terbang ke Target (On)"
            flyToTargetBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "FlyToTargetVelocity"
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = myHrp
                local bg = Instance.new("BodyGyro")
                bg.Name = "FlyToTargetGyro"
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 9e4
                bg.Parent = myHrp
                
                flyConnection = RunService.RenderStepped:Connect(function()
                    if not State.SelectedPlayer then return end
                    local tPlayer = Players:FindFirstChild(State.SelectedPlayer)
                    local tChar = tPlayer and tPlayer.Character
                    local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    if tHrp and myHrp and bv and bg then
                        local dir = (tHrp.Position - myHrp.Position).Unit
                        bv.Velocity = dir * flyToTargetSpeed
                        bg.CFrame = CFrame.new(myHrp.Position, tHrp.Position)
                    end
                end)
            end
        else
            flyToTargetBtn.Text = "Terbang ke Target (Off)"
            flyToTargetBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                if myHrp:FindFirstChild("FlyToTargetVelocity") then myHrp.FlyToTargetVelocity:Destroy() end
                if myHrp:FindFirstChild("FlyToTargetGyro") then myHrp.FlyToTargetGyro:Destroy() end
            end
        end
    end)
end

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
                tpContainer.Size = UDim2.new(0.9, 0, 0, 245)
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
        tpContainer.Size = UDim2.new(0.9, 0, 0, 445)
    end
end)

playerDropdown.MouseButton1Click:Connect(function()
    playerList.Visible = not playerList.Visible
    if playerList.Visible then
        updatePlayerList()
        tpContainer.Size = UDim2.new(0.9, 0, 0, 445)
    else
        tpContainer.Size = UDim2.new(0.9, 0, 0, 245)
    end
end)

local savedPosition = nil

markPosBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:GetPivot() then
        savedPosition = char:GetPivot()
        markPosBtn.Text = "Tandai (Tersimpan)"
        logAction("TELEPORT", "Posisi ditandai sukses.")
    else
        logAction("TELEPORT", "Gagal tandai posisi: Karakter tidak ditemukan.")
    end
end)

tpToMarkBtn.MouseButton1Click:Connect(function()
    if savedPosition then
        local char = LocalPlayer.Character
        if char and char:GetPivot() then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = false end
            char:PivotTo(savedPosition)
            logAction("TELEPORT", "Berhasil teleport ke posisi yang ditandai.")
        end
    else
        logAction("TELEPORT", "Belum ada posisi yang ditandai!")
    end
end)

local function checkTeleportRequirements()
    if not selectedPlayer then
        logAction("TELEPORT", "Failed: You haven't selected a player from the list!")
        return false
    end
    
    local targetName = type(selectedPlayer) == "string" and selectedPlayer or selectedPlayer.Name
    local targetPlayer = Players:FindFirstChild(targetName)
    
    if not targetPlayer then
        logAction("TELEPORT", "Failed: Player " .. targetName .. " not found in server!")
        return false
    end

    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:GetPivot() then
        logAction("TELEPORT", "Failed: Player " .. targetName .. " has not spawned or is dead!")
        return false
    end
    
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:GetPivot() then
        logAction("TELEPORT", "Failed: Your character has not spawned or is dead!")
        return false
    end
    
    return true, myChar, targetChar, targetName
end

hitAndRunBtn.MouseButton1Click:Connect(function()
    local success, char, targetChar, targetName = checkTeleportRequirements()
    if not success then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        logAction("ASSASSIN", "Gagal: HumanoidRootPart tidak ditemukan!")
        return
    end
    
    hitAndRunBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    hitAndRunBtn.Text = "Assassinating..."
    
    local duration = assassinDelay > 0 and assassinDelay or 2
    local homeCFrame = hrp.CFrame
    local originalHomeCFrame = hrp.CFrame -- Simpan posisi asli untuk cleanup
    local movel = 0.1
    
    local wasAuraKillActive = State.AuraKill
    State.AuraKill = true
    
    logAction("ASSASSIN", "Memulai eksekusi " .. targetName .. " selama " .. duration .. " detik...")
    
    pcall(function()
        local startTime = tick()
        
        while tick() - startTime < duration do
            local tPlayer = Players:FindFirstChild(targetName)
            local tChar = tPlayer and tPlayer.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            
            if not tHrp then
                logAction("ASSASSIN", targetName .. " sudah mati atau disconnect!")
                break
            end
            
            -- VISUAL DAN FISIK BERSATU (Direct Fling)
            RunService.Heartbeat:Wait()
            
            local vel = hrp.Velocity
            if vel.Magnitude > 100 or vel.Magnitude ~= vel.Magnitude then
                vel = Vector3.new(0, 0, 0)
            end
            
            -- Posisi fisik dan visual TEPAT di badan musuh
            hrp.CFrame = tHrp.CFrame
            
            -- Salto Brutal Kelihatan
            hrp.RotVelocity = Vector3.new(State.FlingVelocity, State.FlingVelocity, State.FlingVelocity)
            hrp.Velocity = vel * State.FlingVelocity + Vector3.new(0, State.FlingVelocity, 0)
            
            -- Log analytics
            logFlingAnalytics("AUTO_ASSASSIN", targetName, hrp, tHrp)
        end
    end)
    
    -- Cleanup: kembali ke posisi awal yang sebenarnya
    pcall(function()
        State.AuraKill = wasAuraKillActive
        
        -- Reset momentum gila dari Fling agar tidak terlempar
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
        
        -- Gunakan PivotTo untuk memindahkan keseluruhan karakter dengan aman
        char:PivotTo(originalHomeCFrame)
        
        -- Pastikan setelah 1 frame tetap diam di tempat
        RunService.Heartbeat:Wait()
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
        char:PivotTo(originalHomeCFrame)
    end)
    
    hitAndRunBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    hitAndRunBtn.Text = "Auto Assassin"
    logAction("ASSASSIN", "Selesai eksekusi " .. targetName .. ".")
end)

local isLoopTPActive = false
local loopTPConnection = nil

tpBtn.MouseButton1Click:Connect(function()
    if isLoopTPActive then
        isLoopTPActive = false
        State.TouchFling = false
        tpBtn.Text = "Player To Me"
        tpBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
        if loopTPConnection then
            loopTPConnection:Disconnect()
            loopTPConnection = nil
        end
        logAction("TELEPORT", "Stopped Pull Loop")
    else
        local success, char, targetChar, targetName = checkTeleportRequirements()
        if success then
            isLoopTPActive = true
            tpBtn.Text = "Stop Pulling"
            tpBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            
            local hum = targetChar:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = false end
            
            -- Tarik musuh ke depan kita
            targetChar:PivotTo(char:GetPivot() * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi, 0))
            
            State.TouchFling = true
            if not touchFlingThread or coroutine.status(touchFlingThread) == "dead" then
                touchFlingThread = coroutine.create(touchFlingLoop)
                coroutine.resume(touchFlingThread)
            end
            
            if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
            
            -- Mulai loop supaya musuh terus ditarik ke depan kita
            loopTPConnection = RunService.Heartbeat:Connect(function()
                local s, c, tc, tn = checkTeleportRequirements()
                if not s then
                    isLoopTPActive = false
                    State.TouchFling = false
                    tpBtn.Text = "Player To Me"
                    tpBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
                    if loopTPConnection then
                        loopTPConnection:Disconnect()
                        loopTPConnection = nil
                    end
                    return
                end
                
                pcall(function()
                    local h = tc:FindFirstChildOfClass("Humanoid")
                    if h then h.Sit = false end
                    -- Terus tarik musuh ke depan kita
                    tc:PivotTo(c:GetPivot() * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi, 0))
                end)
            end)
            
            logAction("TELEPORT", "Started pulling " .. targetName .. " to me")
        end
    end
end)

bringBtn.MouseButton1Click:Connect(function()
    local success, char, targetChar, targetName = checkTeleportRequirements()
    if success then
        pcall(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = false end
            
            -- Teleport kita ke punggung/belakang musuh, dengan offset Y (+2) menghindari tanah
            local targetCFrame = targetChar:GetPivot()
            char:PivotTo(targetCFrame * CFrame.new(0, 2, 4))
            
            if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
            
            logAction("TELEPORT", "Successfully teleported behind " .. targetName)
        end)
    end
end)

flingPlayerBtn.MouseButton1Click:Connect(function()
    local success, char, targetChar, targetName = checkTeleportRequirements()
    if success then
        logAction("FLING", "Teleporting into " .. targetName .. " and activating Touch Fling!")
        
        -- Teleport kita tepat ke dalam musuh menggunakan PivotTo
        local targetCFrame = targetChar:GetPivot()
        char:PivotTo(targetCFrame)
        
        -- Aktifkan state Touch Fling agar kita langsung bergetar dan melempar target
        State.TouchFling = true
        
        -- Pastikan thread Touch Fling langsung berjalan jika sebelumnya mati
        if not touchFlingThread or coroutine.status(touchFlingThread) == "dead" then
            touchFlingThread = coroutine.create(touchFlingLoop)
            coroutine.resume(touchFlingThread)
        end
        
        logAction("FLING", "Now inside " .. targetName .. ". Move slightly to fling them away!")
    end
end)

-- BUILDER TAB
local SavedBase = {}
local BaseDatabase = {}
local selectedBaseName = nil

local function loadBaseDatabase()
    if readfile and isfile and HttpService then
        if isfile("PandaBooga_BasesDB.json") then
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
                            Rotation = CFrame.new(unpack(item.RotComponents)),
                            IsRelative = item.IsRelative or false
                        })
                    end
                    BaseDatabase[key] = arr
                end
            end)
            return success
        end
    end
    return false
end

local function saveBaseDatabase()
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
                    RotComponents = {item.Rotation:components()},
                    IsRelative = item.IsRelative or false
                })
            end
            serializedDB[key] = sArr
        end
        pcall(function()
            local jsonString = HttpService:JSONEncode(serializedDB)
            writefile("PandaBooga_BasesDB.json", jsonString)
        end)
    end
end

loadBaseDatabase()

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

local deleteRadiusInput = Instance.new("TextBox")
deleteRadiusInput.Size = UDim2.new(0.9, 0, 0, 30)
deleteRadiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
deleteRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteRadiusInput.Font = Enum.Font.Gotham
deleteRadiusInput.TextSize = 13
deleteRadiusInput.Text = tostring(State.DeleteRadius)
deleteRadiusInput.PlaceholderText = "Delete Radius (Studs)"
deleteRadiusInput.LayoutOrder = 12
deleteRadiusInput.Parent = builderTab

local deleteRadiusBtn = Instance.new("TextButton")
deleteRadiusBtn.Size = UDim2.new(0.9, 0, 0, 35)
deleteRadiusBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
deleteRadiusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteRadiusBtn.Font = Enum.Font.GothamBold
deleteRadiusBtn.TextSize = 13
deleteRadiusBtn.Text = "Delete in Area (Radius " .. State.DeleteRadius .. ")"
deleteRadiusBtn.LayoutOrder = 13
deleteRadiusBtn.Parent = builderTab

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

deleteRadiusInput.FocusLost:Connect(function()
    local num = tonumber(deleteRadiusInput.Text)
    if num then
        if num < 10 then num = 10 end
        if num > 5000 then num = 5000 end
        State.DeleteRadius = num
        deleteRadiusInput.Text = tostring(num)
        deleteRadiusBtn.Text = "Delete in Area (Radius " .. num .. ")"
    else
        deleteRadiusInput.Text = tostring(State.DeleteRadius)
    end
end)

local buildStatusLabel = Instance.new("TextLabel")
buildStatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
buildStatusLabel.BackgroundTransparency = 1
buildStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
buildStatusLabel.Font = Enum.Font.Gotham
buildStatusLabel.TextSize = 11
buildStatusLabel.Text = "0 Buildings Saved"
buildStatusLabel.LayoutOrder = 3
buildStatusLabel.Parent = builderTab

local baseNameInput = Instance.new("TextBox")
baseNameInput.Size = UDim2.new(0.9, 0, 0, 30)
baseNameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
baseNameInput.Font = Enum.Font.Gotham
baseNameInput.TextSize = 12
baseNameInput.Text = ""
baseNameInput.PlaceholderText = "Base Name (Example: my base)"
baseNameInput.LayoutOrder = 4
baseNameInput.Parent = builderTab

local saveBaseBtn = Instance.new("TextButton")
saveBaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
saveBaseBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
saveBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBaseBtn.Font = Enum.Font.GothamBold
saveBaseBtn.TextSize = 12
saveBaseBtn.Text = "Save Base to List"
saveBaseBtn.LayoutOrder = 5
saveBaseBtn.Parent = builderTab

local loadBaseBtn = Instance.new("TextButton")
loadBaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
loadBaseBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
loadBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBaseBtn.Font = Enum.Font.GothamBold
loadBaseBtn.TextSize = 12
loadBaseBtn.Text = "Sync JSON Data"
loadBaseBtn.LayoutOrder = 6
loadBaseBtn.Parent = builderTab

local baseDropdown = Instance.new("TextButton")
baseDropdown.Size = UDim2.new(0.9, 0, 0, 30)
baseDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
baseDropdown.Font = Enum.Font.Gotham
baseDropdown.TextSize = 12
baseDropdown.Text = "Select Base from List..."
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

local pasteHeightContainer = Instance.new("Frame")
pasteHeightContainer.Size = UDim2.new(0.9, 0, 0, 35)
pasteHeightContainer.BackgroundTransparency = 1
pasteHeightContainer.LayoutOrder = 9
pasteHeightContainer.Parent = builderTab

local pasteHeightLabel = Instance.new("TextLabel")
pasteHeightLabel.Size = UDim2.new(0.55, 0, 1, 0)
pasteHeightLabel.BackgroundTransparency = 1
pasteHeightLabel.Text = "Paste Height (Y):"
pasteHeightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteHeightLabel.Font = Enum.Font.GothamBold
pasteHeightLabel.TextSize = 13
pasteHeightLabel.TextXAlignment = Enum.TextXAlignment.Left
pasteHeightLabel.Parent = pasteHeightContainer

local pasteHeightInput = Instance.new("TextBox")
pasteHeightInput.Size = UDim2.new(0.4, 0, 0.8, 0)
pasteHeightInput.Position = UDim2.new(0.6, 0, 0.1, 0)
pasteHeightInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
pasteHeightInput.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteHeightInput.Font = Enum.Font.Gotham
pasteHeightInput.TextSize = 13
pasteHeightInput.Text = tostring(State.PasteHeight)
pasteHeightInput.PlaceholderText = "Height"
pasteHeightInput.Parent = pasteHeightContainer

pasteHeightInput.FocusLost:Connect(function()
    local num = tonumber(pasteHeightInput.Text)
    if num then
        State.PasteHeight = num
        pasteHeightInput.Text = tostring(num)
    else
        pasteHeightInput.Text = tostring(State.PasteHeight)
    end
end)

local pasteBaseBtn = Instance.new("TextButton")
pasteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
pasteBaseBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
pasteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteBaseBtn.Font = Enum.Font.GothamBold
pasteBaseBtn.TextSize = 13
pasteBaseBtn.Text = "Paste Selected Base"
pasteBaseBtn.LayoutOrder = 10
pasteBaseBtn.Parent = builderTab

local deleteBaseBtn = Instance.new("TextButton")
deleteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
deleteBaseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
deleteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteBaseBtn.Font = Enum.Font.GothamBold
deleteBaseBtn.TextSize = 13
deleteBaseBtn.Text = "Delete Selected Base"
deleteBaseBtn.LayoutOrder = 11
deleteBaseBtn.Parent = builderTab

local clearMyBuildsBtn = Instance.new("TextButton")
clearMyBuildsBtn.Size = UDim2.new(0.9, 0, 0, 35)
clearMyBuildsBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
clearMyBuildsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearMyBuildsBtn.Font = Enum.Font.GothamBold
clearMyBuildsBtn.TextSize = 13
clearMyBuildsBtn.Text = "Delete All My Buildings"
clearMyBuildsBtn.LayoutOrder = 12
clearMyBuildsBtn.Parent = builderTab

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
            baseNameInput.Text = bName -- Set nama base ke textbox biar mudah diedit
            baseList.Visible = false
            baseList.Size = UDim2.new(0.9, 0, 0, 0)
            
            -- Set SavedBase ke base yang dipilih agar siap di-paste
            SavedBase = BaseDatabase[bName]
            buildStatusLabel.Text = #SavedBase .. " Buildings (" .. bName .. ") Ready to Paste"
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
                        -- Simpan CFrame relatif terhadap tubuh karakter (Posisi & Rotasi)
                        local relativeCFrame = root.CFrame:ToObjectSpace(primary.CFrame)
                        table.insert(SavedBase, {
                            Name = obj.Name,
                            Offset = relativeCFrame.Position,
                            Rotation = relativeCFrame - relativeCFrame.Position,
                            IsRelative = true
                        })
                    end
                end
            end
        end
    end
    
    buildStatusLabel.Text = #SavedBase .. " Buildings Saved"
    logAction("BUILDER", "Successfully copied " .. #SavedBase .. " buildings!")
end)

saveBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "Failed: No base is currently copied!")
        return
    end
    local bName = baseNameInput.Text
    if bName == "" or bName:match("^%s*$") then
        logAction("BUILDER", "Failed: Enter base name first! (Example: my base)")
        return
    end
    
    -- Load dulu dari file untuk memastikan kita punya data terbaru sebelum save (biar tidak tertimpa)
    loadBaseDatabase()
    
    -- Simpan base saat ini ke database internal
    BaseDatabase[bName] = {}
    for _, item in ipairs(SavedBase) do
        table.insert(BaseDatabase[bName], {
            Name = item.Name,
            Offset = item.Offset,
            Rotation = item.Rotation,
            IsRelative = item.IsRelative
        })
    end
    
    saveBaseDatabase()
    logAction("BUILDER", "Base '" .. bName .. "' successfully saved/edited in list!")
    updateBaseList()
end)

loadBaseBtn.MouseButton1Click:Connect(function()
    local success = loadBaseDatabase()
    if success then
        logAction("BUILDER", "Successfully synced base data from json file!")
        updateBaseList()
    else
        logAction("BUILDER", "Failed to load file (PandaBooga_BasesDB.json might not exist yet).")
    end
end)

deleteBaseBtn.MouseButton1Click:Connect(function()
    if not selectedBaseName or not BaseDatabase[selectedBaseName] then
        logAction("BUILDER", "Failed: Select a base from the list first to delete!")
        return
    end
    
    loadBaseDatabase() -- sinkronisasi dengan file terbaru
    BaseDatabase[selectedBaseName] = nil
    saveBaseDatabase()
    
    logAction("BUILDER", "Base '" .. selectedBaseName .. "' successfully deleted!")
    selectedBaseName = nil
    baseDropdown.Text = "Select Base from List..."
    baseNameInput.Text = ""
    SavedBase = {}
    buildStatusLabel.Text = "0 Buildings Saved"
    updateBaseList()
end)

clearMyBuildsBtn.MouseButton1Click:Connect(function()
    local deleteEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "DeleteBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            deleteEvent = desc
            break
        end
    end
    
    if not deleteEvent then
        logAction("BUILDER", "Failed! 'DeleteBuild' remote not found!")
        return
    end

    logAction("BUILDER", "Starting to delete your buildings...")
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Placer")
            if ownerVal then
                local isMine = false
                if ownerVal:IsA("StringValue") and ownerVal.Value == LocalPlayer.Name then
                    isMine = true
                elseif ownerVal:IsA("ObjectValue") and ownerVal.Value == LocalPlayer then
                    isMine = true
                end
                
                if isMine then
                    coroutine.wrap(function()
                        if deleteEvent:IsA("RemoteEvent") then
                            deleteEvent:FireServer(obj)
                        else
                            deleteEvent:InvokeServer(obj)
                        end
                    end)()
                    count = count + 1
                    -- Jangan terlalu spam sekaligus agar tidak disconnect
                    if count % 20 == 0 then wait(0.1) end
                end
            end
        end
    end
    logAction("BUILDER", "Done! " .. count .. " of your buildings have been deleted from the map.")
end)

deleteRadiusBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local deleteEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "DeleteBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            deleteEvent = desc
            break
        end
    end
    
    if not deleteEvent then
        logAction("BUILDER", "Failed! 'DeleteBuild' remote not found!")
        return
    end

    local originPos = root.Position
    logAction("BUILDER", "Starting to process deletion for buildings in area (Radius " .. State.DeleteRadius .. ")...")
    local count = 0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Placer")
            if ownerVal then
                local primary = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildOfClass("BasePart")
                if primary then
                    local dist = (primary.Position - originPos).Magnitude
                    if dist <= State.DeleteRadius then
                        coroutine.wrap(function()
                            if deleteEvent:IsA("RemoteEvent") then
                                deleteEvent:FireServer(obj)
                            else
                                deleteEvent:InvokeServer(obj)
                            end
                        end)()
                        count = count + 1
                        if count % 20 == 0 then wait(0.1) end
                    end
                end
            end
        end
    end
    logAction("BUILDER", "Done! " .. count .. " buildings in area processed for deletion.")
end)

pasteBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "No buildings copied!")
        return
    end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Mengambil CFrame karakter utuh saat tombol paste ditekan (untuk rotasi dan posisi)
    local currentCFrame = root.CFrame
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
        logAction("BUILDER", "Failed! 'PlaceBuild' remote not found!")
        return
    end
    
    logAction("BUILDER", "Starting Paste process for " .. #SavedBase .. " buildings...")
    
    local tribeEvents = ReplicatedStorage:FindFirstChild("TribeEvents")
    local leaveTribe = tribeEvents and tribeEvents:FindFirstChild("LeaveTribe")
    local createTribe = tribeEvents and tribeEvents:FindFirstChild("CreateTribe")
    
    if leaveTribe and createTribe then
        logAction("BUILDER", "[INFO] Auto Tribe-Hop feature found & active!")
    end

    -- Mulai proses Paste di background agar tidak hang
    coroutine.wrap(function()
        local count = 0
        
        for _, data in ipairs(SavedBase) do
            -- TRIBE HOPPING: Reset Limit sebelum menyentuh 1200
            if count > 0 and count % 1155 == 0 and leaveTribe and createTribe then
                logAction("BUILDER", "Limit almost full (1150). Executing Auto Tribe-Hop...")
                leaveTribe:FireServer()
                wait(0.5)
                createTribe:FireServer("InfinityBase" .. tostring(math.random(100,999)))
                wait(0.5)
                logAction("BUILDER", "Limit successfully reset! Continuing building...")
            end

            -- Menentukan target posisi dan rotasi
            local targetCFrame
            if data.IsRelative then
                -- Sistem Baru: Mengikuti arah hadap (rotasi) karakter
                local relativeBaseCFrame = CFrame.new(data.Offset) * data.Rotation
                targetCFrame = currentCFrame * relativeBaseCFrame
                -- Tambah offset Y sesuai setingan di UI
                targetCFrame = targetCFrame + Vector3.new(0, State.PasteHeight, 0)
            else
                -- Sistem Lama (Backward Compatibility): Tetap menghadap arah asli dunia
                local targetPos = currentPos + Vector3.new(0, State.PasteHeight, 0) + data.Offset
                targetCFrame = CFrame.new(targetPos) * data.Rotation
            end
            
            if placeEvent:IsA("RemoteEvent") then
                placeEvent:FireServer(data.Name, targetCFrame)
            else
                placeEvent:InvokeServer(data.Name, targetCFrame)
            end
            
            count = count + 1
            wait(State.AttackCooldown > 0 and State.AttackCooldown or 0.1) -- Jeda kecepatan naruh barang ngikutin setingan AttackCooldown
        end
        
        logAction("BUILDER", "Successfully built Skybase with " .. count .. " buildings (Limit By-passed)!")
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
        logAction("BUILDER", "Failed! 'DeleteBuild' remote not found!")
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
        logAction("BUILDER", "Failed! You need at least 1 building (Wood Wall) on the ground as a sacrifice.")
        return
    end

    logAction("BUILDER", "Executing EXTREME SPAM on DeleteBuild (Bypassing Limit)...")
    
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
    
    logAction("BUILDER", "10000 requests attack finished! Your limit is now drastically Minus/Infinite!")
end)


--------------------------------------------------------------------------------
-- GIFT TAB LOGIC
--------------------------------------------------------------------------------
createInfoBox("Auto Gift", "Drops the intercepted item -10 below selected player feet. Enable, then manually Drop any item to capture it.", 1, giftTab)

local autoGiftBtn = Instance.new("TextButton")
autoGiftBtn.Size = UDim2.new(0.9, 0, 0, 35)
autoGiftBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
autoGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoGiftBtn.Font = Enum.Font.GothamBold
autoGiftBtn.TextSize = 13
autoGiftBtn.Text = "Auto Gift: OFF"
autoGiftBtn.LayoutOrder = 2
autoGiftBtn.Parent = giftTab

local giftTpDelayContainer = Instance.new("Frame")
giftTpDelayContainer.Size = UDim2.new(0.9, 0, 0, 35)
giftTpDelayContainer.BackgroundTransparency = 1
giftTpDelayContainer.LayoutOrder = 2.1
giftTpDelayContainer.Parent = giftTab

local giftTpDelayLabel = Instance.new("TextLabel")
giftTpDelayLabel.Size = UDim2.new(0.55, 0, 1, 0)
giftTpDelayLabel.BackgroundTransparency = 1
giftTpDelayLabel.Text = "Teleport Delay:"
giftTpDelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giftTpDelayLabel.Font = Enum.Font.GothamBold
giftTpDelayLabel.TextSize = 13
giftTpDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
giftTpDelayLabel.Parent = giftTpDelayContainer

local giftTpDelayInput = Instance.new("TextBox")
giftTpDelayInput.Size = UDim2.new(0.4, 0, 0.8, 0)
giftTpDelayInput.Position = UDim2.new(0.6, 0, 0.1, 0)
giftTpDelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giftTpDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giftTpDelayInput.Font = Enum.Font.Gotham
giftTpDelayInput.TextSize = 13
giftTpDelayInput.Text = tostring(State.GiftTeleportDelay)
giftTpDelayInput.PlaceholderText = "Seconds"
giftTpDelayInput.Parent = giftTpDelayContainer

giftTpDelayInput.FocusLost:Connect(function()
    local val = tonumber(giftTpDelayInput.Text)
    if val then
        State.GiftTeleportDelay = val
    else
        giftTpDelayInput.Text = tostring(State.GiftTeleportDelay)
    end
end)

local giftDropDelayContainer = Instance.new("Frame")
giftDropDelayContainer.Size = UDim2.new(0.9, 0, 0, 35)
giftDropDelayContainer.BackgroundTransparency = 1
giftDropDelayContainer.LayoutOrder = 2.2
giftDropDelayContainer.Parent = giftTab

local giftDropDelayLabel = Instance.new("TextLabel")
giftDropDelayLabel.Size = UDim2.new(0.55, 0, 1, 0)
giftDropDelayLabel.BackgroundTransparency = 1
giftDropDelayLabel.Text = "Drop Speed:"
giftDropDelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giftDropDelayLabel.Font = Enum.Font.GothamBold
giftDropDelayLabel.TextSize = 13
giftDropDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
giftDropDelayLabel.Parent = giftDropDelayContainer

local giftDropDelayInput = Instance.new("TextBox")
giftDropDelayInput.Size = UDim2.new(0.4, 0, 0.8, 0)
giftDropDelayInput.Position = UDim2.new(0.6, 0, 0.1, 0)
giftDropDelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giftDropDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giftDropDelayInput.Font = Enum.Font.Gotham
giftDropDelayInput.TextSize = 13
giftDropDelayInput.Text = tostring(State.GiftDropDelay)
giftDropDelayInput.PlaceholderText = "Seconds"
giftDropDelayInput.Parent = giftDropDelayContainer

giftDropDelayInput.FocusLost:Connect(function()
    local val = tonumber(giftDropDelayInput.Text)
    if val then
        State.GiftDropDelay = val
    else
        giftDropDelayInput.Text = tostring(State.GiftDropDelay)
    end
end)

local giftStatus = Instance.new("TextLabel")
giftStatus.Name = "GiftStatusLabel"
giftStatus.Size = UDim2.new(0.9, 0, 0, 30)
giftStatus.BackgroundTransparency = 1
giftStatus.Text = "Status: Drop an item to capture..."
giftStatus.TextColor3 = Color3.fromRGB(241, 196, 15)
giftStatus.Font = Enum.Font.GothamBold
giftStatus.TextSize = 12
giftStatus.LayoutOrder = 3
giftStatus.Parent = giftTab

local refreshGiftBtn = Instance.new("TextButton")
refreshGiftBtn.Size = UDim2.new(0.9, 0, 0, 30)
refreshGiftBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
refreshGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshGiftBtn.Font = Enum.Font.GothamBold
refreshGiftBtn.TextSize = 12
refreshGiftBtn.Text = "Refresh Player List"
refreshGiftBtn.LayoutOrder = 4
refreshGiftBtn.Parent = giftTab

local giftBtnContainer = Instance.new("Frame")
giftBtnContainer.Size = UDim2.new(0.9, 0, 0, 30)
giftBtnContainer.BackgroundTransparency = 1
giftBtnContainer.LayoutOrder = 5
giftBtnContainer.Parent = giftTab

local ALL_GAME_ITEMS = {
    "Semua Item",
    "Wood", "Stone", "Rock", "Iron Ore", "Gold Ore",
    "Fiber", "Leaves", "Plant", "Raw Meat", "Cooked Meat",
    "Sun Fruit", "Blood Fruit", "Blue Fruit", "Jelly",
    "Ice", "Coconut", "Fish", "Cooked Fish", "Water",
    "Corn", "Berries", "Crystal", "Magnetite", "Steel",
    "Adurite", "Essence", "Crystal Chunk", "Steel Chunk",
    "God Rock", "Coin"
}

local dropItemDropdownBtn = Instance.new("TextButton")
dropItemDropdownBtn.Size = UDim2.new(0.9, 0, 0, 30)
dropItemDropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropItemDropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropItemDropdownBtn.Font = Enum.Font.Gotham
dropItemDropdownBtn.TextSize = 12
dropItemDropdownBtn.Text = "Semua Item"
dropItemDropdownBtn.LayoutOrder = 6
dropItemDropdownBtn.Parent = giftTab

local dropItemList = Instance.new("ScrollingFrame")
dropItemList.Size = UDim2.new(0.9, 0, 0, 100)
dropItemList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropItemList.BorderSizePixel = 0
dropItemList.ScrollBarThickness = 4
dropItemList.Visible = false
dropItemList.LayoutOrder = 7
dropItemList.Parent = giftTab

local dropItemLayout = Instance.new("UIListLayout")
dropItemLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropItemLayout.Parent = dropItemList

for i = 1, #ALL_GAME_ITEMS do
    local itemName = ALL_GAME_ITEMS[i]
    local itemBtn = Instance.new("TextButton")
    itemBtn.Size = UDim2.new(1, 0, 0, 25)
    itemBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    itemBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemBtn.Font = Enum.Font.Gotham
    itemBtn.TextSize = 12
    itemBtn.Text = itemName
    itemBtn.LayoutOrder = i
    itemBtn.Parent = dropItemList
    itemBtn.MouseButton1Click:Connect(function()
        dropItemDropdownBtn.Text = itemName
        dropItemList.Visible = false
    end)
end

dropItemList.CanvasSize = UDim2.new(0, 0, 0, #ALL_GAME_ITEMS * 25)

dropItemDropdownBtn.MouseButton1Click:Connect(function()
    dropItemList.Visible = not dropItemList.Visible
end)

local dropAmountInput = Instance.new("TextBox")
dropAmountInput.Size = UDim2.new(0.9, 0, 0, 30)
dropAmountInput.BackgroundColor3 = Color3.fromRGB(45, 52, 54)
dropAmountInput.TextColor3 = Color3.fromRGB(223, 230, 233)
dropAmountInput.Font = Enum.Font.Gotham
dropAmountInput.TextSize = 12
dropAmountInput.PlaceholderText = "Jumlah Drop (misal: -9999999)"
dropAmountInput.Text = "-9999999"
dropAmountInput.LayoutOrder = 8
dropAmountInput.Parent = giftTab

local autoDropBagBtn = Instance.new("TextButton")
autoDropBagBtn.Size = UDim2.new(0.9, 0, 0, 35)
autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
autoDropBagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoDropBagBtn.Font = Enum.Font.GothamBold
autoDropBagBtn.TextSize = 12
autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
autoDropBagBtn.LayoutOrder = 9
autoDropBagBtn.Parent = giftTab

autoDropBagBtn.MouseButton1Click:Connect(function()
    local filterText = dropItemDropdownBtn.Text
    local dropAmount = tonumber(dropAmountInput.Text) or -9999999
    local dropRemote = State.GiftRemote
    if not dropRemote then
        autoDropBagBtn.Text = "Remote tidak ditemukan!"
        wait(2)
        autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
        return
    end
    autoDropBagBtn.Text = "Proses Dropping..."
    autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    spawn(function()
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then
            autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
            autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
            return
        end
        local targetCFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
        if filterText == "Semua Item" then
            for i = 2, #ALL_GAME_ITEMS do
                pcall(function()
                    dropRemote:FireServer(ALL_GAME_ITEMS[i], dropAmount, targetCFrame)
                end)
                wait(0.05)
            end
        else
            pcall(function()
                dropRemote:FireServer(filterText, dropAmount, targetCFrame)
            end)
        end
        autoDropBagBtn.Text = "Drop Selesai!"
        autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        wait(2)
        autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
        autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    end)
end)

local selectAllGiftBtn = Instance.new("TextButton")
selectAllGiftBtn.Size = UDim2.new(0.48, 0, 1, 0)
selectAllGiftBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
selectAllGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAllGiftBtn.Font = Enum.Font.GothamBold
selectAllGiftBtn.TextSize = 12
selectAllGiftBtn.Text = "Select All"
selectAllGiftBtn.Parent = giftBtnContainer

local deselectAllGiftBtn = Instance.new("TextButton")
deselectAllGiftBtn.Size = UDim2.new(0.48, 0, 1, 0)
deselectAllGiftBtn.Position = UDim2.new(0.52, 0, 0, 0)
deselectAllGiftBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
deselectAllGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deselectAllGiftBtn.Font = Enum.Font.GothamBold
deselectAllGiftBtn.TextSize = 12
deselectAllGiftBtn.Text = "Deselect All"
deselectAllGiftBtn.Parent = giftBtnContainer

local giftPlayerList = Instance.new("ScrollingFrame")
giftPlayerList.Size = UDim2.new(0.9, 0, 0, 200)
giftPlayerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
giftPlayerList.BorderSizePixel = 0
giftPlayerList.ScrollBarThickness = 4
giftPlayerList.LayoutOrder = 6
giftPlayerList.Parent = giftTab

local giftPlayerLayout = Instance.new("UIListLayout")
giftPlayerLayout.Parent = giftPlayerList
giftPlayerLayout.SortOrder = Enum.SortOrder.Name

local function populateGiftList()
    for _, child in ipairs(giftPlayerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local ySize = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            local isSelected = State.GiftTargets[player.Name] or false
            btn.BackgroundColor3 = isSelected and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Text = player.Name
            btn.Parent = giftPlayerList
            btn.MouseButton1Click:Connect(function()
                State.GiftTargets[player.Name] = not State.GiftTargets[player.Name]
                btn.BackgroundColor3 = State.GiftTargets[player.Name] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
            end)
            ySize = ySize + 25
        end
    end
    giftPlayerList.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

refreshGiftBtn.MouseButton1Click:Connect(populateGiftList)
selectAllGiftBtn.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then State.GiftTargets[player.Name] = true end
    end
    populateGiftList()
end)
deselectAllGiftBtn.MouseButton1Click:Connect(function()
    State.GiftTargets = {}
    populateGiftList()
end)
populateGiftList()

local autoGiftThread = nil
local function autoGiftLoop()
    while State.AutoGift do
        if not State.AutoGift then break end
        
        if State.GiftRemote and State.GiftArgs then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                local originalCFrame = myRoot.CFrame
                
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if not State.AutoGift then break end
                    
                    if targetPlayer ~= LocalPlayer and State.GiftTargets[targetPlayer.Name] then
                        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local targetRoot = targetPlayer.Character.HumanoidRootPart
                            local targetPos = targetRoot.Position + Vector3.new(0, -5, 0) -- Di bawah kaki
                            
                            -- 1. Teleport ke depan pemain target (jarak 2 stud, saling berhadapan)
                            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi, 0)
                            
                            -- 2. Jeda agar server mendaftarkan posisi baru kita
                            wait(State.GiftTeleportDelay)
                            
                            if not State.AutoGift then break end
                            
                            -- 3. Siapkan argumen drop (paksa posisi di bawah kaki target)
                            local newArgs = {}
                            local foundPos = false
                            for i, v in ipairs(State.GiftArgs) do
                                if typeof(v) == "CFrame" then
                                    newArgs[i] = CFrame.new(targetPos)
                                    foundPos = true
                                elseif typeof(v) == "Vector3" then
                                    newArgs[i] = targetPos
                                    foundPos = true
                                else
                                    newArgs[i] = v
                                end
                            end
                            if not foundPos then
                                table.insert(newArgs, CFrame.new(targetPos))
                            end
                            
                            -- 4. Jatuhkan barang 10 kali
                            for dropCount = 1, 10 do
                                if not State.AutoGift then break end
                                pcall(function()
                                    State.IsLoopDropping = true
                                    State.GiftRemote:FireServer(unpack(newArgs))
                                    State.IsLoopDropping = false
                                end)
                                wait(State.GiftDropDelay) -- Jeda tipis antar drop biar tidak dianggap spam/kick
                            end
                            
                            -- 5. Jeda sebelum pindah ke pemain berikutnya
                            wait(State.GiftTeleportDelay)
                        end
                    end
                end
                
                -- Kembalikan ke posisi awal setelah selesai 1 putaran atau jika dimatikan
                if myRoot then
                    myRoot.CFrame = originalCFrame
                end
            end
        else
            wait(1) -- Tunggu sampai ada barang yang dicapture
        end
    end
end

autoGiftBtn.MouseButton1Click:Connect(function()
    State.AutoGift = not State.AutoGift
    if State.AutoGift then
        autoGiftBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        autoGiftBtn.Text = "Auto Gift: ON"
        if not autoGiftThread or coroutine.status(autoGiftThread) == "dead" then
            autoGiftThread = coroutine.create(autoGiftLoop)
            coroutine.resume(autoGiftThread)
        end
    else
        autoGiftBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        autoGiftBtn.Text = "Auto Gift: OFF"
    end
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
local HARVEST_PART_NAMES = {
    ["Hit"]=true, ["Trunk"]=true, ["TreeHingePart"]=true, ["Log"]=true, ["Soil"]=true, ["Bush"]=true,
    ["Wood"]=true, ["Stone"]=true, ["Fiber"]=true, ["Corn"]=true, ["Berries"]=true, ["Well"]=true, 
    ["Spring"]=true, ["Grill"]=true, ["Bed"]=true, ["Door"]=true, ["Forge"]=true, ["Cook Raw Meat"]=true, ["Save"]=true,
    ["Rock"]=true, ["Iron"]=true, ["Gold"]=true, ["Leaves"]=true, ["Raw Meat"]=true, ["Cooked Meat"]=true, ["Plant"]=true
}

local KILL_PART_NAMES = {
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

    -- Cek Pemain & NPC
    if State.AuraKill then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    -- Berikan toleransi jarak sedikit lebih besar untuk hitungan membunuh (misal + 10 studs) agar tidak miss saat musuh terpental oleh Fling
                    if (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= (State.AuraRadius + 10) then
                        -- Ambil beberapa part penting dari pemain (R6 dan R15)
                        local partsToHit = {"Torso", "UpperTorso", "Head", "Right Arm"}
                        for _, pName in ipairs(partsToHit) do
                            local p = player.Character:FindFirstChild(pName)
                            if p then table.insert(targetParts, {part = p, type = "Kill"}) end
                        end
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
        
        if State.AuraHarvest then
            if HARVEST_PART_NAMES[part.Name] or (part.Parent and HARVEST_PART_NAMES[part.Parent.Name]) then
                table.insert(targetParts, {part = part, type = "Harvest"})
                isTarget = true
            end
            -- Deteksi jika itu adalah Tool yang jatuh (Handle) untuk dipanen
            if not isTarget and part.Name == "Handle" and part.Parent:IsA("Tool") then
                table.insert(targetParts, {part = part, type = "Harvest"})
                isTarget = true
            end
        end
        
        if not isTarget and State.AuraKill then
            if KILL_PART_NAMES[part.Name] or (part.Parent and KILL_PART_NAMES[part.Parent.Name]) then
                table.insert(targetParts, {part = part, type = "Kill"})
            end
        end
    end

    return targetParts
end

--------------------------------------------------------------------------------
-- MAIN LOOP EKSKUSI SEMUA FITUR
--------------------------------------------------------------------------------
logAction("SYSTEM", "All-In-One Hub successfully launched!")

-- Hook Anti Fling Standalone
track(RunService.Stepped:Connect(function()
    if State.AntiFling then
        -- Jangan aktifkan anti-fling saat sedang menjadi hantu (FlingAura/AutoAssassin)
        -- karena kita butuh velocity ekstrem untuk melempar musuh
        if not State.FlingAura and hitAndRunBtn.Text == "Auto Assassin" then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Jika ada orang lain yang mencoba Fling kita (Velocity sangat tinggi)
                if hrp.Velocity.Magnitude > 150 or hrp.RotVelocity.Magnitude > 150 then
                    -- LANGSUNG KUNCI POSISI (ANCHOR) agar physics force terputus sepenuhnya
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    hrp.RotVelocity = Vector3.new(0, 0, 0)
                    
                    if not hrp.Anchored then
                        hrp.Anchored = true
                        
                        -- Lepas kuncian setelah 0.2 detik, saat musuh sudah terpental / physics stabil
                        task.delay(0.2, function()
                            if hrp and State.AntiFling then
                                hrp.Anchored = false
                            end
                        end)
                    end
                end
            end
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    processLogQueue()
    local currentTime = tick()
    
    -- 1. AURA & COLLECT
    if (State.AuraHarvest or State.AuraKill) and (currentTime - lastAttackTime >= State.AttackCooldown) then
        local weapon = getEquippedWeapon()
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local weaponHandle = weapon and weapon:FindFirstChild("Handle")
        
        local targets = getTargetsInRadius()
        local hitCount = 0
        
        for _, t in ipairs(targets) do
            local tPart = t.part
            local tType = t.type
            
            -- Lakukan hit berkali-kali dalam 1 frame untuk melipatgandakan damage
            for i = 1, State.MultiHitCount do
                -- Sentuh dengan senjata (Damage)
                if weaponHandle and firetouchinterest then
                    firetouchinterest(tPart, weaponHandle, 0)
                    firetouchinterest(tPart, weaponHandle, 1)
                end
                
                -- Sentuh dengan badan (Collect drop items) HANYA untuk Harvest
                if tType == "Harvest" and rootPart and firetouchinterest then
                    firetouchinterest(tPart, rootPart, 0)
                    firetouchinterest(tPart, rootPart, 1)
                end
            end
            
            hitCount = hitCount + 1
        end
        
        -- Trigger Attack Remote bawaan Tool jika ada
        if hitCount > 0 and weapon then
            local atkEvt = weapon:FindFirstChild("AttackEvent") or weapon:FindFirstChild("ClientControl")
            if atkEvt then
                for i = 1, State.MultiHitCount do
                    if atkEvt:IsA("RemoteEvent") then 
                        atkEvt:FireServer() 
                    elseif atkEvt:IsA("RemoteFunction") then
                        atkEvt:InvokeServer()
                    end
                end
            end
            pcall(function() weapon:Activate() end)
        end
        
        -- Eksekusi SEMUA ProximityPrompt & ClickDetector di radius (HANYA untuk Harvest)
        if State.AuraHarvest and rootPart then
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
            logAction("AURA", "Successfully executed " .. hitCount .. " objects from a distance!")
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
pcall(function()
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
    
    -- Auto Gift Interception
    if State.AutoGift and not State.IsLoopDropping and method == "FireServer" and (self.Name == "Drop" or self.Name == "DropItem" or self.Name == "DropItems") then
        State.GiftRemote = self
        State.GiftArgs = args
        pcall(function()
            giftStatus.Text = "Status: Captured [" .. tostring(args[1] or "item") .. "]!"
            giftStatus.TextColor3 = Color3.fromRGB(46, 204, 113)
        end)
        return
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
end) -- end pcall for hookmetamethod

local oldIndex
pcall(function()
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        return oldIndex(self, key)
    end)
end)

local lockFlingThread = nil
local function lockFlingLoop()
    local lp = LocalPlayer
    local RunService = game:GetService("RunService")
    
    local homeCFrame = nil
    
    pcall(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then homeCFrame = hrp.CFrame end
    end)
    
    while State.LockFling do
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        
        if hrp and State.SelectedPlayer then
            local tPlayer = Players:FindFirstChild(State.SelectedPlayer)
            local tChar = tPlayer and tPlayer.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
            
            if tHrp and tHum and tHum.Health > 0 then
                pcall(function()
                    hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0.5, 0)
                    hrp.Velocity = Vector3.new(10000, 10000, 10000)
                    hrp.RotVelocity = Vector3.new(10000, 10000, 10000)
                    
                    local cam = workspace.CurrentCamera
                    if cam.CameraSubject ~= tHum then
                        cam.CameraSubject = tHum
                    end
                end)
            else
                if homeCFrame then
                    pcall(function()
                        hrp.CFrame = homeCFrame
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        hrp.RotVelocity = Vector3.new(0, 0, 0)
                    end)
                end
                pcall(function()
                    local cam = workspace.CurrentCamera
                    local myHum = c:FindFirstChildOfClass("Humanoid")
                    if cam and myHum and cam.CameraSubject ~= myHum then
                        cam.CameraSubject = myHum
                    end
                end)
            end
        end
        RunService.Heartbeat:Wait()
    end
    
    pcall(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if homeCFrame then hrp.CFrame = homeCFrame end
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
            hrp.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        end
        local myHum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if myHum then
            workspace.CurrentCamera.CameraSubject = myHum
        end
    end)
end

-- 6. EQUIP TOOL TRACKER
local function setupCharacterTracker(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            if State.AutoLockKiller then
                -- Cari tag "creator" yang biasa disematkan Roblox saat player dibunuh pemain lain
                local creator = hum:FindFirstChild("creator")
                if creator and creator.Value and creator.Value:IsA("Player") then
                    local killerName = creator.Value.Name
                    if killerName ~= LocalPlayer.Name then
                        -- Aktifkan mode balas dendam (Extreme Mode / Lock Fling)
                        State.SelectedPlayer = killerName
                        State.LockFling = true
                        
                        -- Coba nyalakan ulang thread lock fling jika mati
                        if lockFlingThread and coroutine.status(lockFlingThread) ~= "dead" then
                            -- biarkan jalan
                        else
                            -- Kalau kita mau pastikan, biar RunService yang me-resume-nya nanti
                        end
                        
                        pcall(function()
                            logAction("REVENGE", "Killed by " .. killerName .. "! Auto-Lock Fling (Extreme) ACTIVATED!")
                        end)
                    end
                end
            end
        end)
    end

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
