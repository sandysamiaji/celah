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

        -- Y. Auto Collect Barang (Magnet Jarak Jauh)
        if _G_State.AutoCollect then
            local char = LocalPlayer.Character
            for _, v in ipairs(workspace:GetDescendants()) do
                -- Mode 1: Proximity Prompt "Ambil"
                if v:IsA("ProximityPrompt") then
                    local act = string.lower(v.ActionText or "")
                    local obj = string.lower(v.ObjectText or "")
                    if string.find(act, "ambil") or string.find(act, "collect") or string.find(act, "pick") or string.find(obj, "hasil") or string.find(obj, "telur") or string.find(obj, "susu") or string.find(obj, "wol") or string.find(act, "pungut") then
                        v.RequiresLineOfSight = false
                        if fireproximityprompt then fireproximityprompt(v) end
                    end
                -- Mode 2: TouchInterest (Barang Jatuh)
                elseif v:IsA("BasePart") and v:FindFirstChild("TouchInterest") and char and not v:IsDescendantOf(char) then
                    -- Pastikan bukan ngambil part/senjata milik pemain lain
                    local isPlayer = false
                    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                        if p.Character and v:IsDescendantOf(p.Character) then isPlayer = true break end
                    end
                    if not isPlayer then
                        if firetouchinterest then
                            firetouchinterest(hrp, v, 0)
                            task.wait(0.01)
                            firetouchinterest(hrp, v, 1)
                        else
                            v.CFrame = hrp.CFrame -- Fallback jika script executor tidak support firetouchinterest
                        end
                    end
                end
            end
        end

        -- W. Auto Pabrik Siluman (Setiap 5 detik)
        if _G_State.AutoPabrikSiluman then
            if not _G_State.NextPabrikSiluman then _G_State.NextPabrikSiluman = 0 end
            if tick() > _G_State.NextPabrikSiluman then
                _G_State.NextPabrikSiluman = tick() + 5
                if _G_State.SelectedPabrik and _G_State.SelectedPabrik ~= "" then
                    produksiPabrikSiluman(_G_State.SelectedPabrik)
                end
            end
        end

        -- 1. Auto Refill Air (Continuous Remote Refill)
        if hrp then
            if not _G_State.NextRefillDelay then _G_State.NextRefillDelay = 0 end
            if _G_State.AutoRefill and (not _G_State.LastRefill or tick() - _G_State.LastRefill > _G_State.NextRefillDelay) then
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
                        local part = closestWell.Parent
                        local cf = nil
                        if part:IsA("BasePart") then cf = part.CFrame
                        elseif part:IsA("Model") then cf = part:GetPivot()
                        elseif part:IsA("Attachment") then cf = CFrame.new(part.WorldPosition) end
                        
                        if cf then
                            local oldCf = hrp.CFrame
                            -- Teleport super cepat bolak-balik karena server mengecek jarak Sumur
                            hrp.CFrame = cf + Vector3.new(0, 3, 0)
                            task.wait(0.1)
                            closestWell.RequiresLineOfSight = false
                            if fireproximityprompt then fireproximityprompt(closestWell) end
                            task.wait(0.1)
                            hrp.CFrame = oldCf
                        end
                    end)
                    
                    _G_State.LastRefill = tick()
                    _G_State.NextRefillDelay = math.random(8, 15) / 10 -- Delay acak 0.8 s/d 1.5 detik agar tidak spam teleport
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
local function firePromptByName(nameKey, successMsg)
    local fired = false
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent then
            local pName = string.lower(prompt.Parent.Name)
            if string.find(pName, string.lower(nameKey)) then
                prompt.RequiresLineOfSight = false
                if fireproximityprompt then fireproximityprompt(prompt) end
                fired = true
            end
        end
    end
    if fired then
        logAction("Manual", true, successMsg)
    else
        logAction("Manual", false, "Gagal menemukan: " .. nameKey .. " (Pastikan map sudah ter-render)")
    end
end

