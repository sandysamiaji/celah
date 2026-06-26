-- ============================================================
-- Panda Industri - Auto Farm & Factory (Mr. Panda)
-- V2: Smart Supply Chain & Multi-Processing
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variabel Toggle
local ExecutionID = tick()
_G.PandaIndustriExecution = ExecutionID

local _G_State = {}
_G_State.AutoRefill = false
_G_State.AutoDelivery = false
_G_State.DeliveryMode = "Mati"
_G_State.AutoFactory = false
_G_State.AutoBuyAnimal = false
_G_State.AutoCollect = false
_G_State.AutoUpgradeUniversal = false
_G_State.AutoUpgradeFactory = false
_G_State.AutoBuyMastery = false
_G_State.AntiMonster = true
_G_State.LogEnabled = true
_G_State.LiveLogs = "=== PANDA INDUSTRI LIVE LOGS ===\n"

-- Animal toggles
_G_State.BuyAyam = false
_G_State.BuySapi = false
_G_State.BuyDomba = false
_G_State.BuyBabi = false

local tickCollect = 0

-- Daftar Semua Kemungkinan Resep Pabrik di Game Farming
local AllRecipes = {
    "Tepung", "Roti", "Benang", "Kain", "Baju",
    "Keju", "Mentega", "Krim", "Selai", "Kue",
    "Sirup", "Gula", "Minyak", "Sosis", "Burger",
    "Pancake", "Waffle"
}

-- Fungsi Utility
local function getTool(name)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild(name) then return char[name] end
    if LocalPlayer.Backpack:FindFirstChild(name) then return LocalPlayer.Backpack[name] end
    return nil
end

-- ============================================================
-- SYSTEM LOGGING (Memory & Webhook)
-- ============================================================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local http_request = request or http_request or (http and http.request) or syn and syn.request
local logBuffer = {}

local function sendBufferedLogs()
    if #logBuffer == 0 then return end
    if not http_request then return end
    
    local combinedLogs = table.concat(logBuffer, "\n")
    logBuffer = {} -- Kosongkan buffer setelah disiapkan
    
    task.spawn(function()
        pcall(function()
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Body = combinedLogs
            })
        end)
    end)
end

-- Kirim log secara batch setiap 5 detik untuk menghindari rate-limit
task.spawn(function()
    while task.wait(5) do
        sendBufferedLogs()
    end
end)

local lastLogs = {}
local function logAction(action, isSuccess, detail)
    if not _G_State.LogEnabled then return end
    -- Ubah format data menjadi string yang mudah dibaca
    if type(detail) == "table" then detail = "Table/Array" end
    local status = isSuccess and "SUKSES" or "GAGAL"
    local msg = string.format("[%s] %s | %s", status, action, tostring(detail))
    
    -- Anti-Spam: Jangan catat log yang persis sama berturut-turut untuk action yang sama
    if lastLogs[action] == msg then return end
    lastLogs[action] = msg

    local fullMsg = os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg
    
    -- Tulis ke memori (Untuk UI)
    _G_State.LiveLogs = _G_State.LiveLogs .. fullMsg .. "\n"
    
    -- Tulis ke Buffer Webhook (Untuk dikirim ke Google Sheets)
    table.insert(logBuffer, fullMsg)
    
    -- Coba update UI utama jika function tersedia
    if _G_State.UpdateUIDisplay then
        pcall(function() _G_State.UpdateUIDisplay(msg) end)
    end
    
    -- Batasi memori agar tidak bocor (max 50000 karakter)
    if #_G_State.LiveLogs > 50000 then
        _G_State.LiveLogs = string.sub(_G_State.LiveLogs, -40000)
    end
end

local function safeInvoke(remote, actionName, ...)
    local remoteName = remote and remote.Name or "UnknownRemote"
    local fullAction = actionName .. " -> " .. remoteName
    local s, r = pcall(function(...) return remote:InvokeServer(...) end, ...)
    if s then
        if r == false or r == nil or r == "Error" or r == "AlreadyFull" then
            -- logAction(fullAction, false, r or "Ditolak Server")
        else
            logAction(fullAction, true, r)
        end
    else
        logAction(fullAction, false, "ERROR SCRIPT: " .. tostring(r))
    end
end

-- ============================================================
-- SENSOR EKONOMI
-- ============================================================
local function getPlayerMoney()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local money = -1
    if pGui then
        for _, v in ipairs(pGui:GetDescendants()) do
            if v:IsA("TextLabel") and string.find(v.Text, "Rp") and not v:FindFirstAncestorWhichIsA("GuiButton") then
                local mStr = string.match(v.Text, "Rp%s*([%d%.]+)")
                if mStr then
                    local val = tonumber(string.gsub(mStr, "%.", ""))
                    if val and val > money then money = val end
                end
            end
        end
    end
    return money
end

local function getPrice(txt)
    local mStr = string.match(txt, "Rp%s*([%d%.]+)")
    if mStr then return tonumber(string.gsub(mStr, "%.", "")) end
    return 0 -- Jika tidak ada harga (gratis)
end

