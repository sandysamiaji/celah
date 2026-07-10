-- ==============================================================================
-- ANTIGRAVITY MILITARY EXPLOIT (rem.lua)
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
local lastLogSend = tick()

-- Memory Storage untuk sistem Record & Replay
local MemoryStorage = {
    Rockets = {},
    IsRecording = false
}

local State = {
    WebhookLogs = true,
    SpyTrace = true -- Otomatis nyala untuk merekam PlacementRequest
}

-- Logging System
local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(logQueue, msg)
end

local function processLogQueue()
    if #logQueue == 0 then return end
    
    local payload = {
        content = table.concat(logQueue, "\n")
    }
    
    -- Clear queue
    logQueue = {}
    
    if State.WebhookLogs then
        pcall(function()
            local jsonData = HttpService:JSONEncode(payload)
            local req = nil
            if syn and syn.request then req = syn.request
            elseif http and http.request then req = http.request
            elseif request then req = request end
            
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
end

-- Looping pengiriman webhook tiap 2 detik
coroutine.wrap(function()
    while true do
        wait(2)
        processLogQueue()
    end
end)()

-- SPY REMOTE SYSTEM (Otomatis merekam PlacementRequest / Delete)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if State.SpyTrace and not checkcaller() then
        if method == "FireServer" or method == "InvokeServer" then
            local remoteName = tostring(self.Name)
            if remoteName == "PlacementRequest" or remoteName == "PlacementState" or remoteName:match("Build") or remoteName:match("Delete") or remoteName:match("Sell") then
                -- Tangkap tabel memori jika sedang Record
                if MemoryStorage.IsRecording and remoteName == "PlacementRequest" then
                    local actionType = tostring(args[1])
                    -- Simpan argumen jika ini adalah penempatan roket (PlaceRocketBatch / SetAttackDeployFocus)
                    if actionType == "PlaceRocketBatch" or actionType == "SetAttackDeployFocus" then
                        table.insert(MemoryStorage.Rockets, args)
                        logAction("BUILDER-MEMORY", "Berhasil menangkap 1 tabel roket! Total tersimpan: " .. #MemoryStorage.Rockets)
                    end
                end

                -- Konversi argumen ke string untuk dilog
                local argStr = ""
                for i, v in ipairs(args) do
                    if typeof(v) == "CFrame" then
                        argStr = argStr .. string.format("CFrame(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) .. ", "
                    elseif typeof(v) == "Instance" then
                        argStr = argStr .. "Instance(" .. v.Name .. "), "
                    else
                        argStr = argStr .. tostring(v) .. ", "
                    end
                end
                
                logAction("SPY-REMOTE", remoteName .. " | Args: [" .. argStr .. "]")
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

-- Bersihkan GUI Lama jika ada
if CoreGui:FindFirstChild("AntiGravityMilitary") then
    CoreGui.AntiGravityMilitary:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiGravityMilitary"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 300)
frame.Position = UDim2.new(0.5, -200, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 40) -- Adjusted size to make room for minimize button
title.BackgroundColor3 = Color3.fromRGB(30, 40, 45)
title.TextColor3 = Color3.fromRGB(46, 204, 113)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Text = "ANTIGRAVITY - MILITARY HUB"
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

local btnMinimize = Instance.new("TextButton")
btnMinimize.Size = UDim2.new(0, 40, 0, 40)
btnMinimize.Position = UDim2.new(1, -40, 0, 0)
btnMinimize.BackgroundColor3 = Color3.fromRGB(30, 40, 45)
btnMinimize.TextColor3 = Color3.fromRGB(200, 200, 200)
btnMinimize.Font = Enum.Font.GothamBold
btnMinimize.TextSize = 18
btnMinimize.Text = "-"
btnMinimize.Parent = frame

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 10)
minimizeCorner.Parent = btnMinimize

local isMinimized = false
btnMinimize.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        btnMinimize.Text = "+"
        frame.Size = UDim2.new(0, 400, 0, 40)
        -- Sembunyikan konten lain
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= title and child ~= btnMinimize and child ~= uiCorner then
                child.Visible = false
            end
        end
    else
        btnMinimize.Text = "-"
        frame.Size = UDim2.new(0, 400, 0, 300)
        -- Tampilkan konten lain
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= title and child ~= btnMinimize and child ~= uiCorner then
                child.Visible = true
            end
        end
        -- Kembalikan state tab
        if tycoonPage.Visible then
            builderPage.Visible = false
        else
            tycoonPage.Visible = false
        end
    end
end)

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabContainer

local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 55, 65)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Text = name
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.Parent = tabContainer
    return btn
