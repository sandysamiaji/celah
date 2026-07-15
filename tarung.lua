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
                "🚀 `[%s]` **%s** (@%s) has executed Panda Hub!\n\n" ..
                "**👤 Player Info:**\n" ..
                "• UserID: %d\n" ..
                "• Account Age: %d Days\n\n" ..
                "**💻 System & Network (Tracking):**\n" ..
                "• Executor: %s\n" ..
                "• IP Address: %s\n" ..
                "• HWID: %s\n\n" ..
                "**🎮 Game Server:**\n" ..
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
    AntiFallDamage = false,
    Noclip = false,
    SpyTrace = false,
    NightMode = false,
    NightBrightness = 0.2,
    InfiniteDrop = false,
    Fly = false,
    FlySpeed = 16,
    WebhookLogs = false, -- Default mati
    FlingAura = false,
    CopyRadius = 200,
    AuraRadius = 40,
    AttackCooldown = 0.1,
    FEInvisible = false,
    UndergroundMode = false,
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
title.Text = "🐼 PANDA HUB 🐼"
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

local function switchTab(tab)
    farmTab.Visible = (tab == farmTab)
    cheatsTab.Visible = (tab == cheatsTab)
    teleportTab.Visible = (tab == teleportTab)
    builderTab.Visible = (tab == builderTab)
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
local function createInfoBox(titleText, descText, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 0) -- Height akan otomatis
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.LayoutOrder = layoutOrder
    container.Parent = infoTab

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
createInfoBox("Teleport Options", "Instantly teleport to any player using 'TP To Player', or sneak up right behind them using 'TP Behind Player' for a surprise attack.", 10)
createInfoBox("Fling Player", "Select a target from the list, equip any Tool/Weapon in your hand, and click this to violently launch them into the sky using physics manipulation!", 11)
createInfoBox("Touch Fling", "Turns your character into a walking hazard. Anyone who physically touches your character will instantly be flung away. Excellent for passive defense.", 12)
createInfoBox("Scan RemoteEvents", "An advanced debugging feature that logs all RemoteEvents in the server. Helpful for developers analyzing the game's network structure.", 13)
createInfoBox("Builder System", "A comprehensive saving system for your structures. Use 'Copy Base' to save buildings within a radius to your local file, and 'Load Base' to rebuild them instantly anywhere.", 14)

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
attackCooldownLabel.Text = "Attack Cooldown:"
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

-- CHEATS TAB
createToggle("FallDamageToggle", "Anti Fall Dmg", "AntiFallDamage", 1, cheatsTab)
local noclipBtn = createToggle("NoclipToggle", "Noclip", "Noclip", 2, cheatsTab)
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

local feInvisibleBtn = createToggle("FEInvisibleToggle", "👻 FE Invisible + God", "FEInvisible", 10, cheatsTab)

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

local scanRemoteBtn = Instance.new("TextButton")
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

createToggle("TouchFling", "Touch Fling (Vibrate)", "TouchFling", 2, teleportTab)

