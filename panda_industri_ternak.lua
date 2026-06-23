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
-- SYSTEM LOGGING (Anti-Spam & Auto-Save ke .txt)
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
    
    -- Tulis ke file secara terus menerus
    pcall(function()
        local paths = {
            "/sdcard/Download/Panda_Log.txt", 
            "/sdcard/Android/data/com.roblox.client/files/Panda_Log.txt",
            "/sdcard/Android/data/com.roblox.client/files/workspace/Panda_Log.txt",
            "Panda_Log.txt"
        }
        for _, path in ipairs(paths) do
            local success = pcall(function()
                if not isfile(path) then
                    writefile(path, "=== PANDA INDUSTRI LOGS ===\n")
                end
                appendfile(path, fullMsg .. "\n")
            end)
            if success then break end
        end
    end)
end

local function safeInvoke(remote, actionName, ...)
    local s, r = pcall(function(...) return remote:InvokeServer(...) end, ...)
    if s then
        -- Anggap gagal jika server mengembalikan false, nil, atau pesan error umum
        if r == false or r == nil or r == "Error" or r == "AlreadyFull" then
            -- logAction(actionName, false, r or "Ditolak Server") -- (Opsional: Matikan jika tidak mau log GAGAL penuh)
        else
            logAction(actionName, true, r)
        end
    else
        logAction(actionName, false, "ERROR SCRIPT: " .. tostring(r))
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
                        logAction("Auto Delivery", true, "Mencoba Menjual Karena Tas Penuh")
                        safeInvoke(sellRemote, "RequestSendDelivery")
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
            end
        end
        
        -- 2. Auto Factory (BRUTE-FORCE SEMUA RESEP SEKALIGUS!)
        if _G_State.AutoFactory then
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local startR = remotes:FindFirstChild("RequestStartProduction")
                local claimR = remotes:FindFirstChild("RequestClaimProduction")
                for _, recipe in ipairs(AllRecipes) do
                    if startR then task.spawn(function() safeInvoke(startR, "Pabrik_Start_"..recipe, recipe) end) end
                    if claimR then task.spawn(function() safeInvoke(claimR, "Pabrik_Claim_"..recipe, recipe) end) end
                end
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
            end
        end

        -- 5. Auto Upgrades
        if _G_State.AutoUpgradeUniversal then
            local remote = RS:FindFirstChild("RequestUniversalUpgrade")
            if remote then task.spawn(function() safeInvoke(remote, "Up_Universal") end) end
        end
        if _G_State.AutoBuyMastery then
            local remote = RS:FindFirstChild("RequestBuyFarmMastery")
            if remote then task.spawn(function() safeInvoke(remote, "Up_Mastery") end) end
        end
        if _G_State.AutoUpgradeFactory then
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local uF = remotes:FindFirstChild("RequestUnlockFactory")
                local upF = remotes:FindFirstChild("RequestFactoryUpgrade")
                for _, recipe in ipairs(AllRecipes) do
                    if uF then task.spawn(function() safeInvoke(uF, "UnlockPabrik_"..recipe, recipe) end) end
                    if upF then task.spawn(function() safeInvoke(upF, "UpPabrik_"..recipe, recipe) end) end
                end
            end
        end
        
        -- 6. Auto Collect (Magnet) berjalan tiap ~1 detik
        tickCollect = tickCollect + 0.5
        if _G_State.AutoCollect and tickCollect >= 1.5 then
            tickCollect = 0
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
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
                        end
                    end
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
    Icon = "rbxassetid://10618928818",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 380),
    Transparent = false
})

local TabFarm = Window:AddTab({ Title = "Farming", Icon = "rbxassetid://10618928818" })
local TabFactory = Window:AddTab({ Title = "Factory", Icon = "rbxassetid://10618928818" })
local TabAnimal = Window:AddTab({ Title = "Animals", Icon = "rbxassetid://10618928818" })
local TabUpgrade = Window:AddTab({ Title = "Upgrades", Icon = "rbxassetid://10618928818" })
local TabLogs = Window:AddTab({ Title = "Logs", Icon = "rbxassetid://10618928818" })

-- === TAB FARMING ===
TabFarm:AddToggle({
    Title = "Auto Refill Water",
    Desc = "Otomatis mengisi air di Gembor",
    Default = false,
    Callback = function(state) _G_State.AutoRefill = state end
})

