-- ==========================================
-- Panda Mancing Hub V3 (Tabbed UI)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Clean up lama
pcall(function()
    if CoreGui:FindFirstChild("panda mancing") then CoreGui["panda mancing"]:Destroy() end
    if gethui and gethui():FindFirstChild("panda mancing") then gethui()["panda mancing"]:Destroy() end
end)

-- Remotes (Dynamic Finder)
local FoundRemotes = {}
local function getRemote(name)
    if FoundRemotes[name] ~= nil then 
        return FoundRemotes[name] == false and nil or FoundRemotes[name]
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            FoundRemotes[name] = obj
            return obj
        end
    end
    FoundRemotes[name] = false
    return nil
end

local function safeCall(remote, ...)
    if not remote then return end
    if remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    elseif remote:IsA("RemoteFunction") then
        local args = {...}
        task.spawn(function()
            pcall(function() remote:InvokeServer(unpack(args)) end)
        end)
    end
end

local HttpService = game:GetService("HttpService")

local State = {
    AutoFish = false,
    AutoClaim = false,
    SpamFireworks = false,
    Fly = false,
    FlySpeed = 50,
    Delay = 2.5,
    WebhookSpy = false,
    PerfectCast = false,
    InstantCatch = false
}

-- ==========================================
-- WEBHOOK SPY SYSTEM
-- ==========================================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
_G.PandaSpyQueue = _G.PandaSpyQueue or {}
_G.PandaSpyBlacklist = {
    "CastReplication", "UpdateCharacter", "UpdateMouse", "MoveDirection", "Animation", "Ping", "Stats"
}

-- Mencegah multi-hooking jika script dieksekusi berkali-kali
if not _G.PandaHookNamecall then
    _G.PandaHookNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        local isSpyActive = _G.PandaSpyActive or false
        local q = _G.PandaSpyQueue or {}
        local blacklist = _G.PandaSpyBlacklist or {}
        
        -- AUTO PERFECT CAST (Bekerja saat Mancing Manual)
        if State.PerfectCast and method == "FireServer" and self.Name == "CastReplication" then
            if args[4] and type(args[4]) == "number" then
                args[4] = 100 -- Ubah power langsung jadi 100 (Perfect) sebelum masuk ke server
            end
            if isSpyActive then
                table.insert(q, "[Auto Perfect Cast] Intercepted and forced 100% power!")
            end
            return _G.PandaHookNamecall(self, unpack(args))
        end
        
        if isSpyActive and not checkcaller() then
            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                local isBl = false
                for _, v in ipairs(blacklist) do
                    if v == self.Name or string.match(self.Name, v) then isBl = true break end
                end
                
                if not isBl then
                    local t = os.date("%Y-%m-%d %H:%M:%S")
                    local rType = (method == "FireServer") and "[C2S-RE]" or "[C2S-RF]"
                    
                    local argStr = ""
                    for i, v in ipairs(args) do
                        if type(v) == "table" then argStr = argStr .. "{...}"
                        elseif typeof(v) == "Instance" then argStr = argStr .. "[Inst: " .. v.Name .. "]"
                        elseif type(v) == "string" then argStr = argStr .. '"' .. v .. '"'
                        else argStr = argStr .. tostring(v) end
                        if i < #args then argStr = argStr .. ", " end
                    end
                    
                    local logMsg = string.format("[%s] %s %s | Args: %s", t, rType, self.Name, (argStr == "" and "none" or argStr))
                    table.insert(q, logMsg)
                    print(logMsg)
                end
            end
        end
        return _G.PandaHookNamecall(self, ...)
    end)
end

-- Coroutine Pengirim Webhook
coroutine.wrap(function()
    while true do
        task.wait(5)
        if State.WebhookSpy and #_G.PandaSpyQueue > 0 then
            local payload = { content = table.concat(_G.PandaSpyQueue, "\n") }
            _G.PandaSpyQueue = {} -- Clear queue
            local req = (syn and syn.request) or request or (http and http.request) or http_request
            if req then
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
            end
        end
    end
end)()