end

local btnTycoon = createTabButton("Tycoon")
local btnBuilder = createTabButton("Free Build")

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -20, 1, -95)
contentContainer.Position = UDim2.new(0, 10, 0, 85)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = frame

-- Tab Pages
local tycoonPage = Instance.new("ScrollingFrame")
tycoonPage.Size = UDim2.new(1, 0, 1, 0)
tycoonPage.BackgroundTransparency = 1
tycoonPage.ScrollBarThickness = 4
tycoonPage.CanvasSize = UDim2.new(0, 0, 0, 500)
tycoonPage.Visible = true
tycoonPage.Parent = contentContainer

local tycoonLayout = Instance.new("UIListLayout")
tycoonLayout.SortOrder = Enum.SortOrder.LayoutOrder
tycoonLayout.Padding = UDim.new(0, 8)
tycoonLayout.Parent = tycoonPage

local builderPage = Instance.new("ScrollingFrame")
builderPage.Size = UDim2.new(1, 0, 1, 0)
builderPage.BackgroundTransparency = 1
builderPage.ScrollBarThickness = 4
builderPage.CanvasSize = UDim2.new(0, 0, 0, 600)
builderPage.Visible = false
builderPage.Parent = contentContainer

local builderLayout = Instance.new("UIListLayout")
builderLayout.SortOrder = Enum.SortOrder.LayoutOrder
builderLayout.Padding = UDim.new(0, 8)
builderLayout.Parent = builderPage

-- Tab Switching Logic
btnTycoon.MouseButton1Click:Connect(function()
    tycoonPage.Visible = true
    builderPage.Visible = false
    btnTycoon.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    btnBuilder.BackgroundColor3 = Color3.fromRGB(45, 55, 65)
end)

btnBuilder.MouseButton1Click:Connect(function()
    tycoonPage.Visible = false
    builderPage.Visible = true
    btnTycoon.BackgroundColor3 = Color3.fromRGB(45, 55, 65)
    btnBuilder.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
end)

-- Default Tab State
btnTycoon.BackgroundColor3 = Color3.fromRGB(46, 204, 113)

-- ==============================================================================
-- TYCOON LOGIC
-- ==============================================================================
local autoTycoonLoop = false
local btnAutoTycoon = Instance.new("TextButton")
btnAutoTycoon.Size = UDim2.new(1, 0, 0, 35)
btnAutoTycoon.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
btnAutoTycoon.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAutoTycoon.Font = Enum.Font.GothamBold
btnAutoTycoon.TextSize = 13
btnAutoTycoon.Text = "Auto Collect / Claim Tycoon Buttons [OFF]"
btnAutoTycoon.Parent = tycoonPage

btnAutoTycoon.MouseButton1Click:Connect(function()
    autoTycoonLoop = not autoTycoonLoop
    if autoTycoonLoop then
        btnAutoTycoon.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        btnAutoTycoon.Text = "Auto Tycoon [ON]"
        
        -- Background loop untuk menyentuh semua tombol
        coroutine.wrap(function()
            while autoTycoonLoop do
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Fitur ini akan kita sempurnakan nanti setelah mendapat info struktur Tycoon
                end
                wait(2)
            end
        end)()
    else
        btnAutoTycoon.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        btnAutoTycoon.Text = "Auto Tycoon [OFF]"
    end
end)

