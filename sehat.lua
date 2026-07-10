-- ==============================================================================
-- ANTIGRAVITY - AUTO CLAIM & BUY TESTER (sehat.lua)
-- ==============================================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Konfigurasi Webhook
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local logQueue = {}

-- Logging System
local function logAction(text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s", t, text)
    table.insert(logQueue, msg)
end

local function processLogQueue()
    if #logQueue == 0 then return end
    local payload = { content = table.concat(logQueue, "\n") }
    logQueue = {}
    
    pcall(function()
        local jsonData = HttpService:JSONEncode(payload)
        local req = (syn and syn.request) or (http and http.request) or request
        if req then
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonData
            })
        end
    end)
end

coroutine.wrap(function()
    while true do
        task.wait(2)
        processLogQueue()
    end
end)()

-- Target Remotes
local TargetRemotes = {
    "shop_purchase",
    "gift_redeem",
    "calendar_redeem",
    "claim_task",
    "strike_reward",
    "offers_buy"
}

-- Storage untuk argumen terakhir
local LastArgs = {
    shop_purchase = nil,
    gift_redeem = nil,
    calendar_redeem = nil,
    claim_task = nil,
    strike_reward = nil,
    offers_buy = nil
}

-- Bersihkan GUI Lama jika ada
local targetGui = (gethui and gethui()) or CoreGui
if targetGui:FindFirstChild("AntiGravitySehat") then
    targetGui.AntiGravitySehat:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiGravitySehat"
screenGui.ResetOnSpawn = false
screenGui.Parent = targetGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 450, 0, 350)
frame.Position = UDim2.new(0.5, -225, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 40, 45)
title.TextColor3 = Color3.fromRGB(241, 196, 15)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = "ANTIGRAVITY - AUTO BUY & CLAIM TESTER"
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -50)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 450)
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, 0, 0, 60)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 12
logLabel.TextWrapped = true
logLabel.Text = "Menunggu kamu menekan tombol beli/klaim di game..."
logLabel.Parent = scrollFrame

-- Fungsi pembuat tombol
local function createButton(name, text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = scrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

local btnSpamShop = createButton("btnSpamShop", "SPAM BELI TOKO (Auto Buy)", Color3.fromRGB(46, 204, 113))
local btnSpamGift = createButton("btnSpamGift", "SPAM KLAIM HADIAH (Gift Redeem)", Color3.fromRGB(52, 152, 219))
local btnSpamTask = createButton("btnSpamTask", "SPAM MISI (Claim Task)", Color3.fromRGB(155, 89, 182))
local btnSpamCalendar = createButton("btnSpamCalendar", "SPAM HARIAN (Calendar Redeem)", Color3.fromRGB(230, 126, 34))

-- HELPER: Mencari remote di game
local function fireTargetRemote(remoteName, args)
    if not args then
        logLabel.Text = "ERROR: Belum ada data untuk " .. remoteName .. ". Coba lakukan manual di game 1x!"
        return
    end
    
    local remote = ReplicatedStorage.remotes:FindFirstChild(remoteName)
    if not remote then
        logLabel.Text = "ERROR: Remote " .. remoteName .. " tidak ditemukan di game!"
        return
    end
    
    logLabel.Text = "Sedang melakukan SPAM " .. remoteName .. " sebanyak 100x..."
    coroutine.wrap(function()
        for i = 1, 100 do
            if remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args))
            elseif remote:IsA("RemoteFunction") then
                coroutine.wrap(function() remote:InvokeServer(table.unpack(args)) end)()
            end
            if i % 10 == 0 then task.wait() end -- Anti lag
        end
        logLabel.Text = "Selesai spam 100x untuk " .. remoteName .. "!"
        logAction("SEHAT-EXPLOIT | Selesai spam 100x untuk remote: " .. remoteName)
    end)()
end

-- Events
btnSpamShop.MouseButton1Click:Connect(function() fireTargetRemote("shop_purchase", LastArgs.shop_purchase) end)
btnSpamGift.MouseButton1Click:Connect(function() fireTargetRemote("gift_redeem", LastArgs.gift_redeem) end)
btnSpamTask.MouseButton1Click:Connect(function() fireTargetRemote("claim_task", LastArgs.claim_task) end)
btnSpamCalendar.MouseButton1Click:Connect(function() fireTargetRemote("calendar_redeem", LastArgs.calendar_redeem) end)

-- SPY SYSTEM KHUSUS (Hanya merekam argumen Klaim/Beli)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        local remoteName = tostring(self.Name)
        
        -- Cek apakah remote ini ada di daftar TargetRemotes
        local isTarget = false
        for _, tName in ipairs(TargetRemotes) do
            if remoteName == tName then
                isTarget = true
                break
            end
        end
        
        if isTarget then
            -- Simpan argumennya!
            LastArgs[remoteName] = args
            
            -- Tampilkan di log UI
            local argStr = ""
            for i, v in ipairs(args) do
                argStr = argStr .. tostring(v) .. ", "
            end
            
            local logMsg = "TEREKAM! [" .. remoteName .. "] Args: " .. argStr
            logLabel.Text = logMsg
            logAction("SEHAT-SPY | " .. logMsg)
        end
    end
    
    return oldNamecall(self, ...)
end)

logLabel.Text = "Menu siap! Silakan beli 1 barang di toko atau klaim 1 hadiah secara manual di gamenya, lalu tekan tombol SPAM di bawah."
