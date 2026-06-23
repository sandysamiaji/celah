-- ============================================================
-- Panda Industri - Auto Farm & Factory (Mr. Panda)
-- V2: Smart Supply Chain & Multi-Processing
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variabel Toggle
local _G_State = {}
_G_State.AutoRefill = false
_G_State.AutoDelivery = false
_G_State.AutoFactory = false
_G_State.AutoBuyAnimal = false
_G_State.AutoCollect = false
_G_State.AutoUpgradeUniversal = false
_G_State.AutoUpgradeFactory = false
_G_State.AutoBuyMastery = false
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
-- SYSTEM LOGGING (Memory-based)
-- ============================================================
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
    
    -- Tulis ke memori (Tanpa pakai file .txt yang ribet di Android)
    _G_State.LiveLogs = _G_State.LiveLogs .. fullMsg .. "\n"
    
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
-- SMART DELIVERY HOOK (Jual HANYA saat tas penuh)
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
        -- UI CLICKER UNIVERSAL (Bypass tanpa harus buka menu)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in ipairs(pGui:GetDescendants()) do
                if v:IsA("GuiButton") then
                    local txt = string.lower(v.Name)
                    if v:IsA("TextButton") then txt = txt .. " " .. string.lower(v.Text) end
                    for _, child in ipairs(v:GetChildren()) do
                        if child:IsA("TextLabel") then txt = txt .. " " .. string.lower(child.Text) end
                    end
                    
                    -- 1. Auto Delivery (Jual)
                    if _G_State.AutoDelivery and (txt == ">>" or string.find(txt, "kirim") or string.find(txt, "max")) then
                        clickGuiButton(v)
                    end
                    
                    -- 2. Auto Factory (Produksi & Ambil Hasil)
                    if _G_State.AutoFactory and (string.find(txt, "produksi") or string.find(txt, "ambil")) then
                        clickGuiButton(v)
                    end
                    
                    -- 3. Auto Upgrade Semua UI (Pabrik, Kandang, Sumur, Kendaraan & Hewan)
                    if _G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory or _G_State.AutoBuyAnimal then
                        if string.find(txt, "rp") then
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
                                -- Bukan hewan, berarti ini upgrade (Kandang, Sumur, Pabrik, Kendaraan)
                                shouldBuy = (_G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory)
                            end
                            
                            if shouldBuy then clickGuiButton(v) end
                        end
                    end
                end
            end
        end
        
        -- Fallback Remote Auto Delivery
        if _G_State.AutoDelivery then
            -- Coba klik ProximityPrompt "Jual" jika ada di dekat player
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and string.find(string.lower(prompt.ActionText or ""), "jual") then
                        pcall(function()
                            prompt.RequiresLineOfSight = false
                            if fireproximityprompt then fireproximityprompt(prompt) end
                        end)
                    end
                end
            end
            
            local sellRemote = RS:FindFirstChild("RequestSendDelivery")
            if sellRemote then pcall(function() sellRemote:InvokeServer() end) end
        end
    end
end)

