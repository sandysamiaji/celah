-- ==========================================
-- MENU FARM & AURA
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
local farmTab = Tabs.Farm
local logAction = getgenv().PandaHub.logAction

-- FARM TAB
UI.createToggle("AuraHarvestToggle", "Aura Harvest", "AuraHarvest", 1, farmTab)
UI.createToggle("AuraKillToggle", "Aura Kill", "AuraKill", 2, farmTab)

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

UI.createToggle("RewardToggle", "Claim Reward", "AutoClaimReward", 5, farmTab)
UI.createToggle("RespawnToggle", "Auto Respawn", "AutoRespawn", 6, farmTab)
UI.createToggle("AutoHealToggle", "Auto Bandage (x3)", "AutoHeal", 100, farmTab)
UI.createToggle("AutoEatToggle", "Auto Eat & Drink", "AutoEat", 7, farmTab)

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

local autoCookBtn = UI.createToggle("AutoCookToggle", "Auto Cook in Area", "AutoCook", 103, farmTab)


-- ==========================================
-- LOGIC
-- ==========================================
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
        if not State.FlingAura and not State.AutoAssassinActive then
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


-- INJECTED FROM CHEATS --
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
end-- Farm loops (AutoEat, AutoHeal, AutoCook, AuraHarvest) have been moved to tarung_menu_farm.luand