-- Instant Catch GUI Bypass (Menghapus Minigame "Klik-Klik" di layar)
RunService.RenderStepped:Connect(function()
    if State.InstantCatch or State.AutoFish then
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                for _, gui in ipairs(pg:GetChildren()) do
                    local name = string.lower(gui.Name)
                    -- Sembunyikan UI yang berhubungan dengan minigame mancing
                    if name ~= "panda mancing" and (string.match(name, "fish") or string.match(name, "minigame") or string.match(name, "catch") or string.match(name, "bar")) then
                        if gui:IsA("ScreenGui") and gui.Enabled then
                            gui.Enabled = false
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- LOGIC FUNCTIONS
-- ==========================================
local function doFishing()
    while State.AutoFish do
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            -- Cari alat pancing di tangan atau di Backpack
            local tool = char:FindFirstChildOfClass("Tool")
            local rodName = "Binary Edge"
            
            if tool then
                rodName = tool.Name
            else
                local bpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                if bpTool then
                    rodName = bpTool.Name
                    safeCall(getRemote("Inventory_EquipRod"), rodName)
                    task.wait(0.5)
                end
            end
            
            if char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local targetPos = hrp.Position + (hrp.CFrame.LookVector * 20)
                
                -- Melempar kail (Cast)
                safeCall(getRemote("CastReplication"), targetPos, Vector3.new(25, 5, 0), rodName, 100)
                
                local waitTime = State.InstantCatch and 0.1 or State.Delay
                task.wait(waitTime)
                
                if not State.AutoFish then return end
                
                -- Proses Minigame "Tap Tap" dan Catch secara otomatis
                safeCall(getRemote("FishingCatchSuccess"))
                safeCall(getRemote("FishRollResult"))
                safeCall(getRemote("FishCaught"), targetPos.X, targetPos.Y, targetPos.Z)
                task.wait(0.5)
                
                safeCall(getRemote("FishGiver"))
                safeCall(getRemote("CleanupCast"))
                
                -- Refresh inventory dan misi (dari log asli)
                task.spawn(function()
                    safeCall(getRemote("GetDailyInfo"))
                    safeCall(getRemote("Inventory_GetData"))
                end)
            end
        end)
        task.wait(1)
    end
end

local function doAutoClaim()
    while State.AutoClaim do
        pcall(function()
            safeCall(getRemote("ClaimDaily"))
            safeCall(getRemote("ClaimDailyMission"))
            safeCall(getRemote("ClaimMission"))
        end)
        task.wait(10)
    end
end

local function doSpamFireworks()
    while State.SpamFireworks do
        pcall(function()
            safeCall(getRemote("FireworksToggle"))
        end)
        task.wait(0.5)
    end
end

local function doFly()
    local bg, bv
    while State.Fly do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local hrp = char.HumanoidRootPart
            local hum = char.Humanoid
            if not bg or not bg.Parent then
                bg = Instance.new("BodyGyro")
                bg.P = 9e4
                bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.cframe = hrp.CFrame
                bg.Parent = hrp
            end
            if not bv or not bv.Parent then
                bv = Instance.new("BodyVelocity")
                bv.velocity = Vector3.new(0, 0, 0)
                bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = hrp
            end
            hum.PlatformStand = true
            
            local cam = workspace.CurrentCamera
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                bv.velocity = moveDir * State.FlySpeed
            else
                bv.velocity = Vector3.new(0,0,0)
            end
            bg.cframe = cam.CFrame
        end
        task.wait()
    end
    
    -- Cleanup Fly
    if bg then bg:Destroy() end
    if bv then bv:Destroy() end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
end

-- ==========================================
-- GUI STRUCTURE (Tabbed)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "panda mancing"
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
frame.Size = UDim2.new(0, 350, 0, 380)
frame.Position = UDim2.new(0.5, -175, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = gui

-- TOP BAR
local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 40)
spacer.BackgroundTransparency = 1
spacer.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = " PANDA MANCING HUB"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = spacer

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 1, 0)
minimizeBtn.Position = UDim2.new(1, -70, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(243, 156, 18)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.TextSize = 20
minimizeBtn.Text = "-"
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = spacer

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 1, 0)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 14
closeBtn.Text = "X"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = spacer

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 350, 0, 40)
        minimizeBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 350, 0, 380)
        minimizeBtn.Text = "-"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    State.AutoFish = false
    State.AutoClaim = false
    State.SpamFireworks = false
    State.Fly = false
    pcall(function() gui:Destroy() end)
end)

-- BODY
local bodyFrame = Instance.new("Frame")
bodyFrame.Size = UDim2.new(1, 0, 1, -40)
bodyFrame.Position = UDim2.new(0, 0, 0, 40)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = frame

-- NAV BAR
local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(0, 85, 1, 0)
navBar.BackgroundTransparency = 1
navBar.Parent = bodyFrame

local navLayout = Instance.new("UIListLayout")
navLayout.Parent = navBar
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Padding = UDim.new(0, 5)

