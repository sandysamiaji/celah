local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "Panda Helper | Nuke & Commander", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "PandaHelper"
})

-- ==================== TABS ====================
local FarmTab = Window:MakeTab({
	Name = "Auto Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local NukeTab = Window:MakeTab({
	Name = "Nuke & Launch",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local RewardsTab = Window:MakeTab({
	Name = "Rewards",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local PlayerTab = Window:MakeTab({
	Name = "Player",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

-- ==================== VARIABLES ====================
local getgenv = getgenv or function() return _G end
getgenv().autoMerge = false
getgenv().autoCollect = false
getgenv().autoClaimReward = false
getgenv().autoDefense = false
getgenv().isUnderAttack = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getBestBombArg()
    local maxLvl = 0
    local bestObj = nil
    -- Scan workspace untuk mencari bom (biasanya nama modelnya berupa angka level)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and tonumber(v.Name) then
            local lvl = tonumber(v.Name)
            if lvl > maxLvl then
                maxLvl = lvl
                bestObj = v
            end
        end
    end
    return maxLvl, bestObj
end

local function toggleBomb(state)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes then
            if state then
                if remotes:FindFirstChild("PickUp") then
                    local lvl, obj = getBestBombArg()
                    
                    -- Kita coba kirim argumen Angka (int), String, dan Objek. 
                    -- Salah satunya pasti cocok dengan sistem gamenya agar bom terbesar terambil.
                    if lvl > 0 then
                        pcall(function() remotes.PickUp:FireServer(lvl) end)
                        pcall(function() remotes.PickUp:FireServer(tostring(lvl)) end)
                    end
                    if obj then
                        pcall(function() remotes.PickUp:FireServer(obj) end)
                    end
                    
                    -- Fallback jika PickUp tidak butuh argumen
                    pcall(function() remotes.PickUp:FireServer() end)
                end
            else
                if remotes:FindFirstChild("Drop") then remotes.Drop:FireServer() end
            end
        end
    end)
end

-- Deteksi serangan melalui RemoteEvent LockStateUpdate
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
    if remotes and remotes:FindFirstChild("LockStateUpdate") then
        remotes.LockStateUpdate.OnClientEvent:Connect(function(state)
            if getgenv().autoDefense then
                if state == "locked" then
                    getgenv().isUnderAttack = true
                    toggleBomb(true) -- Pegang bom
                else
                    getgenv().isUnderAttack = false
                    toggleBomb(false) -- Lepas bom
                end
            end
        end)
    end
end)

-- ==================== FARM TAB ====================
FarmTab:AddToggle({
	Name = "Auto Merge",
	Default = false,
    Callback = function(Value)
		getgenv().autoMerge = Value
        coroutine.wrap(function()
            while getgenv().autoMerge do
                wait(1)
                
                -- Hanya merge jika kondisi aman (tidak sedang diserang / memegang bom)
                if not getgenv().isUnderAttack then
                    -- Mencoba memicu Merge Request dari 2 lokasi remote yang ditemukan di log
                    pcall(function()
                        local nukeRemotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
                        if nukeRemotes and nukeRemotes:FindFirstChild("MergeRequest") then
                            nukeRemotes.MergeRequest:FireServer()
                        end
                    end)

                    pcall(function()
                        local pkgRemotes = ReplicatedStorage:FindFirstChild("Packages")
                        if pkgRemotes then
                            local mergeReq = pkgRemotes.Remotes.Networking["RE/Merge/MergeRequest"]
                            if mergeReq then
                                mergeReq:FireServer()
                            end
                        end
                    end)
                end
            end
        end)()
	end    
})

FarmTab:AddToggle({
	Name = "Auto Touch/Collect (Money/Drops)",
	Default = false,
	Callback = function(Value)
		getgenv().autoCollect = Value
        coroutine.wrap(function()
            while getgenv().autoCollect do
                wait(0.5)
                -- Teleportasikan semua drop ke player (berdasarkan log objek sentuhan "RMB_..." dan "neon")
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        for _, obj in pairs(workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("TouchTransmitter") then
                                -- Filter agar hanya mengambil objek uang / part tertentu (bisa disesuaikan)
                                if string.match(obj.Name, "RMB_") or obj.Name == "neon" then
                                    firetouchinterest(hrp, obj, 0)
                                    wait(0.01)
                                    firetouchinterest(hrp, obj, 1)
                                end
                            end
                        end
                    end
                end)
            end
        end)()
	end    
})

-- ==================== NUKE TAB ====================
NukeTab:AddToggle({
	Name = "Auto Defense (Hold Bomb on Attack)",
	Default = false,
	Callback = function(Value)
		getgenv().autoDefense = Value
        if not Value then
            getgenv().isUnderAttack = false
            toggleBomb(false)
        end
	end    
})

NukeTab:AddButton({
	Name = "Confirm OP Launch",
	Callback = function()
      	pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if remotes and remotes:FindFirstChild("ConfirmOPLaunch") then
                remotes.ConfirmOPLaunch:FireServer()
            end
        end)
  	end    
})

NukeTab:AddButton({
	Name = "Rebuild Done (Skip Build Time)",
	Callback = function()
      	pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if remotes and remotes:FindFirstChild("RebuildDone") then
                remotes.RebuildDone:FireServer()
            end
        end)
  	end    
})

-- ==================== REWARDS TAB ====================
RewardsTab:AddButton({
	Name = "Claim Group Reward",
	Callback = function()
      	pcall(function()
            local rf = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if rf and rf:FindFirstChild("ClaimGroupReward") then
                rf.ClaimGroupReward:InvokeServer()
            end
        end)
  	end    
})

RewardsTab:AddButton({
	Name = "Claim Offline Earnings",
	Callback = function()
      	pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if remotes and remotes:FindFirstChild("OfflineEarnings") then
                remotes.OfflineEarnings:FireServer()
            end
        end)
  	end    
})

-- ==================== PLAYER TAB ====================
PlayerTab:AddSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 200,
	Default = 16,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "Speed",
	Callback = function(Value)
		pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end
        end)
	end    
})

PlayerTab:AddSlider({
	Name = "JumpPower",
	Min = 50,
	Max = 300,
	Default = 50,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "Power",
	Callback = function(Value)
		pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = Value
            end
        end)
	end    
})

-- Inisialisasi UI
OrionLib:Init()