-- ============================================================
-- SMART DELIVERY HOOK
-- ============================================================
local function clickGuiButton(btn)
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn.Function() end
            for _, conn in pairs(getconnections(btn.MouseButton1Down)) do conn.Function() end
        end
    end)
end

task.spawn(function()
    while task.wait(2) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        local myMoney = getPlayerMoney()
        
        -- Siklus Tab Delivery (Smart Sales)
        local tabs = {}
        if _G_State.DeliveryMode == "Jual Mentah Saja" then
            tabs = {"mentah"}
        elseif _G_State.DeliveryMode == "Jual Olahan Saja" then
            tabs = {"olahan"}
        elseif _G_State.DeliveryMode == "Jual Semua (Mentah & Olahan)" then
            tabs = {"mentah", "olahan"}
        else
            tabs = {"olahan"} -- Fallback
        end
        
        if not _G_State.DelivCycle then _G_State.DelivCycle = 0 end
        if _G_State.AutoDelivery then
            _G_State.DelivCycle = _G_State.DelivCycle + 1
            if _G_State.DelivCycle > #tabs then _G_State.DelivCycle = 1 end
        end
        local activeTab = tabs[_G_State.DelivCycle] or tabs[1]

        -- UI CLICKER UNIVERSAL (Bypass tanpa harus buka menu)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in ipairs(pGui:GetDescendants()) do
                if v:IsA("GuiButton") then
                    local txt = string.lower(v.Name)
                    if v:IsA("TextButton") then txt = txt .. " " .. string.lower(v.Text) end
                    for _, child in ipairs(v:GetDescendants()) do -- Ganti ke GetDescendants agar teks terdalam terbaca
                        if child:IsA("TextLabel") or child:IsA("TextBox") then 
                            txt = txt .. " " .. string.lower(child.Text) 
                        end
                    end
                    
                    -- 1. Auto Delivery (Jual Cerdas)
                    if _G_State.AutoDelivery then
                        local isTab = (txt == activeTab)
                        local isAdd = string.find(txt, ">>") or string.find(txt, "max")
                        local isSend = string.find(txt, "kirim") or string.find(txt, "jual")
                        
                        -- Cari tombol barang dengan mendeteksi teks "stok:"
                        local isItem = string.find(txt, "stok:")
                        local hasStock = isItem and not string.find(txt, "stok: 0")
                        
                        if isTab then
                            clickGuiButton(v)
                        elseif isItem and hasStock then
                            -- KLIK BARANG YANG ADA STOKNYA!
                            clickGuiButton(v)
                        elseif isAdd or isSend then
                            clickGuiButton(v)
                        end
                    end
                    
                    -- 2. Auto Factory (Produksi & Ambil Hasil)
                    if _G_State.AutoFactory and (string.find(txt, "produksi") or string.find(txt, "ambil")) then
                        clickGuiButton(v)
                    end
                    
                    -- 3. Auto Upgrade Semua UI (Berdasarkan Saldo Uang)
                    if _G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory or _G_State.AutoBuyAnimal then
                        if string.find(txt, "rp") then
                            local price = getPrice(txt)
                            -- HANYA klik jika uang cukup!
                            if myMoney >= price then
                                local isAyam = string.find(txt, "ayam")
                                local isSapi = string.find(txt, "sapi")
                                local isDomba = string.find(txt, "domba")
                                local isBabi = string.find(txt, "babi")
                                
                                local shouldBuy = false
                                if isAyam then shouldBuy = _G_State.BuyAyam
                                elseif isSapi then shouldBuy = _G_State.BuySapi
                                elseif isDomba then shouldBuy = _G_State.BuyDomba
                                elseif isBabi then shouldBuy = _G_State.BuyBabi
                                else
                                    shouldBuy = (_G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory)
                                end
                                
                                if shouldBuy then 
                                    clickGuiButton(v)
                                    logAction("Auto Shop", true, string.format("Membeli Upgrade seharga Rp %d", price))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Fallback Remote Auto Delivery (Dihapus karena sudah digabung ke Patroli Fisik)
    end
end)