-- Add padding top
local navPad = Instance.new("UIPadding")
navPad.PaddingTop = UDim.new(0, 5)
navPad.Parent = navBar

-- CONTENT CONTAINER
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -85, 1, 0)
contentContainer.Position = UDim2.new(0, 85, 0, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = bodyFrame

-- Tab Generator Helper
local tabs = {}
local function createTab(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name .. "Tab"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.Visible = false
    scroll.Parent = contentContainer
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = scroll
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 15)
    pad.Parent = scroll
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = name
    btn.Parent = navBar
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.scroll.Visible = false end
        scroll.Visible = true
    end)
    
    local tabObj = {scroll = scroll, btn = btn}
    table.insert(tabs, tabObj)
    return scroll
end

local farmTab = createTab("Farm")
local cheatsTab = createTab("Cheats")
local teleportTab = createTab("Teleport")
local miscTab = createTab("Misc")

-- Tampilkan tab pertama secara default
tabs[1].scroll.Visible = true

-- ==========================================
-- COMPONENT GENERATORS
-- ==========================================
local function createToggle(text, stateKey, func, parentTab)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text .. ": OFF"
    btn.Parent = parentTab
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        if State[stateKey] then
            btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.Text = text .. ": ON"
            if func then task.spawn(func) end
        else
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = text .. ": OFF"
        end
    end)
end

local function createButton(text, color, onClick, parentTab)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(52, 152, 219)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text
    btn.Parent = parentTab
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- ==========================================
-- 1. FARM TAB
-- ==========================================
createToggle("Auto Fish", "AutoFish", doFishing, farmTab)

local delayContainer = Instance.new("Frame")
delayContainer.Size = UDim2.new(0.9, 0, 0, 35)
delayContainer.BackgroundTransparency = 1
delayContainer.Parent = farmTab

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0.6, 0, 1, 0)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay:"
delayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
delayLabel.Font = Enum.Font.GothamBold
delayLabel.TextSize = 12
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = delayContainer

local delayInput = Instance.new("TextBox")
delayInput.Size = UDim2.new(0.35, 0, 0.8, 0)
delayInput.Position = UDim2.new(0.65, 0, 0.1, 0)
delayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
delayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
delayInput.Font = Enum.Font.Gotham
delayInput.TextSize = 12
delayInput.Text = tostring(State.Delay)
delayInput.Parent = delayContainer
local delayCorner = Instance.new("UICorner")
delayCorner.CornerRadius = UDim.new(0, 4)
delayCorner.Parent = delayInput

delayInput.FocusLost:Connect(function()
    local num = tonumber(delayInput.Text)
    if num and num > 0 then State.Delay = num else delayInput.Text = tostring(State.Delay) end
end)

createButton("Sell All Fish", Color3.fromRGB(243, 156, 18), function()
    pcall(function() safeCall(getRemote("SellFish")) end)
end, farmTab)

createToggle("Auto Claim Rewards", "AutoClaim", doAutoClaim, farmTab)

createToggle("Instant Catch (Bypass Minigame)", "InstantCatch", nil, farmTab)
createToggle("Auto Perfect Cast (Manual)", "PerfectCast", nil, farmTab)

-- ==========================================
-- 2. CHEATS TAB
-- ==========================================
createToggle("Fly", "Fly", doFly, cheatsTab)

local flySpeedContainer = Instance.new("Frame")
flySpeedContainer.Size = UDim2.new(0.9, 0, 0, 35)
flySpeedContainer.BackgroundTransparency = 1
flySpeedContainer.Parent = cheatsTab

local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Size = UDim2.new(0.6, 0, 1, 0)
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.Text = "Fly Speed:"
flySpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedLabel.Font = Enum.Font.GothamBold
flySpeedLabel.TextSize = 12
flySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
flySpeedLabel.Parent = flySpeedContainer

local flySpeedInput = Instance.new("TextBox")
flySpeedInput.Size = UDim2.new(0.35, 0, 0.8, 0)
flySpeedInput.Position = UDim2.new(0.65, 0, 0.1, 0)
flySpeedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedInput.Font = Enum.Font.Gotham
flySpeedInput.TextSize = 12
flySpeedInput.Text = tostring(State.FlySpeed)
flySpeedInput.Parent = flySpeedContainer
local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 4)
flyCorner.Parent = flySpeedInput