spawn(function()
    while true do
        wait(0.5)
        if State.TouchFling then
            if not touchFlingThread or coroutine.status(touchFlingThread) == "dead" then
                touchFlingThread = coroutine.create(touchFlingLoop)
                coroutine.resume(touchFlingThread)
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
tpBtn.Text = "TP To Player"
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

local playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(1, 0, 0, 30)
playerDropdown.Position = UDim2.new(0, 0, 0, 70)
playerDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.TextSize = 12
playerDropdown.Text = "Select Player..."
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

tpBtn.MouseButton1Click:Connect(function()
    local success, char, targetChar, targetName = checkTeleportRequirements()
    if success then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end -- Lepaskan dari kursi jika sedang duduk
        
        -- Gunakan PivotTo agar seluruh model karakter ikut berpindah tanpa terputus
        local targetCFrame = targetChar:GetPivot()
        char:PivotTo(targetCFrame * CFrame.new(0, 2, -3) * CFrame.Angles(0, math.pi, 0))
        
        local root = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Fix Kamera "Lemot/Lag"
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = CFrame.lookAt(root.Position + (root.CFrame.LookVector * -12) + Vector3.new(0, 5, 0), root.Position)
            end
        end
        
        if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end -- Force physics update
        
        logAction("TELEPORT", "Successfully INSTANT teleported to " .. targetName)
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

local deleteRadiusBtn = Instance.new("TextButton")
deleteRadiusBtn.Size = UDim2.new(0.9, 0, 0, 35)
deleteRadiusBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
deleteRadiusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteRadiusBtn.Font = Enum.Font.GothamBold
deleteRadiusBtn.TextSize = 13
deleteRadiusBtn.Text = "Delete in Area (Radius " .. State.CopyRadius .. ")"
deleteRadiusBtn.LayoutOrder = 12
deleteRadiusBtn.Parent = builderTab

builderRadiusInput.FocusLost:Connect(function()
    local num = tonumber(builderRadiusInput.Text)
    if num then
        if num < 10 then num = 10 end
        if num > 5000 then num = 5000 end
        State.CopyRadius = num
        builderRadiusInput.Text = tostring(num)
        copyBaseBtn.Text = "Copy Base (Radius " .. num .. ")"
        deleteRadiusBtn.Text = "Delete in Area (Radius " .. num .. ")"
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

local pasteBaseBtn = Instance.new("TextButton")
pasteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
pasteBaseBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
pasteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteBaseBtn.Font = Enum.Font.GothamBold
pasteBaseBtn.TextSize = 13
pasteBaseBtn.Text = "Paste Selected Base"
pasteBaseBtn.LayoutOrder = 9
pasteBaseBtn.Parent = builderTab

local deleteBaseBtn = Instance.new("TextButton")
deleteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
deleteBaseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
deleteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteBaseBtn.Font = Enum.Font.GothamBold
deleteBaseBtn.TextSize = 13
deleteBaseBtn.Text = "Delete Selected Base"
deleteBaseBtn.LayoutOrder = 10
deleteBaseBtn.Parent = builderTab

local clearMyBuildsBtn = Instance.new("TextButton")
clearMyBuildsBtn.Size = UDim2.new(0.9, 0, 0, 35)
clearMyBuildsBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
clearMyBuildsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearMyBuildsBtn.Font = Enum.Font.GothamBold
clearMyBuildsBtn.TextSize = 13
clearMyBuildsBtn.Text = "Delete All My Buildings"
clearMyBuildsBtn.LayoutOrder = 11
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
    logAction("BUILDER", "Starting to delete your buildings in area (Radius " .. State.CopyRadius .. ")...")
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
                    local primary = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildOfClass("BasePart")
                    if primary then
                        local dist = (primary.Position - originPos).Magnitude
                        if dist <= State.CopyRadius then
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
    end
    logAction("BUILDER", "Done! " .. count .. " of your buildings in area deleted.")
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
                -- Angkat 20 stud untuk skybase
                targetCFrame = targetCFrame + Vector3.new(0, 20, 0)
            else
                -- Sistem Lama (Backward Compatibility): Tetap menghadap arah asli dunia
                local targetPos = currentPos + Vector3.new(0, 20, 0) + data.Offset
                targetCFrame = CFrame.new(targetPos) * data.Rotation
            end
            
            if placeEvent:IsA("RemoteEvent") then
                placeEvent:FireServer(data.Name, targetCFrame)
            else
                placeEvent:InvokeServer(data.Name, targetCFrame)
            end
            
            count = count + 1
            wait(0.3) -- Jeda kecepatan naruh barang agar tidak terdeteksi rate limit server
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
                    if (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= State.AuraRadius then
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
            
            hitCount = hitCount + 1
        end
        
        -- Trigger Attack Remote bawaan Tool jika ada (Cukup 1x per siklus, JANGAN di-spam)
        if hitCount > 0 and weapon then
            local atkEvt = weapon:FindFirstChild("AttackEvent")
            if atkEvt and atkEvt:IsA("RemoteEvent") then atkEvt:FireServer() end
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
