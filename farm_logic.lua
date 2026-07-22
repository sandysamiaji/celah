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