-- ============================================================
-- MAIN LOOP (Jantung Script)
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- ============================================================
        -- RUTE PATROLI (Keliling ke Pabrik & Pengiriman setiap 15 Detik)
        -- ============================================================
        if not _G_State.PatrolTick then _G_State.PatrolTick = tick() end
        if tick() - _G_State.PatrolTick > 15 then
            _G_State.PatrolTick = tick()
            
            -- 1. Kunjungi Pabrik (Jika Aktif)
            if _G_State.AutoFactory then
                local closestFactory = nil
                local minDist = math.huge
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local part = prompt.Parent
                        if part then
                            local pos = nil
                            if part:IsA("BasePart") then pos = part.Position
                            elseif part:IsA("Model") then pos = part:GetPivot().Position
                            elseif part:IsA("Attachment") then pos = part.WorldPosition end
                            
                            if pos then
                                local dist = (pos - hrp.Position).Magnitude
                                if dist < minDist then
                                    local act = string.lower(prompt.ActionText or "")
                                    local obj = string.lower(prompt.ObjectText or "")
                                    if string.find(act, "kelola") or string.find(obj, "pabrik") or string.find(act, "produksi") or string.find(act, "buka") then
                                        minDist = dist
                                        closestFactory = prompt
                                    end
                                end
                            end
                        end
                    end
                end
                
                if closestFactory then
                    task.spawn(function()
                        closestFactory.RequiresLineOfSight = false
                        if fireproximityprompt then fireproximityprompt(closestFactory) end
                        logAction("Patroli Mesin", true, "Akses Pabrik secara Remote (Tanpa Teleport)")
                    end)
                    task.wait(2.5) -- Beri jeda antar patroli
                end
            end
            
            -- 2. Kunjungi Pengiriman (Jika Aktif)
            if _G_State.AutoDelivery then
                local closestTruck = nil
                local minDist = math.huge
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local part = prompt.Parent
                        if part then
                            local pos = nil
                            if part:IsA("BasePart") then pos = part.Position
                            elseif part:IsA("Model") then pos = part:GetPivot().Position
                            elseif part:IsA("Attachment") then pos = part.WorldPosition end
                            
                            if pos then
                                local dist = (pos - hrp.Position).Magnitude
                                if dist < minDist then
                                    local act = string.lower(prompt.ActionText or "")
                                    if string.find(act, "jual") or string.find(act, "kirim") or string.find(string.lower(part.Name), "jual") then
                                        minDist = dist
                                        closestTruck = prompt
                                    end
                                end
                            end
                        end
                    end
                end
                
                if closestTruck then
                    task.spawn(function()
                        closestTruck.RequiresLineOfSight = false
                        if fireproximityprompt then fireproximityprompt(closestTruck) end
                        logAction("Patroli Penjualan", true, "Akses Truk secara Remote (Tanpa Teleport)")
                    end)
                end
            end
        end
        
        -- Z. Anti Monster (Werewolf Aura Kill)
        if _G_State.AntiMonster then
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character then
                    local name = string.lower(v.Name)
                    if string.find(name, "wolf") or string.find(name, "werewolf") or string.find(name, "monster") then
                        local mHrp = v:FindFirstChild("HumanoidRootPart")
                        local mHum = v:FindFirstChild("Humanoid")
                        
                        if mHrp and mHum and mHum.Health > 0 and (mHrp.Position - hrp.Position).Magnitude < 150 then
                            pcall(function()
                                -- 1. Kuras HP (Bypass Client-Sided Damage)
                                mHum.Health = 0 
                                
                                -- 2. Spam Senjata (Auto Swing Pedang/Tembak)
                                local char = LocalPlayer.Character
                                local bp = LocalPlayer:FindFirstChild("Backpack")
                                if char and bp then
                                    for _, tool in ipairs(bp:GetChildren()) do
                                        if tool:IsA("Tool") and not string.find(string.lower(tool.Name), "water") then
                                            tool.Parent = char
                                        end
                                    end
                                    for _, tool in ipairs(char:GetChildren()) do
                                        if tool:IsA("Tool") and not string.find(string.lower(tool.Name), "water") then
                                            tool:Activate()
                                        end
                                    end
                                end
                                
                                -- 3. Lempar paksa ke Void agar mati dibunuh oleh Server (FallenPartsDestroyHeight)
                                mHrp.CFrame = CFrame.new(mHrp.Position.X, -9999, mHrp.Position.Z)
                                mHrp.Velocity = Vector3.new(0, -9999, 0)
                            end)
                            logAction("Anti-Monster", true, "Aura Damage: Menyerang Werewolf!")
                        end
                    end
                end
            end
        end

        -- 1. Auto Refill Air (Fast Teleport Refill)
        if hrp then
            if _G_State.AutoRefill and (not _G_State.LastRefill or tick() - _G_State.LastRefill > 10) then
                local closestWell = nil
                local minDist = math.huge
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        local obj = string.lower(prompt.ObjectText or "")
                        local pName = string.lower(prompt.Parent and prompt.Parent.Name or "")
                        
                        -- Cek apakah ini sumur / tempat isi air
                        if string.find(obj, "isi air") or string.find(act, "isi air") or string.find(pName, "sumur") or string.find(pName, "waterclaim") then
                            local part = prompt.Parent
                            if part then
                                local pos = nil
                                if part:IsA("BasePart") then pos = part.Position
                                elseif part:IsA("Model") then pos = part:GetPivot().Position
                                elseif part:IsA("Attachment") then pos = part.WorldPosition end
                                
                                if pos then
                                    local dist = (pos - hrp.Position).Magnitude
                                    if dist < minDist then
                                        minDist = dist
                                        closestWell = prompt
                                    end
                                end
                            end
                        end
                    end
                end
                
                if closestWell then
                    task.spawn(function()
                        local char = LocalPlayer.Character
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        local part = closestWell.Parent
                        local cf = nil
                        if part:IsA("BasePart") then cf = part.CFrame
                        elseif part:IsA("Model") then cf = part:GetPivot()
                        elseif part:IsA("Attachment") then cf = CFrame.new(part.WorldPosition) end
                        
                        if not cf then return end
                        
                        -- Equip alat penyiram dulu
                        if bp and char then
                            for _, t in ipairs(bp:GetChildren()) do
                                if t:IsA("Tool") and string.find(string.lower(t.Name), "water") then
                                    t.Parent = char
                                end
                            end
                        end
                        task.wait(0.2)
                        
                        -- Teleport sekilas
                        local originalCFrame = hrp.CFrame
                        hrp.CFrame = cf + Vector3.new(0, 3, 0)
                        task.wait(0.2)
                        
                        -- Tahan di sana sampai penuh (Maksimal 3 detik)
                        local t = 0
                        while t < 30 do
                            local waterVal = 0
                            local currentTool = char:FindFirstChild("Watering Can") or bp:FindFirstChild("Watering Can")
                            if currentTool then
                                for _, v in ipairs(currentTool:GetDescendants()) do
                                    if (v:IsA("IntValue") or v:IsA("NumberValue")) and string.find(string.lower(v.Name), "water") then
                                        waterVal = v.Value
                                    end
                                end
                            end
                            if waterVal >= 100 then break end
                            
                            closestWell.RequiresLineOfSight = false
                            if fireproximityprompt then fireproximityprompt(closestWell) end
                            task.wait(0.1)
                            t = t + 1
                        end
                        
                        hrp.CFrame = originalCFrame
                        logAction("Auto Refill", true, "Isi air jarak jauh selesai (Penuh)!")
                    end)
                    
                    _G_State.LastRefill = tick()
                    task.wait(0.5) -- Beri jeda
                end
            end
            
            -- X. AURA SIRAM (Memperbesar area jangkauan siraman)
            local toolHand = hrp.Parent and hrp.Parent:FindFirstChild("Watering Can")
            if toolHand then
                pcall(function()
                    for _, v in ipairs(toolHand:GetDescendants()) do
                        if v:IsA("NumberValue") or v:IsA("IntValue") then
                            local n = string.lower(v.Name)
                            if string.find(n, "range") or string.find(n, "radius") or string.find(n, "area") or string.find(n, "distance") then
                                if v.Value < 150 then v.Value = 150 end
                            end
                        end
                    end
                    for name, val in pairs(toolHand:GetAttributes()) do
                        local n = string.lower(name)
                        if type(val) == "number" and (string.find(n, "range") or string.find(n, "radius") or string.find(n, "area") or string.find(n, "distance")) then
                            if val < 150 then toolHand:SetAttribute(name, 150) end
                        end
                    end
                end)
            end
            
            -- B. Auto Collect Barang
            if _G_State.AutoCollect then
                if not _G_State.CollectedItems then _G_State.CollectedItems = {} end
                
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        -- PASTIKAN HANYA BARANG DI DEKAT PEMAIN (Radius 150)
                        if (prompt.Parent.Position - hrp.Position).Magnitude > 150 then continue end
                        
                        local act = prompt.ActionText or ""
                        local obj = prompt.ObjectText or ""
                        if act == "Ambil" and not string.find(obj, "Isi Air") then
                            if not _G_State.CollectedItems[prompt] then
                                _G_State.CollectedItems[prompt] = true
                                pcall(function()
                                    local pos = prompt.Parent.Position
                                    hrp.CFrame = prompt.Parent.CFrame + Vector3.new(0, 1.5, 0)
                                    task.wait(0.4) -- Jeda aman pendaftaran posisi
                                    prompt.RequiresLineOfSight = false
                                    if fireproximityprompt then fireproximityprompt(prompt) end
                                    logAction("Auto Collect -> ProximityPrompt", true, string.format("Ambil %s di X:%.0f", obj, pos.X))
                                end)
                                break -- HANYA AMBIL 1! Sisa telur diambil di loop selanjutnya (0.5 detik kemudian)
                            end
                        end
                    end
                end
                
                -- Bersihkan memory (anti-lag)
                for p, _ in pairs(_G_State.CollectedItems) do
                    if typeof(p) ~= "Instance" or not p.Parent then _G_State.CollectedItems[p] = nil end
                end
            end
        end
        
        -- C. Auto Nyiram Tanaman (Pegang Gembor & Siram)
        if _G_State.AutoRefill then
            -- 1. Pindahkan dari tas ke tangan
            local toolBag = LocalPlayer.Backpack:FindFirstChild("Watering Can")
            if toolBag and hrp and hrp.Parent then
                local hum = hrp.Parent:FindFirstChild("Humanoid")
                if hum then
                    pcall(function() hum:EquipTool(toolBag) end)
                    task.wait(0.1)
                end
            end
            
            -- 2. Siram (Klik Kiri / Tembak Remote)
            local toolHand = hrp and hrp.Parent and hrp.Parent:FindFirstChild("Watering Can")
            if toolHand then
                pcall(function()
                    if toolHand:FindFirstChild("WaterRemote") then
                        toolHand.WaterRemote:FireServer()
                    end
                    toolHand:Activate()
                end)
            end
        end
        
        -- Deteksi WaterRemote cadangan
        if _G_State.AutoRefill then
            local tool = getTool("Watering Can")
            if tool and tool:FindFirstChild("WaterRemote") then
                pcall(function() tool.WaterRemote:FireServer() end)
            end
        end

        -- D. Auto Bantu Siram Tetangga
        if _G_State.AutoBantuSiram then
            if not _G_State.BantuTick then _G_State.BantuTick = 0 end
            if tick() - _G_State.BantuTick > 5 then
                _G_State.BantuTick = tick()
                
                local players = game:GetService("Players"):GetPlayers()
                local targets = {}
                for _, p in ipairs(players) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        -- Filter Target (Jika daftar kosong, maka siram semua)
                        local isTarget = false
                        if not _G_State.BantuTargets or #_G_State.BantuTargets == 0 then
                            isTarget = true
                        else
                            for _, t in ipairs(_G_State.BantuTargets) do
                                if string.lower(p.Name) == string.lower(t) or string.lower(p.DisplayName) == string.lower(t) then
                                    isTarget = true
                                    break
                                end
                            end
                        end
                        
                        if isTarget then
                            table.insert(targets, p.Character.HumanoidRootPart)
                        end
                    end
                end
                
                if #targets > 0 then
                    task.spawn(function()
                        local target = targets[math.random(1, #targets)]
                        local isAdminStand = _G_State.AdminStand and _G_State.BantuTargets and #_G_State.BantuTargets > 0
                        
                        if isAdminStand then
                            local firstTargetName = string.lower(_G_State.BantuTargets[1])
                            for _, t in ipairs(targets) do
                                local pName = string.lower(t.Parent.Name)
                                if pName == firstTargetName or string.find(pName, firstTargetName) then
                                    target = t
                                    break
                                end
                            end
                        end
                        
                        local originalCFrame = hrp.CFrame
                        
                        -- Pegang Gembor
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        local char = LocalPlayer.Character
                        local toolHand = nil
                        if bp and char then
                            for _, tool in ipairs(bp:GetChildren()) do
                                if tool:IsA("Tool") and string.find(string.lower(tool.Name), "water") then
                                    tool.Parent = char
                                    toolHand = tool
                                end
                            end
                            if not toolHand then toolHand = char:FindFirstChild("Watering Can") end
                        end
                        
                        if not isAdminStand then
                            -- Teleport sekilas ke tetangga (5 studs di atas kepala)
                            hrp.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                            logAction("Bantu Siram", true, "Teleport ke tetangga: " .. target.Parent.Name)
                        else
                            logAction("Bantu Siram", true, "Menyiram dari atas kepala: " .. target.Parent.Name)
                        end
                        
                        -- Siram cepat 3 kali
                        for i = 1, 3 do
                            if toolHand then
                                pcall(function()
                                    if toolHand:FindFirstChild("WaterRemote") then toolHand.WaterRemote:FireServer() end
                                    toolHand:Activate()
                                end)
                            end
                            task.wait(0.3)
                        end
                        
                        -- Pulang jika tidak sedang admin stand
                        if not isAdminStand then
                            hrp.CFrame = originalCFrame
                        end
                    end)
                end
            end
        end
        
        -- 2. Auto Factory (BRUTE-FORCE SEMUA RESEP SEKALIGUS!)
        if _G_State.AutoFactory then
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local startR = remotes:FindFirstChild("RequestStartProduction")
                local claimR = remotes:FindFirstChild("RequestClaimProduction")
                if startR and claimR then
                    for _, recipe in ipairs(AllRecipes) do
                        task.spawn(function() safeInvoke(startR, "Pabrik_Start_"..recipe, recipe) end)
                        task.spawn(function() safeInvoke(claimR, "Pabrik_Claim_"..recipe, recipe) end)
                    end
                else
                    logAction("Auto Factory", false, "Remote RequestStartProduction tidak ditemukan!")
                end
            else
                logAction("Auto Factory", false, "Folder ReplicatedStorage.Remotes tidak ditemukan!")
            end
        end
        
        -- 3. Auto Buy Animal (Membeli hewan yang dicentang)
        if _G_State.AutoBuyAnimal then
            local remote = RS:FindFirstChild("RequestBuyAnimal")
            if remote then
                if _G_State.BuyAyam then task.spawn(function() safeInvoke(remote, "Beli_Ayam", "Ayam") end) end
                if _G_State.BuySapi then task.spawn(function() safeInvoke(remote, "Beli_Sapi", "Sapi") end) end
                if _G_State.BuyDomba then task.spawn(function() safeInvoke(remote, "Beli_Domba", "Domba") end) end
                if _G_State.BuyBabi then task.spawn(function() safeInvoke(remote, "Beli_Babi", "Babi") end) end
            else
                logAction("Auto Buy Animal", false, "Remote RequestBuyAnimal tidak ditemukan!")
            end
        end

        -- E. Auto Upgrades & Auto Buy Animals (Via ProximityPrompt)
        if _G_State.AutoUpgradeUniversal or _G_State.AutoBuyAnimal or _G_State.AutoUpgradeFactory or _G_State.AutoBuyMastery then
            if not _G_State.UpgradeCooldowns then _G_State.UpgradeCooldowns = {} end
            
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    -- PASTIKAN HANYA UPGRADE DI DEKAT PEMAIN (Radius 150)
                    if (prompt.Parent.Position - hrp.Position).Magnitude > 150 then continue end
                    
                    local act = string.lower(prompt.ActionText or "")
                    local obj = string.lower(prompt.ObjectText or "")
                    
                    local isUpgrade = (_G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory) and (string.find(act, "tingkat") or string.find(act, "upgrade") or string.find(act, "buka"))
                    local isBuyAyam = _G_State.AutoBuyAnimal and _G_State.BuyAyam and (string.find(obj, "ayam") or string.find(act, "ayam")) and string.find(act, "beli")
                    local isBuySapi = _G_State.AutoBuyAnimal and _G_State.BuySapi and (string.find(obj, "sapi") or string.find(act, "sapi")) and string.find(act, "beli")
                    local isBuyDomba = _G_State.AutoBuyAnimal and _G_State.BuyDomba and (string.find(obj, "domba") or string.find(act, "domba")) and string.find(act, "beli")
                    local isBuyBabi = _G_State.AutoBuyAnimal and _G_State.BuyBabi and (string.find(obj, "babi") or string.find(act, "babi")) and string.find(act, "beli")
                    
                    if isUpgrade or isBuyAyam or isBuySapi or isBuyDomba or isBuyBabi then
                        local price = getPrice(act .. " " .. obj)
                        local myMoney = getPlayerMoney()
                        
                        -- JIKA ADA HARGA DAN UANG KURANG, LEWATI!
                        if price > 0 and myMoney > -1 and myMoney < price then
                            continue
                        end
                        
                        -- Cooldown 30 detik agar tidak nyangkut teleport ke tempat yang sama karena hal tak terduga
                        if not _G_State.UpgradeCooldowns[prompt] or tick() - _G_State.UpgradeCooldowns[prompt] > 30 then
                            _G_State.UpgradeCooldowns[prompt] = tick()
                            pcall(function()
                                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and prompt.Parent and prompt.Parent:IsA("BasePart") then
                                    local pos = prompt.Parent.Position
                                    if (hrp.Position - pos).Magnitude > 15 then
                                        hrp.CFrame = prompt.Parent.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.4) -- Jeda aman teleport
                                    end
                                end
                                prompt.RequiresLineOfSight = false
                                if fireproximityprompt then fireproximityprompt(prompt) end
                                logAction("Auto Shop", true, string.format("Mencoba %s %s", prompt.ActionText or "", prompt.ObjectText or ""))
                            end)
                            break -- Batasi 1 percobaan per loop (tiap setengah detik)
                        end
                    end
                end
            end
            
            -- Hapus cache untuk prompt yang sudah dihancurkan
            for p, _ in pairs(_G_State.UpgradeCooldowns) do
                if typeof(p) ~= "Instance" or not p.Parent then _G_State.UpgradeCooldowns[p] = nil end
            end
        end
        
        -- Fallback Remote Asli (Jika gamenya mendukung tanpa jalan)
        if _G_State.AutoBuyMastery then
            local remote = RS:FindFirstChild("RequestBuyFarmMastery")
            if remote then 
                local masteries = {"Tanam", "Hewan", "Pabrik", "Farming", "Animal", "Factory", "Watering"}
                for _, m in ipairs(masteries) do
                    task.spawn(function() pcall(function() remote:InvokeServer(m) end) end)
                end
            end
        end
    end
end)

