-- Script Auto Tambang
-- Dibuat berdasarkan log remote spy

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Konfigurasi Toggle
getgenv().Config = {
    AutoDig = false,
    AutoSell = false,
    AutoPickup = false,
    AuraGali = false,
    AuraRadius = 35,
    EnableLogs = false
}

-- ==========================================
-- WEBHOOK & LOGGING SYSTEM
-- ==========================================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local logQueue = {}
local lastLogSend = tick()
local loggedObjects = {}

local function processLogQueue()
    if not getgenv().Config.EnableLogs then
        logQueue = {}
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
                        Body = game:GetService("HttpService"):JSONEncode({ content = payload })
                    })
                end
            end)
        end)
    end
end

-- Timer pemroses antrean log (5 detik sekali via trigger logic)
task.spawn(function()
    while task.wait(1) do
        processLogQueue()
    end
end)

local function logData(text)
    if getgenv().Config.EnableLogs then
        table.insert(logQueue, "[LOG " .. os.date("%H:%M:%S") .. "] " .. text)
    end
end

-- Fungsi pembantu untuk mengambil remote
local function getRemote(name)
    return Remotes:FindFirstChild(name)
end

-- ==========================================
-- UI SEDERHANA MENGGUNAKAN ORION LIBRARY
-- ==========================================
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexsoftware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Auto Tambang Script", HidePremium = false, SaveConfig = false, IntroText = "Auto Tambang"})

local MainTab = Window:MakeTab({
	Name = "Main Features",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

MainTab:AddToggle({
	Name = "Auto Dig (Gali)",
	Default = false,
	Callback = function(Value)
		getgenv().Config.AutoDig = Value
	end    
})

MainTab:AddToggle({
	Name = "Auto Sell (Jual)",
	Default = false,
	Callback = function(Value)
		getgenv().Config.AutoSell = Value
	end    
})

MainTab:AddToggle({
	Name = "Auto Pickup Crystal",
	Default = false,
	Callback = function(Value)
		getgenv().Config.AutoPickup = Value
	end    
})

MainTab:AddToggle({
	Name = "Aura Gali (Aura Dig)",
	Default = false,
	Callback = function(Value)
		getgenv().Config.AuraGali = Value
	end    
})

MainTab:AddSlider({
	Name = "Radius Aura Gali",
	Min = 5,
	Max = 100,
	Default = 35,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "Studs",
	Callback = function(Value)
		getgenv().Config.AuraRadius = Value
	end    
})

MainTab:AddToggle({
	Name = "Enable Logs (Data Collector)",
	Default = false,
	Callback = function(Value)
		getgenv().Config.EnableLogs = Value
	end    
})

-- ==========================================
-- LOGIC / LOOPING
-- ==========================================

-- Loop Auto Dig
task.spawn(function()
    local digRemote = getRemote("DigRequest")
    while task.wait(0.1) do
        if getgenv().Config.AutoDig and digRemote then
            pcall(function()
                -- Eksekusi request menggali
                digRemote:FireServer()
            end)
        end
    end
end)

-- Loop Aura Gali
local player = game:GetService("Players").LocalPlayer
task.spawn(function()
    local digRemote = getRemote("DigRequest")
    while task.wait(0.05) do
        if getgenv().Config.AuraGali and digRemote and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local hrp = player.Character.HumanoidRootPart
                -- Scan workspace untuk mencari blok ("Rock", "Ore", "Dirt", dll.) dalam radius
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:find("Rock") or obj.Name:find("Ore") or obj.Name:find("Dirt")) then
                        local distance = (hrp.Position - obj.Position).Magnitude
                        if distance <= getgenv().Config.AuraRadius then
                            -- Log deteksi ore jika belum pernah di log
                            if not loggedObjects[obj] then
                                loggedObjects[obj] = true
                                logData("Menemukan Ore: " .. obj.Name .. " | Material: " .. tostring(obj.Material) .. " | Color: " .. tostring(obj.BrickColor) .. " | Posisi: " .. tostring(obj.Position))
                            end
                            -- Gali block tersebut (mencoba passing block sebagai argumen, atau sekadar spam remote)
                            digRemote:FireServer(obj)
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop Auto Sell
task.spawn(function()
    local sellRemote = getRemote("SellRequest")
    while task.wait(2) do
        if getgenv().Config.AutoSell and sellRemote then
            pcall(function()
                -- Eksekusi request jual
                sellRemote:FireServer()
            end)
        end
    end
end)

-- Loop Auto Pickup
task.spawn(function()
    local pickupRemote = getRemote("CrystalDroppedPickup")
    while task.wait(0.5) do
        if getgenv().Config.AutoPickup and pickupRemote then
            pcall(function()
                -- Untuk pickup biasanya membutuhkan target objek crystal yang ada di Workspace
                -- Skrip ini akan mencoba mencari part dengan nama 'Crystal' di workspace
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        if obj.Name:lower():find("crystal") then
                            if not loggedObjects[obj] then
                                loggedObjects[obj] = true
                                logData("Mendeteksi Crystal Drop: " .. obj.Name)
                            end
                            pickupRemote:FireServer(obj)
                        end
                    end
                end
            end)
        end
    end
end)

OrionLib:Init()