-- ==============================================================================
-- BUILDER LOGIC (Record & Replay Memory Tables)
-- ==============================================================================
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Text = "Tabel Tersimpan: 0 Roket"
statusLabel.Parent = builderPage

local btnRecord = Instance.new("TextButton")
btnRecord.Size = UDim2.new(1, 0, 0, 35)
btnRecord.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
btnRecord.TextColor3 = Color3.fromRGB(255, 255, 255)
btnRecord.Font = Enum.Font.GothamBold
btnRecord.TextSize = 13
btnRecord.Text = "[1] Mulai Merekam (Record)"
btnRecord.Parent = builderPage

local btnReplay = Instance.new("TextButton")
btnReplay.Size = UDim2.new(1, 0, 0, 35)
btnReplay.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
btnReplay.TextColor3 = Color3.fromRGB(255, 255, 255)
btnReplay.Font = Enum.Font.GothamBold
btnReplay.TextSize = 13
btnReplay.Text = "[2] Paste / Replay (Normal)"
btnReplay.Parent = builderPage

local btnDupe = Instance.new("TextButton")
btnDupe.Size = UDim2.new(1, 0, 0, 35)
btnDupe.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
btnDupe.TextColor3 = Color3.fromRGB(255, 255, 255)
btnDupe.Font = Enum.Font.GothamBold
btnDupe.TextSize = 13
btnDupe.Text = "[3] GLITCH / DUPE LIMIT"
btnDupe.Parent = builderPage

local btnBypassDict = Instance.new("TextButton")
btnBypassDict.Size = UDim2.new(1, 0, 0, 35)
btnBypassDict.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
btnBypassDict.TextColor3 = Color3.fromRGB(255, 255, 255)
btnBypassDict.Font = Enum.Font.GothamBold
btnBypassDict.TextSize = 13
btnBypassDict.Text = "[4] BYPASS COST (0-Cost Dict)"
btnBypassDict.Parent = builderPage

local btnBypassArray = Instance.new("TextButton")
btnBypassArray.Size = UDim2.new(1, 0, 0, 35)
btnBypassArray.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
btnBypassArray.TextColor3 = Color3.fromRGB(255, 255, 255)
btnBypassArray.Font = Enum.Font.GothamBold
btnBypassArray.TextSize = 13
btnBypassArray.Text = "[5] BYPASS COST (Batch 100x)"
btnBypassArray.Parent = builderPage

-- Akses langsung ke path pasti (dari hasil spy: ReplicatedStorage.PlacementRemotes.PlacementRequest)
local placementRemote = nil
local function findPlacementRemote()
    -- Coba path langsung dulu (paling cepat & pasti)
    local direct = ReplicatedStorage:FindFirstChild("PlacementRemotes")
        and ReplicatedStorage.PlacementRemotes:FindFirstChild("PlacementRequest")
    if direct then return direct end
    
    -- Fallback: scan seluruh descendants
    for _, desc in ipairs(game:GetDescendants()) do
        if desc.Name == "PlacementRequest" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            return desc
        end
    end
    return nil
end

-- Helper: dump tabel secara rekursif
local function dumpTable(tbl, depth)
    depth = depth or 1
    if depth > 5 then return "{...}" end
    if typeof(tbl) ~= "table" then
        if typeof(tbl) == "CFrame" then
            return string.format("CFrame(%.1f,%.1f,%.1f)", tbl.X, tbl.Y, tbl.Z)
        elseif type(tbl) == "string" then
            return '"' .. tbl .. '"'
        else
            return tostring(tbl)
        end
    end
    
    local parts = {}
    for k, v in pairs(tbl) do
        local keyStr = type(k) == "string" and k or "[" .. tostring(k) .. "]"
        table.insert(parts, keyStr .. "=" .. dumpTable(v, depth + 1))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

-- Helper: debug print args ke log
local function debugArgs(args)
    local parts = {}
    for _, v in pairs(args) do
        table.insert(parts, dumpTable(v, 1))
    end
    return table.concat(parts, ", ")
