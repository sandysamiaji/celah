-- ==========================================
-- MENU CHEATS
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local State = getgenv().PandaHub.State
local UI = getgenv().PandaHub.UI
local Tabs = getgenv().PandaHub.Tabs
local track = getgenv().PandaHub.track
local cheatsTab = Tabs.Cheats
local logAction = getgenv().PandaHub.logAction

-- CHEATS TAB
UI.createToggle("FallDamageToggle", "Anti Fall Dmg", "AntiFallDamage", 1, cheatsTab)
local noclipBtn = UI.createToggle("NoclipToggle", "Noclip", "Noclip", 2, cheatsTab)
UI.createToggle("AntiFlingToggle", "Anti Fling", "AntiFling", 2.5, cheatsTab)
UI.createToggle("SpyToggle", "Spy Trace", "SpyTrace", 3, cheatsTab)
UI.createToggle("DropToggle", "Infinite Drop", "InfiniteDrop", 4, cheatsTab)
local flyBtn = UI.createToggle("FlyToggle", "Fly", "Fly", 5, cheatsTab)
UI.createToggle("NightModeToggle", "Night Mode", "NightMode", 6, cheatsTab)

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

UI.createToggle("WebhookToggle", "Enable Webhook Log", "WebhookLogs", 9, cheatsTab)

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

local feInvisibleBtn = UI.createToggle("FEInvisibleToggle", " FE Invisible + God", "FEInvisible", 10, cheatsTab)

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

local undergroundBtn = UI.createToggle("UndergroundToggle", "⛏️ Underground Mode", "UndergroundMode", 11, cheatsTab)

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
-- ==========================================
-- LOGIC
-- ==========================================
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
task.spawn(function()
    pcall(function()
        local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5))
        local controls = PlayerModule:GetControls()
        getMoveVector = function()
            return controls:GetMoveVector()
        end
    end)
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
            if not fakeFloor or not fakeFloor.Parent then
                if fakeFloor then fakeFloor:Destroy() end
                fakeFloor = Instance.new("Part")
                fakeFloor.Size = Vector3.new(5, 1, 5)
                fakeFloor.Anchored = true
                fakeFloor.Transparency = 1
                fakeFloor.CanCollide = true
                fakeFloor.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                fakeFloor.Parent = workspace
            end
            if not bbg or bbg.Parent ~= root then
                if bbg then bbg:Destroy() end
                bbg = Instance.new("BodyGyro")
                bbg.P = 9e4
                bbg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                bbg.Parent = root
            end
            if not bve or bve.Parent ~= root then
                if bve then bve:Destroy() end
                bve = Instance.new("BodyVelocity")
                bve.maxForce = Vector3.new(9e9, 9e9, 9e9)
                bve.Parent = root
            end
            
            hum.PlatformStand = false
            
            -- Pasang lantai di bawah kaki agar animasi jalan/idle tetap berjalan secara dinamis
            local hipHeight = hum.HipHeight > 0 and hum.HipHeight or 2
            local dropOffset = hipHeight + (root.Size.Y / 2) + 0.2
            fakeFloor.CFrame = root.CFrame - Vector3.new(0, dropOffset, 0)
            
            -- Arahkan badan karakter mengikuti kamera secara horizontal (agar tidak nungging)
            local look = camera.CFrame.LookVector
            bbg.cframe = CFrame.new(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))
            
            local moveVec = getMoveVector()
            local dir = camera.CFrame.LookVector * -moveVec.Z + camera.CFrame.RightVector * moveVec.X
            if dir.Magnitude > 0 then
                dir = dir.Unit
            else
                -- Mencegah bug karakter melayang pelan ke atas setelah fitur Lock/Assassin dimatikan
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
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
    
    -- Auto Respawn block
    if State.AutoRespawn and method == "FireServer" and self.Name == "OnDied" then
        return nil
    end

    -- Infinite Drop / Duplication Exploit (Spoofing Drop Amount)
    if State.InfiniteDrop and method == "FireServer" and (self.Name == "Drop" or self.Name == "DropItem" or self.Name == "DropItems") then
        for i, v in ipairs(args) do
            if type(v) == "number" then
                args[i] = State.CustomDropAmount or -9999999 -- Mengambil jumlah dari UI Gift
            elseif type(v) == "string" and State.CustomDropItem and State.CustomDropItem ~= "Semua Item" then
                args[i] = State.CustomDropItem -- Mengambil nama item dari UI Gift
            end
        end
        return oldNamecall(self, unpack(args))
    end
    
    -- Auto Gift Interception
    if State.AutoGift and not State.IsLoopDropping and method == "FireServer" and (self.Name == "Drop" or self.Name == "DropItem" or self.Name == "DropItems") then
        State.GiftRemote = self
        State.GiftArgs = args
        pcall(function()
            State.GiftStatusLabel.Text = "Status: Captured [" .. tostring(args[1] or "item") .. "]!"
            State.GiftStatusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
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
