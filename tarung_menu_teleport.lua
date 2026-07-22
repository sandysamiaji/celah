-- ==========================================
-- MENU TELEPORT
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")

local State = getgenv().PandaHub.State
local UI = getgenv().PandaHub.UI
local Tabs = getgenv().PandaHub.Tabs
local track = getgenv().PandaHub.track
local teleportTab = Tabs.Teleport
local logAction = getgenv().PandaHub.logAction

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
playerList.Size = UDim2.new(1, 0, 0, 150)
playerList.Position = UDim2.new(0, 0, 1, 0)
playerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerList.ScrollBarThickness = 4
playerList.Visible = false
playerList.ZIndex = 10
playerList.Parent = playerDropdown

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
                    
                    if myChar then
                        for _, part in ipairs(myChar:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                    
                    if tHrp and myHrp and bv and bg then
                        local targetPos = (tHrp.CFrame * CFrame.new(0, 0, 2)).Position
                        local dir = (targetPos - myHrp.Position).Unit
                        local dist = (targetPos - myHrp.Position).Magnitude
                        
                        if dist > 1 then
                            bv.Velocity = dir * flyToTargetSpeed
                        else
                            bv.Velocity = Vector3.new(0, 0, 0)
                        end
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
                
                -- Reset velocity agar tidak glitch terbang
                myHrp.Velocity = Vector3.new(0, 0, 0)
                myHrp.RotVelocity = Vector3.new(0, 0, 0)
                RunService.Heartbeat:Wait()
                myHrp.Velocity = Vector3.new(0, 0, 0)
                myHrp.RotVelocity = Vector3.new(0, 0, 0)
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
end)

playerDropdown.MouseButton1Click:Connect(function()
    playerList.Visible = not playerList.Visible
    if playerList.Visible then
        updatePlayerList()
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
    
    State.AutoAssassinActive = true
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
            -- logFlingAnalytics("AUTO_ASSASSIN", targetName, hrp, tHrp)
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
    
    State.AutoAssassinActive = false
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


-- ==========================================
-- LOGIC
-- ==========================================

-- MOVED FROM CHEATS --
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
                -- logFlingAnalytics("FLING_AURA", targetHrp.Parent.Name, hrp, targetHrp)
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

UI.createToggle("TouchFling", "Touch Fling (Vibrate)", "TouchFling", 2, teleportTab)
UI.createToggle("FlingAura", "Fling Aura (Area Fling)", "FlingAura", 3, teleportTab)
UI.createToggle("TeleportToSelectedBtn", "Teleport (Pilih Pemain)", "TeleportToSelected", 3.2, teleportTab)
UI.createToggle("TeleportToMouseBtn", "Teleport ke Mouse (C)", "TeleportToMouse", 3.3, teleportTab)
UI.createToggle("CamFollowBtn", "Kamera Ikuti Target", "CamFollow", 3.4, teleportTab)
UI.createToggle("LockFlingToggle", "Lock Fling (Target)", "LockFling", 3.5, teleportTab)
UI.createToggle("AutoLockKillerToggle", "Auto Lock Killer (Revenge)", "AutoLockKiller", 3.6, teleportTab)

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

task.spawn(function()
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
    
    local cam = workspace.CurrentCamera
    if State.CamFollow and State.SelectedPlayer then
        local tPlayer = Players:FindFirstChild(State.SelectedPlayer)
        local tHum = tPlayer and tPlayer.Character and tPlayer.Character:FindFirstChildOfClass("Humanoid")
        if tHum and tHum.Health > 0 then
            if cam.CameraSubject ~= tHum then
                cam.CameraSubject = tHum
            end
        end
    elseif not State.LockFling then
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if myHum and cam and cam.CameraSubject ~= myHum then
            cam.CameraSubject = myHum
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.C and State.TeleportToMouse then
        local mouse = LocalPlayer:GetMouse()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and mouse.Hit then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            if logAction then logAction("TELEPORT", "Teleported to Mouse (C)") end
        end
    end
end)

-- Solusi elegan untuk Mobile (dan PC): Tombol melayang "🎯 TP" di layar saat fitur aktif
local CoreGui = game:GetService("CoreGui")
local tpGui = Instance.new("ScreenGui")
tpGui.Name = "PandaHub_MobileTP"
tpGui.Parent = CoreGui

local mobileTpBtn = Instance.new("TextButton")
mobileTpBtn.Size = UDim2.new(0, 50, 0, 50)
mobileTpBtn.Position = UDim2.new(1, -70, 0.5, 0) -- Di sebelah kanan tengah layar
mobileTpBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
mobileTpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileTpBtn.Font = Enum.Font.GothamBold
mobileTpBtn.TextSize = 14
mobileTpBtn.Text = "🎯 TP"
mobileTpBtn.Visible = false
mobileTpBtn.Parent = tpGui

-- Buat tombol membulat cantik
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = mobileTpBtn

mobileTpBtn.MouseButton1Click:Connect(function()
    if not State.TeleportToMouse then return end
    local mouse = LocalPlayer:GetMouse()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and mouse.Hit then
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        if logAction then logAction("TELEPORT", "Teleported via 🎯 TP Button!") end
    end
end)

-- Pantau perubahan state untuk menampilkan/menyembunyikan tombol
task.spawn(function()
    while true do
        wait(0.5)
        if State.TeleportToMouse then
            mobileTpBtn.Visible = true
        else
            mobileTpBtn.Visible = false
        end
    end
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
                    for _, part in ipairs(c:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                    hrp.Velocity = Vector3.new(10000, 10000, 10000)
                    hrp.RotVelocity = Vector3.new(10000, 10000, 10000)
                    
                    local cam = workspace.CurrentCamera
                    if cam.CameraSubject ~= tHum then
                        cam.CameraSubject = tHum
                    end
                end)
            else
                if State.AutoLockKiller and tHum and tHum.Health <= 0 then
                    State.LockFling = false
                    State.SelectedPlayer = nil
                    if logAction then logAction("REVENGE", "Target terbunuh! Lock Fling dimatikan.") end
                end
                
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
            RunService.Heartbeat:Wait()
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

-- ==========================================
-- AUTO LOCK KILLER (REVENGE) LOGIC
-- ==========================================
local function setupAutoLockKiller(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            if State.AutoLockKiller then
                local creator = hum:FindFirstChild("creator")
                if creator and creator.Value and creator.Value:IsA("Player") then
                    local killerName = creator.Value.Name
                    if killerName ~= LocalPlayer.Name then
                        State.SelectedPlayer = killerName
                        State.LockFling = true
                        if logAction then logAction("REVENGE", "Dibunuh oleh " .. killerName .. "! Auto-Lock Fling (Extreme) ACTIVATED!") end
                    end
                end
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(setupAutoLockKiller)
if LocalPlayer.Character then
    setupAutoLockKiller(LocalPlayer.Character)
end
