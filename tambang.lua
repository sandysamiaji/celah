local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Konfigurasi
getgenv().Config = {
    AutoDig = false,
    AutoSell = false,
    AutoPickup = false,
    AuraGali = false,
    AuraRadius = 35,
    EnableLogs = false
}

local function getRemote(name)
    return Remotes:FindFirstChild(name)
end

-- Logging System
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
                        Body = HttpService:JSONEncode({ content = payload })
                    })
                end
            end)
        end)
    end
end

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

-- Cleanup Old GUI (Jika di-execute berulang kali)
pcall(function()
    if CoreGui:FindFirstChild("TambangHub") then CoreGui.TambangHub:Destroy() end
    if gethui and gethui():FindFirstChild("TambangHub") then gethui().TambangHub:Destroy() end
end)

-- UI Creation (Manual UI tanpa OrionLib)
local gui = Instance.new("ScreenGui")
gui.Name = "TambangHub"
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
frame.Size = UDim2.new(0, 300, 0, 320)
frame.Position = UDim2.new(0.5, -150, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = frame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 40)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 1
spacer.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = "⛏ AUTO TAMBANG HUB ⛏"
title.Parent = spacer

local function createToggle(name, text, stateKey, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = getgenv().Config[stateKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text .. (getgenv().Config[stateKey] and ": ON" or ": OFF")
    btn.LayoutOrder = layoutOrder
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        getgenv().Config[stateKey] = not getgenv().Config[stateKey]
        if getgenv().Config[stateKey] then
            btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.Text = text .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            btn.Text = text .. ": OFF"
        end
    end)
    return btn
end

-- Menambahkan tombol ke Frame
createToggle("AutoDigToggle", "Auto Dig (Gali)", "AutoDig", 2)
createToggle("AutoSellToggle", "Auto Sell (Jual)", "AutoSell", 3)
createToggle("AutoPickupToggle", "Auto Pickup Crystal", "AutoPickup", 4)
createToggle("AuraGaliToggle", "Aura Gali (Aura Dig)", "AuraGali", 5)

-- Slider / Input untuk Radius
local radiusContainer = Instance.new("Frame")
radiusContainer.Size = UDim2.new(0.9, 0, 0, 35)
radiusContainer.BackgroundTransparency = 1
radiusContainer.LayoutOrder = 6
radiusContainer.Parent = frame

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0.55, 0, 1, 0)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Radius Aura:"
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
radiusInput.Text = tostring(getgenv().Config.AuraRadius)
radiusInput.Parent = radiusContainer

radiusInput.FocusLost:Connect(function()
    local num = tonumber(radiusInput.Text)
    if num then
        getgenv().Config.AuraRadius = num
        radiusInput.Text = tostring(num)
    else
        radiusInput.Text = tostring(getgenv().Config.AuraRadius)
    end
end)

createToggle("EnableLogsToggle", "Enable Logs (Data Collector)", "EnableLogs", 7)

-- ==========================================
-- LOGIC / LOOPING
-- ==========================================

task.spawn(function()
    local digRemote = getRemote("DigRequest")
    while task.wait(0.1) do
        if getgenv().Config.AutoDig and digRemote then
            pcall(function() digRemote:FireServer() end)
        end
    end
end)

local player = Players.LocalPlayer
task.spawn(function()
    local digRemote = getRemote("DigRequest")
    while task.wait(0.05) do
        if getgenv().Config.AuraGali and digRemote and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local hrp = player.Character.HumanoidRootPart
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:find("Rock") or obj.Name:find("Ore") or obj.Name:find("Dirt")) then
                        local distance = (hrp.Position - obj.Position).Magnitude
                        if distance <= getgenv().Config.AuraRadius then
                            if not loggedObjects[obj] then
                                loggedObjects[obj] = true
                                logData("Menemukan Ore: " .. obj.Name .. " | Material: " .. tostring(obj.Material) .. " | Color: " .. tostring(obj.BrickColor) .. " | Posisi: " .. tostring(obj.Position))
                            end
                            digRemote:FireServer(obj)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local sellRemote = getRemote("SellRequest")
    while task.wait(2) do
        if getgenv().Config.AutoSell and sellRemote then
            pcall(function() sellRemote:FireServer() end)
        end
    end
end)

task.spawn(function()
    local pickupRemote = getRemote("CrystalDroppedPickup")
    while task.wait(0.5) do
        if getgenv().Config.AutoPickup and pickupRemote then
            pcall(function()
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