-- ============================================================
-- UI Setup (WindUI Mr. Panda Theme)
-- ============================================================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title = "Panda Industri Pro",
    Icon = "box",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 380),
    Transparent = false
})

local TabFarm = Window:Tab({ Title = "Farming", Icon = "leaf" })
local TabFactory = Window:Tab({ Title = "Factory", Icon = "factory" })
local TabAnimal = Window:Tab({ Title = "Animals", Icon = "paw-print" })
local TabUpgrade = Window:Tab({ Title = "Upgrades", Icon = "trending-up" })
local TabLogs = Window:Tab({ Title = "Logs", Icon = "scroll-text" })

-- === TAB FARMING ===
TabFarm:Toggle({
    Title = "Auto Refill Water",
    Desc = "Otomatis mengisi air di Gembor",
    Default = false,
    Callback = function(state) _G_State.AutoRefill = state; logAction("Menu -> Auto Refill Water", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Auto Bantu Siram (Pahlawan)",
    Desc = "Teleport keliling ke pemain lain & menyiram lahan mereka",
    Default = false,
    Callback = function(state) _G_State.AutoBantuSiram = state; logAction("Menu -> Auto Bantu Siram", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Admin Stand (Nempel di Kepala)",
    Desc = "Mengikuti dan melayang di atas kepala target siram pertamamu!",
    Default = false,
    Callback = function(state)
        _G_State.AdminStand = state
        
        -- Matikan event lama jika ada
        if _G.AdminStandConn then
            _G.AdminStandConn:Disconnect()
            _G.AdminStandConn = nil
        end
        
        if state then
            local rs = game:GetService("RunService")
            _G.AdminStandConn = rs.Heartbeat:Connect(function()
                if not _G_State.AdminStand then return end
                if not _G_State.BantuTargets or #_G_State.BantuTargets == 0 then return end
                
                -- Ambil target pertama saja
                local targetName = string.lower(_G_State.BantuTargets[1])
                local p = nil
                for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                    if string.lower(player.Name) == targetName or string.lower(player.DisplayName) == targetName then
                        p = player
                        break
                    end
                end
                
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if p and myHrp and p.Character and p.Character:FindFirstChild("Head") then
                    myHrp.CFrame = p.Character.Head.CFrame + Vector3.new(0, 4, 0)
                    myHrp.Velocity = Vector3.new(0, 0, 0) -- Anti jatuh/terpeleset
                end
            end)
        end
        logAction("Menu -> Admin Stand", true, state and "AKTIF" or "MATI")
    end
})

_G_State.BantuTargets = {}
local PlayerSelectDropdown = TabFarm:Dropdown({
    Title = "Target Siram (Kosong = Semua)",
    Desc = "Pilih pemain (Target ke-1 jadi tumpangan Admin Stand)",
    Options = {"Memuat..."},
    Multi = true,
    Default = {},
    Callback = function(val)
        if type(val) == "table" then
            _G_State.BantuTargets = val
        elseif type(val) == "string" then
            _G_State.BantuTargets = {val}
        else
            _G_State.BantuTargets = {}
        end
    end
})

TabFarm:Button({
    Title = "Refresh Daftar Pemain",
    Callback = function()
        local list = {}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= LocalPlayer then table.insert(list, p.Name) end
        end
        if PlayerSelectDropdown and PlayerSelectDropdown.Refresh then
            PlayerSelectDropdown:Refresh(list)
        end
    end
})

TabFarm:Dropdown({
    Title = "Mode Penjualan (Truk Jual)",
    Desc = "Pilih kategori barang yang ingin dijual",
    Options = {"Mati", "Jual Semua (Mentah & Olahan)", "Jual Mentah Saja", "Jual Olahan Saja"},
    Default = "Mati",
    Callback = function(val)
        _G_State.DeliveryMode = val
        _G_State.AutoDelivery = (val ~= "Mati")
        logAction("Menu -> Mode Penjualan", true, val)
    end
})

TabFarm:Toggle({
    Title = "Auto Collect Barang (Magnet)",
    Desc = "Menarik Telur, Wol, Susu, dll ke badan",
    Default = false,
    Callback = function(state) _G_State.AutoCollect = state; logAction("Menu -> Auto Collect", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Anti-Monster (Aura Kill)",
    Desc = "Otomatis membunuh Werewolf yang mendekat dalam radius 150m",
    Default = true,
    Callback = function(state) _G_State.AntiMonster = state; logAction("Menu -> Anti-Monster", true, state and "AKTIF" or "MATI") end
})

-- === TAB FACTORY ===
TabFactory:Toggle({
    Title = "Auto Proses SEMUA Mesin!",
    Desc = "Otomatis memproses & mengambil hasil dari SEMUA mesin sekaligus",
    Default = false,
    Callback = function(state) _G_State.AutoFactory = state; logAction("Menu -> Auto Factory", true, state and "AKTIF" or "MATI") end
})

-- === TAB ANIMAL ===
TabAnimal:Toggle({
    Title = "Aktifkan Auto Beli",
    Desc = "Mulai membeli hewan yang dicentang di bawah",
    Default = false,
    Callback = function(state) _G_State.AutoBuyAnimal = state; logAction("Menu -> Auto Buy Animal", true, state and "AKTIF" or "MATI") end
})
TabAnimal:Toggle({ Title = "Beli Ayam", Default = false, Callback = function(state) _G_State.BuyAyam = state; logAction("Menu -> Beli Ayam", true, state and "AKTIF" or "MATI") end })
TabAnimal:Toggle({ Title = "Beli Sapi", Default = false, Callback = function(state) _G_State.BuySapi = state; logAction("Menu -> Beli Sapi", true, state and "AKTIF" or "MATI") end })
TabAnimal:Toggle({ Title = "Beli Domba", Default = false, Callback = function(state) _G_State.BuyDomba = state; logAction("Menu -> Beli Domba", true, state and "AKTIF" or "MATI") end })
TabAnimal:Toggle({ Title = "Beli Babi", Default = false, Callback = function(state) _G_State.BuyBabi = state; logAction("Menu -> Beli Babi", true, state and "AKTIF" or "MATI") end })

-- === TAB UPGRADE ===
TabUpgrade:Toggle({
    Title = "Auto Universal Upgrade",
    Desc = "Otomatis membeli upgrade seperti Tas, Kecepatan, Air",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeUniversal = state; logAction("Menu -> Universal Upgrade", true, state and "AKTIF" or "MATI") end
})

TabUpgrade:Toggle({
    Title = "Auto Upgrade & Unlock Pabrik",
    Desc = "Membuka mesin baru dan meng-upgrade semua mesin",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeFactory = state; logAction("Menu -> Factory Upgrade", true, state and "AKTIF" or "MATI") end
})

TabUpgrade:Toggle({
    Title = "Auto Farm Mastery",
    Desc = "Otomatis level up Mastery / Skill memanen",
    Default = false,
    Callback = function(state) _G_State.AutoBuyMastery = state; logAction("Menu -> Auto Farm Mastery", true, state and "AKTIF" or "MATI") end
})

-- === TAB LOGS ===
TabLogs:Toggle({
    Title = "Aktifkan Pencatatan Log",
    Desc = "Mencatat riwayat aktivitas secara real-time (bisa dimatikan jika terlalu spam)",
    Default = true,
    Callback = function(state) 
        _G_State.LogEnabled = state 
        if not state then
            if _G_State.UpdateUIDisplay then _G_State.UpdateUIDisplay("🚫 Pencatatan Log Dinonaktifkan") end
        else
            if _G_State.UpdateUIDisplay then _G_State.UpdateUIDisplay("✅ Pencatatan Log Diaktifkan") end
        end
    end
})

local LogDisplay = TabLogs:Paragraph({
    Title = "Live Logs (3 Baris Terakhir)",
    Desc = "Belum ada aktivitas..."
})

local logLines = {}
_G_State.UpdateUIDisplay = function(newMsg)
    table.insert(logLines, newMsg)
    if #logLines > 3 then table.remove(logLines, 1) end
    if LogDisplay and LogDisplay.SetDesc then
        LogDisplay:SetDesc(table.concat(logLines, "\n"))
    end
end

TabLogs:Input({
    Title = "Kirim Catatan (Ke Webhook)",
    Desc = "Ketik lokasi/teks lalu Enter untuk mencatat ke log",
    Placeholder = "Ketik catatan di sini...",
    Callback = function(text)
        if text == "" then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local pos = hrp and string.format("X:%.1f, Y:%.1f, Z:%.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "Unknown Pos"
        table.insert(logBuffer, string.format("[%s] CATATAN PABRIK | Lokasi: %s | Teks: %s", os.date("%Y-%m-%d %H:%M:%S"), pos, text))
        windui:Notify({Title="Terkirim!", Content="Catatan dikirim ke Google Webhook.", Duration=3})
    end
})

TabLogs:Button({
    Title = "Test Semua Alat & Objek",
    Desc = "Jalankan Auto-Test untuk alat di tas dan objek di map",
    Callback = function()
        logAction("Test", true, "Memulai Auto-Test Tools & Prompts...")
        task.spawn(function()
            local prompts = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then table.insert(prompts, v) end
            end
            if #prompts > 0 then
                for _, p in ipairs(prompts) do
                    local name = p.Parent and p.Parent.Name or "Unknown"
                    logAction("Test Sentuh", true, name)
                    pcall(function() if fireproximityprompt then fireproximityprompt(p) end end)
                    task.wait(0.05)
                end
            end
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local char = LocalPlayer.Character
            local tools = {}
            if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
            if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
            if #tools > 0 then
                for _, t in ipairs(tools) do
                    logAction("Test Alat", true, t.Name)
                    pcall(function() t.Parent = char; task.wait(0.1); t:Activate() end)
                    task.wait(0.2)
                end
            end
            logAction("Test", true, "Auto-Test Selesai!")
        end)
    end
})

TabLogs:Button({
    Title = "Salin (Copy) Log",
    Desc = "Salin semua log memori ke Clipboard",
    Callback = function()
        setclipboard(_G_State.LiveLogs)
        windui:Notify({Title="Berhasil Disalin!", Content="Log sudah di-copy. Silakan Paste sekarang!", Duration=3})
    end
})

TabLogs:Button({
    Title = "Hapus Log (Clear)",
    Desc = "Bersihkan memori log",
    Callback = function()
        _G_State.LiveLogs = "=== PANDA INDUSTRI LIVE LOGS ===\n"
        logLines = {}
        lastLogs = {}
        if _G_State.UpdateUIDisplay then _G_State.UpdateUIDisplay("Belum ada aktivitas...") end
        windui:Notify({Title="Dibersihkan!", Content="Log memori sudah dihapus.", Duration=3})
    end
})

-- Matikan UI overlay jika masih nyala dari script sebelumnya
pcall(function() game:GetService("CoreGui").PandaIndustriMini:Destroy() end)

-- ============================================================
-- REMOTE SERVICE DETECTION (Auto-Scan)
-- ============================================================
task.spawn(function()
    if not _G.HasScannedRemotes then
        _G.HasScannedRemotes = true
        task.wait(3) -- Tunggu game load
        local found = {}
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(found, (v:IsA("RemoteEvent") and "[RE] " or "[RF] ") .. v.Name)
            end
        end
        if #found > 0 then
            table.insert(logBuffer, "=== REMOTE SERVICE DETECTION ===\nDitemukan " .. #found .. " Remotes di ReplicatedStorage:\n" .. table.concat(found, "\n"))
        end
    end
end)

windui:Notify({
    Title = "Mr. Panda Loaded!",
    Content = "Sistem Live Log Memory & Webhook Aktif!",
    Duration = 5
})