flySpeedInput.FocusLost:Connect(function()
    local num = tonumber(flySpeedInput.Text)
    if num and num > 0 then State.FlySpeed = num else flySpeedInput.Text = tostring(State.FlySpeed) end
end)

-- ==========================================
-- 3. TELEPORT TAB (Dropdown)
-- ==========================================
local tpContainer = Instance.new("Frame")
tpContainer.Size = UDim2.new(0.9, 0, 0, 35)
tpContainer.BackgroundTransparency = 1
tpContainer.ClipsDescendants = true
tpContainer.Parent = teleportTab

local selectedPlayer = nil

local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(0.65, 0, 0, 28)
dropBtn.Position = UDim2.new(0, 0, 0, 3)
dropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropBtn.Font = Enum.Font.Gotham
dropBtn.TextSize = 11
dropBtn.Text = "Select Player ▼"
dropBtn.Parent = tpContainer
local dropBtnCorner = Instance.new("UICorner")
dropBtnCorner.CornerRadius = UDim.new(0, 4)
dropBtnCorner.Parent = dropBtn

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0.3, 0, 0, 28)
tpBtn.Position = UDim2.new(0.7, 0, 0, 3)
tpBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 11
tpBtn.Text = "TP"
tpBtn.Parent = tpContainer
local tpBtnCorner = Instance.new("UICorner")
tpBtnCorner.CornerRadius = UDim.new(0, 4)
tpBtnCorner.Parent = tpBtn

local dropList = Instance.new("ScrollingFrame")
dropList.Size = UDim2.new(0.65, 0, 0, 120)
dropList.Position = UDim2.new(0, 0, 0, 35)
dropList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dropList.BorderSizePixel = 0
dropList.ScrollBarThickness = 4
dropList.Parent = tpContainer

local dropListLayout = Instance.new("UIListLayout")
dropListLayout.Parent = dropList
dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local isDropdownOpen = false

local function updateDropdown()
    for _, child in ipairs(dropList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, 0, 0, 25)
            pBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            pBtn.Font = Enum.Font.Gotham
            pBtn.TextSize = 10
            pBtn.Text = p.DisplayName
            pBtn.Parent = dropList
            
            pBtn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                dropBtn.Text = p.DisplayName .. " ▼"
                isDropdownOpen = false
                tpContainer.Size = UDim2.new(0.9, 0, 0, 35)
            end)
            count = count + 1
        end
    end
    dropList.CanvasSize = UDim2.new(0, 0, 0, count * 25)
end

dropBtn.MouseButton1Click:Connect(function()
    isDropdownOpen = not isDropdownOpen
    if isDropdownOpen then
        tpContainer.Size = UDim2.new(0.9, 0, 0, 160)
        updateDropdown()
    else
        tpContainer.Size = UDim2.new(0.9, 0, 0, 35)
    end
end)

tpBtn.MouseButton1Click:Connect(function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end)

-- ==========================================
-- 4. MISC TAB
-- ==========================================
createButton("Purchase Luck Boost", Color3.fromRGB(155, 89, 182), function()
    pcall(function() safeCall(getRemote("PurchaseLuckBoost")) end)
end, miscTab)

createButton("Show Hacker HUD", Color3.fromRGB(26, 188, 156), function()
    pcall(function() safeCall(getRemote("ShowEventHackerHUD")) end)
end, miscTab)

createButton("Rent Boat", Color3.fromRGB(52, 152, 219), function()
    pcall(function() safeCall(getRemote("RentBoat")) end)
end, miscTab)

createButton("Spam All Gifts", Color3.fromRGB(231, 76, 60), function()
    pcall(function() 
        safeCall(getRemote("RoseGiftEvents"))
        safeCall(getRemote("BungaGiftEvents"))
        safeCall(getRemote("SunflowerGiftEvents"))
        safeCall(getRemote("BonekaGiftEvents"))
    end)
end, miscTab)

createButton("Toggle Night Zone", Color3.fromRGB(52, 73, 94), function()
    pcall(function() safeCall(getRemote("NightZoneSync")) end)
end, miscTab)

createToggle("Spam Fireworks", "SpamFireworks", doSpamFireworks, miscTab)

createToggle("Webhook Remote Spy", "WebhookSpy", function()
    _G.PandaSpyActive = State.WebhookSpy
    if State.WebhookSpy then
        print("[!] Webhook Spy Activated. Logs will be sent to Google.")
    else
        print("[!] Webhook Spy Deactivated.")
    end
end, miscTab)

print("Panda Mancing Hub V3 (Tabbed) Loaded!")