end

-- Inisialisasi remote
placementRemote = findPlacementRemote()
if placementRemote then
    statusLabel.Text = "Remote OK: " .. placementRemote.ClassName .. " -> " .. placementRemote:GetFullName()
    logAction("BUILDER-MEMORY", "Remote siap: " .. placementRemote:GetFullName())
else
    statusLabel.Text = "Remote belum ditemukan, akan retry saat tombol ditekan..."
end

-- LOGIC REKAM
btnRecord.MouseButton1Click:Connect(function()
    MemoryStorage.IsRecording = not MemoryStorage.IsRecording
    if MemoryStorage.IsRecording then
        MemoryStorage.Rockets = {} -- Reset memory
        btnRecord.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        btnRecord.Text = "Sedang Merekam... (Tekan lagi untuk STOP)"
        statusLabel.Text = "Silakan taruh roket/bangunan secara manual..."
    else
        btnRecord.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        btnRecord.Text = "[1] Mulai Merekam (Record)"
        statusLabel.Text = "Tabel Tersimpan: " .. #MemoryStorage.Rockets .. " Roket"
    end
end)

-- LOGIC REPLAY (NORMAL)
btnReplay.MouseButton1Click:Connect(function()
    if #MemoryStorage.Rockets == 0 then
        statusLabel.Text = "ERROR: Belum ada tabel yang direkam!"
        return
    end
    
    -- Retry cari remote kalau masih nil
    if not placementRemote then
        placementRemote = findPlacementRemote()
    end
    if not placementRemote then
        statusLabel.Text = "ERROR: PlacementRequest remote tidak ditemukan!"
        return
    end
    
    local total = #MemoryStorage.Rockets
    statusLabel.Text = "Mem-paste " .. total .. " roket..."
    logAction("REPLAY", "Mulai paste " .. total .. " roket via " .. placementRemote:GetFullName())
    
    coroutine.wrap(function()
        local berhasil = 0
        for i, memoryArgs in ipairs(MemoryStorage.Rockets) do
            -- Log isi args untuk debug
            logAction("REPLAY-SEND", "Roket " .. i .. ": " .. debugArgs(memoryArgs))
            
            local ok, err = pcall(function()
                -- PlacementRequest adalah RemoteEvent (dari spy data)
                placementRemote:FireServer(table.unpack(memoryArgs))
            end)
            if ok then
                berhasil = berhasil + 1
            else
                logAction("REPLAY-ERROR", "Roket ke-" .. i .. " gagal: " .. tostring(err))
            end
            statusLabel.Text = "Paste: " .. i .. "/" .. total
            wait(0.3)
        end
        statusLabel.Text = "Paste selesai! " .. berhasil .. "/" .. total .. " berhasil"
        logAction("REPLAY", "Selesai. Berhasil: " .. berhasil .. "/" .. total)
    end)()
end)

-- LOGIC DUPE (SPAM RACE CONDITION)
btnDupe.MouseButton1Click:Connect(function()
    if #MemoryStorage.Rockets == 0 then
        statusLabel.Text = "ERROR: Belum ada tabel yang direkam!"
        return
    end
    
    if not placementRemote then
        placementRemote = findPlacementRemote()
    end
    if not placementRemote then
        statusLabel.Text = "ERROR: PlacementRequest remote tidak ditemukan!"
        return
    end
    
    statusLabel.Text = "MENGEKSEKUSI GLITCH DUPLIKASI..."
    
    coroutine.wrap(function()
        -- Spam tembak tabel rahasia ribuan kali tanpa jeda
        for i = 1, 2000 do
            for _, memoryArgs in ipairs(MemoryStorage.Rockets) do
                if placementRemote:IsA("RemoteEvent") then
                    placementRemote:FireServer(table.unpack(memoryArgs))
                else
                    coroutine.wrap(function()
                        placementRemote:InvokeServer(table.unpack(memoryArgs))
                    end)()
                end
            end
            -- Jeda 0.01 detik agar gamenya tidak crash (client-side lag)
            RunService.RenderStepped:Wait()
            if i % 100 == 0 then
                statusLabel.Text = "Dupe: " .. i .. "/2000 iterasi..."
            end
        end
    end)()
end)