local function jualSiluman(namaBarang)
    if not namaBarang or namaBarang == "" then return end
    task.spawn(function()
        firePromptByName("DeliveryOpen", "Membuka Truk Jual Siluman")
        task.wait(0.5)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not string.find(string.lower(gui.Name), "windui") and not string.find(string.lower(gui.Name), "panda") then
                    for _, v in ipairs(gui:GetDescendants()) do
                        if v:IsA("GuiButton") then
                            local txt = string.lower(v.Name)
                            if v:IsA("TextButton") then txt = txt .. " " .. string.lower(v.Text) end
                            for _, child in ipairs(v:GetDescendants()) do 
                                if child:IsA("TextLabel") or child:IsA("TextBox") then txt = txt .. " " .. string.lower(child.Text) end
                            end
                            if string.find(txt, string.lower(namaBarang)) and string.find(txt, "stok:") then
                                gui.Enabled = false
                                clickGuiButton(v)
                                task.wait(0.2)
                                for _, btn2 in ipairs(gui:GetDescendants()) do
                                    if btn2:IsA("GuiButton") then
                                        local txt2 = string.lower(btn2.Name)
                                        if btn2:IsA("TextButton") then txt2 = txt2 .. " " .. string.lower(btn2.Text) end
                                        if string.find(txt2, "max") or string.find(txt2, ">>") or string.find(txt2, "kirim") or string.find(txt2, "jual") then
                                            clickGuiButton(btn2)
                                        end
                                    end
                                end
                                task.wait(0.2)
                                for _, closeBtn in ipairs(gui:GetDescendants()) do
                                    if closeBtn:IsA("GuiButton") and (string.find(string.lower(closeBtn.Name), "close") or (closeBtn:IsA("TextButton") and string.find(string.lower(closeBtn.Text), "x"))) then
                                        clickGuiButton(closeBtn)
                                    end
                                end
                                task.wait(0.1)
                                gui.Enabled = true
                                logAction("Siluman", true, "Sukses menjual " .. namaBarang .. " secara ghaib!")
                                return
                            end
                        end
                    end
                end
            end
        end
        logAction("Siluman", false, "Gagal menemukan " .. namaBarang .. " di Truk")
    end)
end

local function produksiPabrikSiluman(namaBarang)
    if not namaBarang or namaBarang == "" then return end
    task.spawn(function()
        local fired = false
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local act = string.lower(prompt.ActionText or "")
                local obj = string.lower(prompt.ObjectText or "")
                if string.find(act, "kelola") or string.find(obj, "pabrik") or string.find(act, "produksi") or string.find(act, "buka") then
                    prompt.RequiresLineOfSight = false
                    if fireproximityprompt then fireproximityprompt(prompt) end
                    fired = true
                    break
                end
            end
        end
        if not fired then logAction("Siluman", false, "Gagal menemukan mesin pabrik") return end
        
        task.wait(0.5)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not string.find(string.lower(gui.Name), "windui") and not string.find(string.lower(gui.Name), "panda") then
                    for _, v in ipairs(gui:GetDescendants()) do
                        if v:IsA("GuiButton") then
                            local txt = string.lower(v.Name)
                            if v:IsA("TextButton") then txt = txt .. " " .. string.lower(v.Text) end
                            for _, child in ipairs(v:GetDescendants()) do 
                                if child:IsA("TextLabel") or child:IsA("TextBox") then txt = txt .. " " .. string.lower(child.Text) end
                            end
                            if string.find(txt, string.lower(namaBarang)) then
                                gui.Enabled = false
                                clickGuiButton(v)
                                task.wait(0.2)
                                
                                -- 1. Klik Max / >> terlebih dahulu
                                for _, btn2 in ipairs(gui:GetDescendants()) do
                                    if btn2:IsA("GuiButton") then
                                        local txt2 = string.lower(btn2.Name)
                                        if btn2:IsA("TextButton") then txt2 = txt2 .. " " .. string.lower(btn2.Text) end
                                        if string.find(txt2, "max") or string.find(txt2, ">>") then
                                            clickGuiButton(btn2)
                                        end
                                    end
                                end
                                task.wait(0.2)
                                
                                -- 2. Klik Produksi / Ambil
                                for _, btn2 in ipairs(gui:GetDescendants()) do
                                    if btn2:IsA("GuiButton") then
                                        local txt2 = string.lower(btn2.Name)
                                        if btn2:IsA("TextButton") then txt2 = txt2 .. " " .. string.lower(btn2.Text) end
                                        if string.find(txt2, "produksi") or string.find(txt2, "ambil") or string.find(txt2, "buat") then
                                            clickGuiButton(btn2)
                                        end
                                    end
                                end
                                task.wait(0.2)
                                for _, closeBtn in ipairs(gui:GetDescendants()) do
                                    if closeBtn:IsA("GuiButton") and (string.find(string.lower(closeBtn.Name), "close") or (closeBtn:IsA("TextButton") and string.find(string.lower(closeBtn.Text), "x"))) then
                                        clickGuiButton(closeBtn)
                                    end
                                end
                                task.wait(0.1)
                                gui.Enabled = true
                                logAction("Siluman", true, "Sukses Produksi/Ambil " .. namaBarang .. " secara ghaib!")
                                return
                            end
                        end
                    end
                end
            end
        end
        logAction("Siluman", false, "Gagal menemukan " .. namaBarang .. " di Pabrik")
    end)
