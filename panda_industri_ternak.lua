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
    -- Ubah format data menjadi string yang mudah dibaca
    if type(detail) == "table" then detail = "Table/Array" end
    local status = isSuccess and "SUKSES" or "GAGAL"
    local msg = string.format("[%s] %s | %s", status, action, tostring(detail))
    
    -- Anti-Spam: Jangan catat log yang persis sama berturut-turut untuk action yang sama
    if lastLogs[action] == msg then return end
    lastLogs[action] = msg

    local fullMsg = os.date("%H:%M:%S") .. " " .. msg
    
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
task.spawn(function()
    local notifyRemote = RS:WaitForChild("NotifyClientEvent", 10)
    if notifyRemote then
        notifyRemote.OnClientEvent:Connect(function(msg, msgType)
            if _G_State.AutoDelivery and type(msg) == "string" then
                -- Jika ada notifikasi penuh dan BUKAN penuh air
                if string.find(string.lower(msg), "penuh") and not string.find(string.lower(msg), "gembor") and not string.find(string.lower(msg), "air") then
                    local sellRemote = RS:FindFirstChild("RequestSendDelivery")
                    if sellRemote then
                        logAction("Auto Delivery -> RequestSendDelivery", true, "Mencoba Menjual Karena Tas Penuh")
                        safeInvoke(sellRemote, "Auto Delivery")
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- Looping Utama (Berjalan di background)
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        -- 1. Auto Refill Air
        if _G_State.AutoRefill then
            local tool = getTool("Watering Can")
            if tool and tool:FindFirstChild("WaterRemote") then
                pcall(function() tool.WaterRemote:FireServer() end)
                logAction("Auto Refill -> WaterRemote", true, "Menembak FireServer()")
            else
                logAction("Auto Refill -> ???", false, "Alat 'Watering Can' tidak ditemukan di tas atau tangan!")
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

        -- 5. Auto Upgrades
        if _G_State.AutoUpgradeUniversal then
            local remote = RS:FindFirstChild("RequestUniversalUpgrade")
            if remote then task.spawn(function() safeInvoke(remote, "Up_Universal") end) 
            else logAction("Auto Upgrade", false, "Remote RequestUniversalUpgrade tidak ditemukan!") end
        end
        if _G_State.AutoBuyMastery then
            local remote = RS:FindFirstChild("RequestBuyFarmMastery")
            if remote then task.spawn(function() safeInvoke(remote, "Up_Mastery") end)
            else logAction("Auto Mastery", false, "Remote RequestBuyFarmMastery tidak ditemukan!") end
        end
        if _G_State.AutoUpgradeFactory then
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local uF = remotes:FindFirstChild("RequestUnlockFactory")
                local upF = remotes:FindFirstChild("RequestFactoryUpgrade")
                if uF and upF then
                    for _, recipe in ipairs(AllRecipes) do
                        task.spawn(function() safeInvoke(uF, "UnlockPabrik_"..recipe, recipe) end)
                        task.spawn(function() safeInvoke(upF, "UpPabrik_"..recipe, recipe) end)
                    end
                else
                    logAction("Auto UpFactory", false, "Remote UnlockFactory/UpgradeFactory tidak ditemukan!")
                end
            end
        end
        
        -- 6. Auto Collect (Magnet) berjalan tiap ~1 detik
        tickCollect = tickCollect + 0.5
        if _G_State.AutoCollect and tickCollect >= 1.5 then
            tickCollect = 0
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local collected = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v:FindFirstChild("TouchInterest") then
                        if not v.Parent:FindFirstChild("Humanoid") then
                            pcall(function()
                                v.CFrame = hrp.CFrame
                                if firetouchinterest then
                                    firetouchinterest(hrp, v, 0)
                                    firetouchinterest(hrp, v, 1)
                                end
                            end)
                            collected = collected + 1
                        end
                    end
                end
                if collected > 0 then
                    logAction("Auto Collect -> firetouchinterest", true, "Menarik " .. tostring(collected) .. " barang!")
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
    Callback = function(state) _G_State.AutoRefill = state end
})

TabFarm:Toggle({
    Title = "Auto Jual Pintar (Smart Delivery)",
    Desc = "Menjual HANYA saat tas kepenuhan, agar mesin sempat menyedot bahan",
    Default = false,
    Callback = function(state) _G_State.AutoDelivery = state end
})

TabFarm:Toggle({
    Title = "Auto Collect Barang (Magnet)",
    Desc = "Menarik Telur, Wol, Susu, dll ke badan",
    Default = false,
    Callback = function(state) _G_State.AutoCollect = state end
})

-- === TAB FACTORY ===
TabFactory:Toggle({
    Title = "Auto Proses SEMUA Mesin!",
    Desc = "Otomatis memproses & mengambil hasil dari SEMUA mesin sekaligus",
    Default = false,
    Callback = function(state) _G_State.AutoFactory = state end
})

-- === TAB ANIMAL ===
TabAnimal:Toggle({
    Title = "Aktifkan Auto Beli",
    Desc = "Mulai membeli hewan yang dicentang di bawah",
    Default = false,
    Callback = function(state) _G_State.AutoBuyAnimal = state end
})
TabAnimal:Toggle({ Title = "Beli Ayam", Default = false, Callback = function(state) _G_State.BuyAyam = state end })
TabAnimal:Toggle({ Title = "Beli Sapi", Default = false, Callback = function(state) _G_State.BuySapi = state end })
TabAnimal:Toggle({ Title = "Beli Domba", Default = false, Callback = function(state) _G_State.BuyDomba = state end })
TabAnimal:Toggle({ Title = "Beli Babi", Default = false, Callback = function(state) _G_State.BuyBabi = state end })

-- === TAB UPGRADE ===
TabUpgrade:Toggle({
    Title = "Auto Universal Upgrade",
    Desc = "Otomatis membeli upgrade seperti Tas, Kecepatan, Air",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeUniversal = state end
})

TabUpgrade:Toggle({
    Title = "Auto Upgrade & Unlock Pabrik",
    Desc = "Membuka mesin baru dan meng-upgrade semua mesin",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeFactory = state end
})

TabUpgrade:Toggle({
    Title = "Auto Farm Mastery",
    Desc = "Otomatis level up Mastery / Skill memanen",
    Default = false,
    Callback = function(state) _G_State.AutoBuyMastery = state end
})

-- === TAB LOGS ===
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