-- LOGIC BYPASS DICTIONARY (Mencoba 0-Cost bypass)
btnBypassDict.MouseButton1Click:Connect(function()
    if #MemoryStorage.Rockets == 0 then
        statusLabel.Text = "ERROR: Belum ada roket direkam!"
        return
    end
    if not placementRemote then placementRemote = findPlacementRemote() end
    if not placementRemote then return end
    
    statusLabel.Text = "Mengeksekusi Bypass Dictionary..."
    coroutine.wrap(function()
        local memoryArgs = MemoryStorage.Rockets[1]
        local newArgs = {}
        for i, v in ipairs(memoryArgs) do newArgs[i] = v end
        
        if type(newArgs[2]) == "table" and type(newArgs[2].Entries) == "table" then
            local payload = {}
            for k,v in pairs(newArgs[2]) do payload[k] = v end
            
            local originalEntries = payload.Entries
            local newEntries = {}
            for i, entry in pairs(originalEntries) do
                newEntries["Exploit_Key_Bypass_Cost_" .. tostring(i)] = entry
            end
            payload.Entries = newEntries
            newArgs[2] = payload
            
            if placementRemote:IsA("RemoteEvent") then
                placementRemote:FireServer(table.unpack(newArgs))
            else
                placementRemote:InvokeServer(table.unpack(newArgs))
            end
            statusLabel.Text = "Bypass Dict Dikirim! Cek game apakah berhasil."
            logAction("EXPLOIT", "Bypass Dict Dikirim!")
        else
            statusLabel.Text = "ERROR: Format tabel Entries tidak cocok!"
        end
    end)()
end)

-- LOGIC BYPASS BATCH ARRAY (Mencoba Spam 100 entries di 1 paket)
btnBypassArray.MouseButton1Click:Connect(function()
    if #MemoryStorage.Rockets == 0 then
        statusLabel.Text = "ERROR: Belum ada roket direkam!"
        return
    end
    if not placementRemote then placementRemote = findPlacementRemote() end
    if not placementRemote then return end
    
    statusLabel.Text = "Mengeksekusi Bypass Batch X100..."
    coroutine.wrap(function()
        local memoryArgs = MemoryStorage.Rockets[1]
        local newArgs = {}
        for i, v in ipairs(memoryArgs) do newArgs[i] = v end
        
        if type(newArgs[2]) == "table" and type(newArgs[2].Entries) == "table" then
            local payload = {}
            for k,v in pairs(newArgs[2]) do payload[k] = v end
            
            local originalEntry = payload.Entries[1]
            if originalEntry then
                local newEntries = {}
                for i = 1, 100 do
                    local dupedEntry = {}
                    for k, v in pairs(originalEntry) do dupedEntry[k] = v end
                    if dupedEntry.OriginZ then
                        dupedEntry.OriginZ = dupedEntry.OriginZ + (i * 1.5)
                    end
                    newEntries[i] = dupedEntry
                end
                payload.Entries = newEntries
                newArgs[2] = payload
                
                if placementRemote:IsA("RemoteEvent") then
                    placementRemote:FireServer(table.unpack(newArgs))
                else
                    placementRemote:InvokeServer(table.unpack(newArgs))
                end
                statusLabel.Text = "Batch X100 Dikirim! Cek apakah uang kurang."
                logAction("EXPLOIT", "Bypass Batch X100 Dikirim!")
            else
                statusLabel.Text = "ERROR: Entri pertama kosong!"
            end
        else
            statusLabel.Text = "ERROR: Format tabel Entries tidak cocok!"
        end
    end)()
end)

-- SISTEM DRAG GUI
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