end

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
local TabToko = Window:Tab({ Title = "Toko Siluman", Icon = "shopping-cart" })

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

TabFarm:Button({
    Title = "⚔️ Kick/Crash Target (Troll)",
    Callback = function()
        local targetName = _G_State.BantuTargets and _G_State.BantuTargets[1]
        if not targetName or targetName == "" then
            logAction("Admin", false, "Pilih target pemain di dropdown atas terlebih dahulu!")
            return
        end
        
        local p = nil
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if string.lower(player.Name) == string.lower(targetName) or string.lower(player.DisplayName) == string.lower(targetName) then
                p = player
                break
            end
        end
        
        if p then
            logAction("Admin", true, "Mencoba menendang/mem-fling " .. p.Name)
            task.spawn(function()
                -- 1. Coba Admin Remote Server (Jika ada celah keamanan)
                local rs = game:GetService("ReplicatedStorage")
                local admin = rs:FindFirstChild("AdminRemote") or rs:FindFirstChild("Admin") or rs:FindFirstChild("ReportSubmitted")
                if admin and admin:IsA("RemoteFunction") then
                    pcall(function() admin:InvokeServer("Kick", p.Name, "Kicked by Panda Industri Pro") end)
                    pcall(function() admin:InvokeServer("Ban", p.Name) end)
                elseif admin and admin:IsA("RemoteEvent") then
                    pcall(function() admin:FireServer("Kick", p.Name, "Kicked by Panda Industri Pro") end)
                end
                
                -- 2. Physical Crash / Fling-Kill (Paling Ampuh)
                local char = LocalPlayer.Character
                local eChar = p.Character
                if char and eChar and char:FindFirstChild("HumanoidRootPart") and eChar:FindFirstChild("HumanoidRootPart") then
                    local myHrp = char.HumanoidRootPart
                    local eHrp = eChar.HumanoidRootPart
                    local oldCf = myHrp.CFrame
                    
                    local flingForce = Instance.new("BodyAngularVelocity")
                    flingForce.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    flingForce.AngularVelocity = Vector3.new(0, 99999, 0)
                    flingForce.Parent = myHrp
                    
                    for i = 1, 20 do
                        if eChar and eChar:FindFirstChild("HumanoidRootPart") then
                            myHrp.CFrame = eChar.HumanoidRootPart.CFrame
                            myHrp.Velocity = Vector3.new(0, 0, 0)
                        end
                        task.wait(0.05)
                    end
                    
                    if flingForce then flingForce:Destroy() end
                    myHrp.CFrame = oldCf
                    myHrp.Velocity = Vector3.new(0,0,0)
                    logAction("Admin", true, "Crash/Fling selesai dikirim ke " .. p.Name)
                end
            end)
        else
            logAction("Admin", false, "Pemain tidak ditemukan/sudah keluar!")
        end
    end
})