-- ============================================================
-- Looping Utama (Berjalan di background)
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        -- 1. Auto Refill Air & 6. Auto Collect (Aman dari Error 277 / Disconnect)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- A. Auto Refill Air (Cooldown 2 Detik agar sinkron dengan kecepatan ambil barang)
            if _G_State.AutoRefill and (not _G_State.LastRefill or tick() - _G_State.LastRefill > 2) then
                local wellFound = false
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = prompt.ActionText or ""
                        local obj = prompt.ObjectText or ""
                        if string.find(obj, "Isi Air") or string.find(act, "Isi Air") or (string.find(act, "Ambil") and string.find(prompt.Parent.Name, "Sumur")) then
                            pcall(function()
                                local pos = prompt.Parent.Position
                                if (hrp.Position - pos).Magnitude > 10 then
                                    hrp.CFrame = prompt.Parent.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.5) -- Anti Error 277
                                    logAction("Auto Refill -> Teleport", true, string.format("Ke Sumur di X:%.0f, Y:%.0f, Z:%.0f", pos.X, pos.Y, pos.Z))
                                end
                                prompt.RequiresLineOfSight = false
                                if fireproximityprompt then fireproximityprompt(prompt) end
                                logAction("Auto Refill -> ProximityPrompt", true, "Berhasil klik Sumur!")
                            end)
                            _G_State.LastRefill = tick()
                            wellFound = true
                            break -- HANYA 1 SUMUR! (Jangan loop ke sumur lain)
                        end
                    end
                end
                if wellFound then task.wait(0.5) end -- Beri jeda sebelum collect barang
            end
            
            -- B. Auto Collect Barang (Hanya ambil 1 barang per loop = Anti Spam)
            if _G_State.AutoCollect then
                if not _G_State.CollectedItems then _G_State.CollectedItems = {} end
                
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
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
                    local act = string.lower(prompt.ActionText or "")
                    local obj = string.lower(prompt.ObjectText or "")
                    
                    local isUpgrade = (_G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory) and (string.find(act, "tingkat") or string.find(act, "upgrade") or string.find(act, "buka"))
                    local isBuyAyam = _G_State.AutoBuyAnimal and _G_State.BuyAyam and (string.find(obj, "ayam") or string.find(act, "ayam")) and string.find(act, "beli")
                    local isBuySapi = _G_State.AutoBuyAnimal and _G_State.BuySapi and (string.find(obj, "sapi") or string.find(act, "sapi")) and string.find(act, "beli")
                    local isBuyDomba = _G_State.AutoBuyAnimal and _G_State.BuyDomba and (string.find(obj, "domba") or string.find(act, "domba")) and string.find(act, "beli")
                    local isBuyBabi = _G_State.AutoBuyAnimal and _G_State.BuyBabi and (string.find(obj, "babi") or string.find(act, "babi")) and string.find(act, "beli")
                    
                    if isUpgrade or isBuyAyam or isBuySapi or isBuyDomba or isBuyBabi then
                        -- Cooldown 30 detik agar tidak nyangkut teleport ke tempat yang sama karena uang tidak cukup
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
    Title = "Auto Jual Pintar (Smart Delivery)",
    Desc = "Menjual HANYA saat tas kepenuhan, agar mesin sempat menyedot bahan",
    Default = false,
    Callback = function(state) _G_State.AutoDelivery = state; logAction("Menu -> Smart Delivery", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Auto Collect Barang (Magnet)",
    Desc = "Menarik Telur, Wol, Susu, dll ke badan",
    Default = false,
    Callback = function(state) _G_State.AutoCollect = state; logAction("Menu -> Auto Collect", true, state and "AKTIF" or "MATI") end
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
    Callback = function(state) _G_State.LogEnabled = state end
})

local LogDisplay = TabLogs:Button({
    Title = "Aktivitas Terakhir:",
    Desc = "Belum ada aktivitas...",
    Callback = function() end
})

-- Hubungkan fungsi update ke UI
_G_State.UpdateUIDisplay = function(newMsg)
    if LogDisplay and LogDisplay.Set then
        LogDisplay:Set({Desc = newMsg})
    elseif LogDisplay and LogDisplay.SetDesc then
        LogDisplay:SetDesc(newMsg)
    end
end

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
        lastLogs = {}
        if _G_State.UpdateUIDisplay then _G_State.UpdateUIDisplay("Belum ada aktivitas...") end
        windui:Notify({Title="Dibersihkan!", Content="Log memori sudah dihapus.", Duration=3})
    end
})

-- Matikan UI overlay jika masih nyala dari script sebelumnya
pcall(function() game:GetService("CoreGui").MrPandaLiveLogs:Destroy() end)

windui:Notify({
    Title = "Mr. Panda Loaded!",
    Content = "Sistem Live Log Memory Aktif!",
    Duration = 5
})
