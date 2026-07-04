local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local getgenv = getgenv or function() return _G end
getgenv().autoMerge = false
getgenv().autoCollect = false
getgenv().autoDefense = false
getgenv().isUnderAttack = false

rubah test

-- ==================== WEBHOOK LOGGER ====================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local http_request = request or http_request or (http and http.request) or syn and syn.request

getgenv().logBuffer = getgenv().logBuffer or {}

local function sendLog(logText)
    table.insert(getgenv().logBuffer, logText)
end

if not getgenv().LogLoopStarted then
    getgenv().LogLoopStarted = true
    coroutine.wrap(function()
        while true do
            wait(5)
            if #getgenv().logBuffer > 0 then
                -- Gabungkan semua isi buffer yang terkumpul dengan baris baru (enter)
                local combinedText = table.concat(getgenv().logBuffer, "\n")
                getgenv().logBuffer = {} -- Kosongkan buffer setelah disalin
                
                if http_request then
                    pcall(function()
                        http_request({
                            Url = WEBHOOK_URL,
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode({
                                content = combinedText
                            })
                        })
                    end)
                end
            end
        end
    end)()
end

-- Spy / Hook untuk mendeteksi remote yang ditembakkan secara manual
if not getgenv().PandaHooked then
    getgenv().PandaHooked = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if method == "FireServer" or method == "InvokeServer" then
            -- Hanya melog remote MergeRequest, PickUp, dan Drop agar tidak spam
            if self.Name == "MergeRequest" or self.Name == "PickUp" or self.Name == "Drop" then
                local args = {...}
                local argStr = ""
                for i, v in ipairs(args) do
                    if typeof(v) == "Instance" then
                        argStr = argStr .. "Instance("..v.Name.."), "
                    else
                        argStr = argStr .. tostring(v) .. ", "
                    end
                end
                
                -- Kirim via webhook
                sendLog("[C2S] " .. self.Name .. " | Args: " .. argStr)
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- ==================== LOGIC FUNCTIONS ====================
local function getBestBombArg()
    local maxLvl = 0
    local bestObj = nil
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
                    
                    if lvl > 0 then
                        pcall(function() remotes.PickUp:FireServer(lvl) end)
                        pcall(function() remotes.PickUp:FireServer(tostring(lvl)) end)
                    end
                    if obj then
                        pcall(function() remotes.PickUp:FireServer(obj) end)
                    end
                    pcall(function() remotes.PickUp:FireServer() end)
                end
            else
                if remotes:FindFirstChild("Drop") then remotes.Drop:FireServer() end
            end
        end
    end)
end

-- Deteksi serangan
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
    if remotes and remotes:FindFirstChild("LockStateUpdate") then
        remotes.LockStateUpdate.OnClientEvent:Connect(function(state)
            if getgenv().autoDefense then
                if state == "locked" then
                    getgenv().isUnderAttack = true
                    toggleBomb(true)
                else
                    getgenv().isUnderAttack = false
                    toggleBomb(false)
                end
            end
        end)
    end
end)

-- ==================== GUI CREATION ====================
if CoreGui:FindFirstChild("PandaHelperUI") then
    CoreGui.PandaHelperUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PandaHelperUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
MainFrame.Size = UDim2.new(0, 200, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = " Panda Helper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BorderSizePixel = 0

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Title
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0

CloseBtn.MouseButton1Click:Connect(function()
    -- Matikan semua loop saat di-close
    getgenv().autoMerge = false
    getgenv().autoCollect = false
    getgenv().autoDefense = false
    ScreenGui:Destroy()
end)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Size = UDim2.new(1, 0, 1, -30)
ScrollFrame.Position = UDim2.new(0, 0, 0, 30)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 350)
ScrollFrame.ScrollBarThickness = 4

local List = Instance.new("UIListLayout")
List.Parent = ScrollFrame
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0, 5)
List.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function createToggle(name, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ScrollFrame
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 40, 40)
    btn.Text = name .. ": " .. (defaultState and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    
    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 40, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

local function createButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ScrollFrame
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    
    btn.MouseButton1Click:Connect(function()
        callback()
    end)
end

-- ==================== ADDING BUTTONS ====================
local pad = Instance.new("Frame", ScrollFrame)
pad.Size = UDim2.new(1,0,0,2)
pad.BackgroundTransparency = 1

createToggle("Auto Merge", false, function(Value)
    getgenv().autoMerge = Value
    coroutine.wrap(function()
        while getgenv().autoMerge do
            wait(1)
            if not getgenv().isUnderAttack then
                pcall(function()
                    local nr = ReplicatedStorage:FindFirstChild("NukeRemotes")
                    if nr and nr:FindFirstChild("MergeRequest") then nr.MergeRequest:FireServer() end
                end)
                pcall(function()
                    local pkgs = ReplicatedStorage:FindFirstChild("Packages")
                    if pkgs then
                        local req = pkgs.Remotes.Networking["RE/Merge/MergeRequest"]
                        if req then req:FireServer() end
                    end
                end)
            end
        end
    end)()
end)

createToggle("Auto Touch Drops", false, function(Value)
    getgenv().autoCollect = Value
    coroutine.wrap(function()
        while getgenv().autoCollect do
            wait(0.5)
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("TouchTransmitter") then
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
end)

createToggle("Auto Defense (Bomb)", false, function(Value)
    getgenv().autoDefense = Value
    if not Value then
        getgenv().isUnderAttack = false
        toggleBomb(false)
    end
end)

createButton("Confirm OP Launch", function()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes and remotes:FindFirstChild("ConfirmOPLaunch") then
            remotes.ConfirmOPLaunch:FireServer()
        end
    end)
end)

createButton("Claim Offline Earning", function()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes and remotes:FindFirstChild("OfflineEarnings") then
            remotes.OfflineEarnings:FireServer()
        end
    end)
end)

createButton("Rebuild Done", function()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes and remotes:FindFirstChild("RebuildDone") then
            remotes.RebuildDone:FireServer()
        end
    end)
end)