TabFarm:Dropdown({
    Title = "Mode Penjualan (Truk Jual)",
    Desc = "Pilih kategori barang yang ingin dijual",
    Options = {"Mati", "Jual Semua (Mentah & Olahan)", "Jual Mentah Saja", "Jual Olahan Saja"},
    Default = "Mati",
    Callback = function(val)
        local mode = val or "Mati"
        _G_State.DeliveryMode = mode
        _G_State.AutoDelivery = (mode ~= "Mati")
        logAction("Menu -> Mode Penjualan", true, tostring(mode))
    end
})

local DeliveryList = {"Truk (Belum Dimuat)"}
local DeliveryPrompts = {} -- Menyimpan referensi prompt asli

local DeliveryDropdown = TabFarm:Dropdown({
    Title = "Pilih Pengiriman (Scan Map)",
    Desc = "Klik Refresh di bawah jika kosong",
    Options = DeliveryList,
    Default = "Truk (Belum Dimuat)",
    Callback = function(val) _G_State.SelectedDeliveryUI = val end
})

TabFarm:Button({
    Title = "🔄 Refresh Daftar Pengiriman",
    Callback = function()
        DeliveryList = {}
        DeliveryPrompts = {}
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local pName = string.lower(prompt.Parent and prompt.Parent.Name or "")
                local act = string.lower(prompt.ActionText or "")
                
                -- Cari kata kunci yang berhubungan dengan penjualan/pengiriman
                if string.find(pName, "delivery") or string.find(act, "jual") or string.find(act, "kirim") or string.find(pName, "sell") then
                    local dName = prompt.ObjectText
                    if not dName or dName == "" then dName = prompt.Parent.Name end
                    if dName ~= "" and not table.find(DeliveryList, dName) then
                        table.insert(DeliveryList, dName)
                        DeliveryPrompts[dName] = prompt
                    end
                end
            end
        end
        if #DeliveryList == 0 then table.insert(DeliveryList, "Tidak Ditemukan") end
        
        if DeliveryDropdown and DeliveryDropdown.Refresh then
            DeliveryDropdown:Refresh(DeliveryList)
        end
        logAction("Manual", true, "Menemukan " .. #DeliveryList .. " Tempat Jual")
    end
})

TabFarm:Button({
    Title = "🚚 Buka UI Jual Ini (Jarak Jauh)",
    Callback = function()
        local dName = _G_State.SelectedDeliveryUI
        if dName and DeliveryPrompts[dName] then
            local prompt = DeliveryPrompts[dName]
            prompt.RequiresLineOfSight = false
            if fireproximityprompt then fireproximityprompt(prompt) end
            logAction("Manual", true, "Membuka UI: " .. dName)
        else
            logAction("Manual", false, "Pengiriman belum dipilih atau coba Refresh")
        end
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

local FactoryList = {"Pabrik (Belum Dimuat)"}
local FactoryPrompts = {} -- Menyimpan referensi prompt asli

local FactoryDropdown = TabFactory:Dropdown({
    Title = "Pilih Pabrik (Scan Map)",
    Desc = "Klik Refresh di bawah jika kosong",
    Options = FactoryList,
    Default = "Pabrik (Belum Dimuat)",
    Callback = function(val) _G_State.SelectedFactoryUI = val end
})

TabFactory:Button({
    Title = "🔄 Refresh Daftar Pabrik",
    Callback = function()
        FactoryList = {}
        FactoryPrompts = {}
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local act = string.lower(prompt.ActionText or "")
                local obj = string.lower(prompt.ObjectText or "")
                local pName = prompt.Parent and prompt.Parent.Name or ""
                
                if string.find(act, "kelola") or string.find(obj, "pabrik") or string.find(act, "produksi") or string.find(string.lower(pName), "factory") then
                    local fName = prompt.ObjectText
                    if not fName or fName == "" then fName = pName end
                    if fName ~= "" and not table.find(FactoryList, fName) then
                        table.insert(FactoryList, fName)
                        FactoryPrompts[fName] = prompt
                    end
                end
            end
        end
        if #FactoryList == 0 then table.insert(FactoryList, "Tidak Ditemukan") end
        
        if FactoryDropdown and FactoryDropdown.Refresh then
            FactoryDropdown:Refresh(FactoryList)
        end
        logAction("Manual", true, "Menemukan " .. #FactoryList .. " Pabrik")
    end
})

TabFactory:Button({
    Title = "🏭 Buka UI Pabrik Ini (Jarak Jauh)",
    Callback = function()
        local fName = _G_State.SelectedFactoryUI
        if fName and FactoryPrompts[fName] then
            local prompt = FactoryPrompts[fName]
            prompt.RequiresLineOfSight = false
            if fireproximityprompt then fireproximityprompt(prompt) end
            logAction("Manual", true, "Membuka UI: " .. fName)
        else
            logAction("Manual", false, "Pabrik belum dipilih atau coba Refresh")
        end
    end
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

-- === TAB TOKO SILUMAN ===
local BarangMentah = {"Telur", "Susu", "Wol", "Bacon", "Gandum", "Tomat", "Wortel", "Tebu"}
local BarangOlahan = {"Tepung", "Roti", "Benang", "Kain", "Baju", "Keju", "Mentega", "Krim", "Selai", "Kue", "Sirup", "Gula", "Minyak", "Sosis", "Burger", "Pancake", "Waffle"}

_G_State.SelectedMentah = "Telur"
_G_State.SelectedOlahan = "Tepung"
_G_State.SelectedPabrik = "Tepung"

TabToko:Dropdown({
    Title = "Jual Barang Mentah",
    Desc = "Pilih hasil tani/hewan mentah",
    Options = BarangMentah,
    Default = "Telur",
    Callback = function(val) _G_State.SelectedMentah = val or "Telur" end
})
TabToko:Button({
    Title = "💰 Jual Semua Mentah Ini (Siluman)",
    Callback = function() jualSiluman(_G_State.SelectedMentah) end
})

TabToko:Dropdown({
    Title = "Jual Barang Olahan",
    Desc = "Pilih hasil dari mesin pabrik",
    Options = BarangOlahan,
    Default = "Tepung",
    Callback = function(val) _G_State.SelectedOlahan = val or "Tepung" end
})
TabToko:Button({
    Title = "💰 Jual Semua Olahan Ini (Siluman)",
    Callback = function() jualSiluman(_G_State.SelectedOlahan) end
})

TabToko:Dropdown({
    Title = "Produksi & Ambil (Pabrik)",
    Desc = "Pilih barang yang ingin diproduksi di pabrik",
    Options = BarangOlahan,
    Default = "Tepung",
    Callback = function(val) _G_State.SelectedPabrik = val or "Tepung" end
})
TabToko:Button({
    Title = "🏭 Proses Pabrik Ini (Siluman)",
    Callback = function() produksiPabrikSiluman(_G_State.SelectedPabrik) end
})

TabToko:Toggle({
    Title = "Auto Proses Pabrik Ini (Loop)",
    Desc = "Otomatis melakukan Pabrik Siluman setiap 5 detik di background",
    Default = false,
    Callback = function(state) _G_State.AutoPabrikSiluman = state; logAction("Menu -> Auto Pabrik Siluman", true, state and "AKTIF" or "MATI") end
})

-- === TAB UPGRADE & TOKO ===
TabUpgrade:Button({Title = "🛒 Buka Toko Utama (Shop)", Callback = function() firePromptByName("OpenShop", "Membuka Toko Utama") end})
TabUpgrade:Button({Title = "🎩 Buka Toko Skin (Alat)", Callback = function() firePromptByName("OpenSkinShop", "Membuka Toko Alat/Skin") end})
TabUpgrade:Button({Title = "🎒 Buka Upgrade Gudang (Barn)", Callback = function() firePromptByName("UpgradeBarn", "Membuka Upgrade Gudang") end})
TabUpgrade:Button({Title = "🚚 Buka Upgrade Truk (Delivery)", Callback = function() firePromptByName("UpgradeDelivery", "Membuka Upgrade Truk") end})
TabUpgrade:Button({Title = "💧 Buka Upgrade Sumur (Well)", Callback = function() firePromptByName("UpgradeWell", "Membuka Upgrade Sumur") end})
TabUpgrade:Button({Title = "⭐ Buka Skill Mastery", Callback = function() firePromptByName("OpenMastery", "Membuka UI Mastery") end})

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