TabFarm:AddToggle({
    Title = "Auto Jual Pintar (Smart Delivery)",
    Desc = "Menjual HANYA saat tas kepenuhan, agar mesin sempat menyedot bahan",
    Default = false,
    Callback = function(state) _G_State.AutoDelivery = state end
})

TabFarm:AddToggle({
    Title = "Auto Collect Barang (Magnet)",
    Desc = "Menarik Telur, Wol, Susu, dll ke badan",
    Default = false,
    Callback = function(state) _G_State.AutoCollect = state end
})

-- === TAB FACTORY ===
TabFactory:AddToggle({
    Title = "Auto Proses SEMUA Mesin!",
    Desc = "Otomatis memproses & mengambil hasil dari SEMUA mesin sekaligus (Telur, Wol, Susu, dll)",
    Default = false,
    Callback = function(state) _G_State.AutoFactory = state end
})

-- === TAB ANIMAL ===
TabAnimal:AddToggle({
    Title = "Aktifkan Auto Beli",
    Desc = "Mulai membeli hewan yang dicentang di bawah",
    Default = false,
    Callback = function(state) _G_State.AutoBuyAnimal = state end
})
TabAnimal:AddToggle({ Title = "Beli Ayam", Default = false, Callback = function(state) _G_State.BuyAyam = state end })
TabAnimal:AddToggle({ Title = "Beli Sapi", Default = false, Callback = function(state) _G_State.BuySapi = state end })
TabAnimal:AddToggle({ Title = "Beli Domba", Default = false, Callback = function(state) _G_State.BuyDomba = state end })
TabAnimal:AddToggle({ Title = "Beli Babi", Default = false, Callback = function(state) _G_State.BuyBabi = state end })

-- === TAB UPGRADE ===
TabUpgrade:AddToggle({
    Title = "Auto Universal Upgrade",
    Desc = "Otomatis membeli upgrade seperti Tas, Kecepatan, Air",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeUniversal = state end
})

TabUpgrade:AddToggle({
    Title = "Auto Upgrade & Unlock Pabrik",
    Desc = "Membuka mesin baru dan meng-upgrade semua mesin",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeFactory = state end
})

TabUpgrade:AddToggle({
    Title = "Auto Farm Mastery",
    Desc = "Otomatis level up Mastery / Skill memanen",
    Default = false,
    Callback = function(state) _G_State.AutoBuyMastery = state end
})

-- === TAB LOGS ===
TabLogs:AddButton({
    Title = "Copy Semua Log ke Clipboard",
    Desc = "Menyalin isi file Panda_Log.txt untuk di-paste",
    Callback = function()
        pcall(function()
            local content = ""
            local paths = {
                "/sdcard/Download/Panda_Log.txt", 
                "/sdcard/Android/data/com.roblox.client/files/Panda_Log.txt",
                "/sdcard/Android/data/com.roblox.client/files/workspace/Panda_Log.txt",
                "Panda_Log.txt"
            }
            for _, path in ipairs(paths) do
                if isfile(path) then
                    content = readfile(path)
                    break
                end
            end
            
            if content ~= "" then
                setclipboard(content)
                windui:Notify({Title="Copied!", Content="Log berhasil disalin ke Clipboard!", Duration=3})
            else
                windui:Notify({Title="Kosong", Content="Belum ada log yang tersimpan.", Duration=3})
            end
        end)
    end
})

TabLogs:AddButton({
    Title = "Hapus Log (Clear)",
    Desc = "Menghapus file log agar memori tidak penuh",
    Callback = function()
        pcall(function() writefile("/sdcard/Download/Panda_Log.txt", "=== PANDA INDUSTRI LOGS ===\n") end)
        pcall(function() writefile("/sdcard/Android/data/com.roblox.client/files/Panda_Log.txt", "=== PANDA INDUSTRI LOGS ===\n") end)
        pcall(function() writefile("/sdcard/Android/data/com.roblox.client/files/workspace/Panda_Log.txt", "=== PANDA INDUSTRI LOGS ===\n") end)
        pcall(function() writefile("Panda_Log.txt", "=== PANDA INDUSTRI LOGS ===\n") end)
        lastLogs = {}
        windui:Notify({Title="Cleared!", Content="File log berhasil dibersihkan.", Duration=3})
    end
})

windui:Notify({
    Title = "Mr. Panda Loaded!",
    Content = "Sistem Logging .txt Aktif!",
    Duration = 5
})
