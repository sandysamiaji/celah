-- ============================================================
-- Panda Industri - Auto Farm & Factory (Mr. Panda)
-- V3: Fully Optimized Admin Edition (Bypass & Fixed)
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variabel Toggle & Eksekusi
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

-- Konfigurasi Kustom Admin (Request User)
_G_State.MonsterRadius = 250   -- Area Hit Werewolf (Bisa Anda ubah sesuka hati)
_G_State.AttackSpeed = 0.2     -- Kecepatan spam hit Serigala (0.2 detik)
_G_State.GlobalRange = true    -- Bypass Jarak Jauh (Ambil barang & air dari mana saja)

-- Animal toggles
_G_State.BuyAyam = false
_G_State.BuySapi = false
_G_State.BuyDomba = false
_G_State.BuyBabi = false

-- Daftar Semua Kemungkinan Resep Pabrik
local AllRecipes = {
    "Tepung", "Roti", "Benang", "Kain", "Baju",
    "Keju", "Mentega", "Krim", "Selai", "Kue",
    "Sirup", "Gula", "Minyak", "Sosis", "Burger",
    "Pancake", "Waffle"
}

-- Fungsi Utility untuk Mencari Item
local function getTool(name)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild(name) then return char[name] end
    if LocalPlayer.Backpack:FindFirstChild(name) then return LocalPlayer.Backpack[name] end
    return nil
end

-- ============================================================
-- SYSTEM LOGGING (Buffer & Webhook)
-- ============================================================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local http_request = request or http_request or (http and http.request) or syn and syn.request
local logBuffer = {}

local function sendBufferedLogs()
    if #logBuffer == 0 then return end
    if not http_request then return end
    
    local combinedLogs = table.concat(logBuffer, "\n")
    logBuffer = {}
    
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

task.spawn(function()
    while task.wait(5) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        sendBufferedLogs()
    end
end)

local lastLogs = {}
local function logAction(action, isSuccess, detail)
    if not _G_State.LogEnabled then return end
    if type(detail) == "table" then detail = "Table/Array" end
    local status = isSuccess and "SUKSES" or "GAGAL"
    local msg = string.format("[%s] %s | %s", status, action, tostring(detail))
    
    if lastLogs[action] == msg then return end
    lastLogs[action] = msg

    local fullMsg = os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg
    _G_State.LiveLogs = _G_State.LiveLogs .. fullMsg .. "\n"
    table.insert(logBuffer, fullMsg)
    
    if _G_State.UpdateUIDisplay then
        pcall(function() _G_State.UpdateUIDisplay(msg) end)
    end
    
    if #_G_State.LiveLogs > 50000 then
        _G_State.LiveLogs = string.sub(_G_State.LiveLogs, -40000)
    end
end

local function safeInvoke(remote, actionName, ...)
    if not remote then return end
    local remoteName = remote.Name or "UnknownRemote"
    local fullAction = actionName .. " -> " .. remoteName
    local s, r = pcall(function(...) return remote:InvokeServer(...) end, ...)
    if s then
        if r == false or r == nil or r == "Error" or r == "AlreadyFull" then
            -- logAction(fullAction, false, r or "Ditolak Server")
        else
            logAction(fullAction, true, r)
        end
    else
        logAction(fullAction, false, "ERROR SERVER/SCRIPT: " .. tostring(r))
    end
end

-- ============================================================
-- SENSOR EKONOMI & MOUSE CLICKER
-- ============================================================
local function getPlayerMoney()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local money = 999999999 -- Default tinggi agar bypass pengecekan client jika gagal detect
    if pGui then
        for _, v in ipairs(pGui:GetDescendants()) do
            if v:IsA("TextLabel") and (string.find(v.Text, "Rp") or string.find(v.Text, "$")) then
                local mStr = string.match(v.Text, "([%d%.%,]+)")
                if mStr then
                    local val = tonumber(string.gsub(string.gsub(mStr, "%.", ""), "%,", ""))
                    if val and val > 0 then money = val end
                end
            end
        end
    end
    return money
end

local function getPrice(txt)
    local mStr = string.match(txt, "([%d%.%,]+)")
    if mStr then return tonumber(string.gsub(string.gsub(mStr, "%.", ""), "%,", "")) or 0 end
    return 0
end

local function clickGuiButton(btn)
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn.Function() end
            for _, conn in pairs(getconnections(btn.MouseButton1Down)) do conn.Function() end
        else
            -- Fallback jika executor standar
            btn:Click()
        end
    end)
end

-- ============================================================
-- THREAD 1: AUTOMATIC SHOP, TRUCK DELIVERY, & UI SCANNER (Realtime)
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        local myMoney = getPlayerMoney()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        
        if pGui then
            for _, v in ipairs(pGui:GetDescendants()) do
                if v:IsA("GuiButton") and v.Visible then
                    local txt = string.lower(v.Name)
                    if v:IsA("TextButton") then txt = txt .. " " .. string.lower(v.Text) end
                    for _, child in ipairs(v:GetDescendants()) do
                        if child:IsA("TextLabel") then txt = txt .. " " .. string.lower(child.Text) end
                    end
                    
                    -- 1. Auto Dark Store / Toko Cerdas (Jual Otomatis Terjual Max)
                    if _G_State.AutoDelivery then
                        local isAdd = string.find(txt, ">>") or string.find(txt, "max") or string.find(txt, "tambah")
                        local isSend = string.find(txt, "kirim") or string.find(txt, "jual") or string.find(txt, "sell")
                        local isItem = string.find(txt, "stok:") or string.find(txt, "stock")
                        local hasStock = isItem and not string.find(txt, "stok: 0") and not string.find(txt, "stock: 0")
                        
                        if (isItem and hasStock) or isAdd or isSend then
                            clickGuiButton(v)
                        end
                    end
                    
                    -- 2. Auto Factory UI Sync
                    if _G_State.AutoFactory and (string.find(txt, "produksi") or string.find(txt, "ambil") or string.find(txt, "claim")) then
                        clickGuiButton(v)
                    end
                    
                    -- 3. Auto Animal & Universal Upgrades
                    if _G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory or _G_State.AutoBuyAnimal then
                        if string.find(txt, "rp") or string.find(txt, "$") or string.find(txt, "beli") then
                            local price = getPrice(txt)
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
                                else shouldBuy = (_G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory) end
                                
                                if shouldBuy then 
                                    clickGuiButton(v)
                                end
                            end
                        end
                    end
                    
                end
            end
        end
    end
end)

-- ============================================================
-- THREAD 2: BYPASS PABRIK (BRUTE-FORCE REMOTES DIRECTLY) - Realtime Loop
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        if _G_State.AutoFactory then
            -- PERBAIKAN UTAMA: Remotes berada langsung di ReplicatedStorage, bukan folder "Remotes"
            local startR = RS:FindFirstChild("RequestStartProduction")
            local claimR = RS:FindFirstChild("RequestClaimProduction")
            
            if startR and claimR then
                for _, recipe in ipairs(AllRecipes) do
                    task.spawn(function() safeInvoke(startR, "Auto_Prod_"..recipe, recipe) end)
                    task.spawn(function() safeInvoke(claimR, "Auto_Claim_"..recipe, recipe) end)
                end
            end
        end
        
        -- Auto Buy Animal via Remote Direct
        if _G_State.AutoBuyAnimal then
            local animalRemote = RS:FindFirstChild("RequestBuyAnimal")
            if animalRemote then
                if _G_State.BuyAyam then task.spawn(function() safeInvoke(animalRemote, "Beli_Ayam", "Ayam") end) end
                if _G_State.BuySapi then task.spawn(function() safeInvoke(animalRemote, "Beli_Sapi", "Sapi") end) end
                if _G_State.BuyDomba then task.spawn(function() safeInvoke(animalRemote, "Beli_Domba", "Domba") end) end
                if _G_State.BuyBabi then task.spawn(function() safeInvoke(animalRemote, "Beli_Babi", "Babi") end) end
            end
        end
    end
end)

-- ============================================================
-- THREAD 3: WEREWOLF AURA SPAM KILL (Bisa Diatur & Hitungan Detik/Milidetik)
-- ============================================================
task.spawn(function()
    while task.wait(_G_State.AttackSpeed or 0.2) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        if _G_State.AntiMonster then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character then
                    local name = string.lower(v.Name)
                    if string.find(name, "wolf") or string.find(name, "werewolf") or string.find(name, "monster") or string.find(name, "siluman") then
                        local mHrp = v:FindFirstChild("HumanoidRootPart")
                        local mHum = v:FindFirstChild("Humanoid")
                        
                        if mHrp and mHum and mHum.Health > 0 then
                            local dist = (mHrp.Position - hrp.Position).Magnitude
                            -- Menggunakan variabel jangkauan area hit yang bisa diatur admin
                            if dist < (_G_State.MonsterRadius or 250) then
                                pcall(function()
                                    -- 1. Hit Damage Event (Jika game menyediakan remote damage)
                                    local dmgEvent = RS:FindFirstChild("BossDamageEvent") or RS:FindFirstChild("BossDamage")
                                    if dmgEvent then
                                        dmgEvent:FireServer(v, 999)
                                    end
                                    
                                    -- 2. Auto Swing Senjata/Pedang dari Tas secara Cepat
                                    local bp = LocalPlayer:FindFirstChild("Backpack")
                                    local char = LocalPlayer.Character
                                    if bp and char then
                                        for _, tool in ipairs(bp:GetChildren()) do
                                            if tool:IsA("Tool") and not string.find(string.lower(tool.Name), "water") then
                                                tool.Parent = char -- Lengkapi senjata
                                            end
                                        end
                                        for _, tool in ipairs(char:GetChildren()) do
                                            if tool:IsA("Tool") and not string.find(string.lower(tool.Name), "water") then
                                                tool:Activate() -- Klik Spam Hit!
                                            end
                                        end
                                    end
                                    
                                    -- 3. Instakill Bypass Celah Client
                                    mHum.Health = 0
                                    mHrp.CFrame = CFrame.new(mHrp.Position.X, -999, mHrp.Position.Z)
                                end)
                                logAction("Anti-Monster", true, "Spam Hit Werewolf/Monster Berhasil (".._G_State.AttackSpeed.."s)")
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- THREAD 4: BYPASS SIRAM AIR & REFILL AIR DARI JARAK JAUH
-- ============================================================
task.spawn(function()
    while task.wait(0.4) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- 1. Auto Refill Air Jarak Jauh (Tanpa Batasan Jarak)
        if _G_State.AutoRefill then
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local act = string.lower(prompt.ActionText or "")
                    local obj = string.lower(prompt.ObjectText or "")
                    local pName = string.lower(prompt.Parent and prompt.Parent.Name or "")
                    
                    if string.find(obj, "air") or string.find(act, "air") or string.find(pName, "sumur") or string.find(pName, "water") then
                        prompt.RequiresLineOfSight = false
                        if _G_State.GlobalRange then
                            prompt.MaxActivationDistance = math.huge -- Paksa jarak infinity
                        end
                        if fireproximityprompt then fireproximityprompt(prompt) end
                    end
                end
            end
            
            -- 2. BYPASS NYIRAM TANAMAN: Kirim Paket ke Server Tanpa Harus Pegang Barang di Tangan
            local tool = getTool("Watering Can")
            if tool and tool:FindFirstChild("WaterRemote") then
                pcall(function() 
                    tool.WaterRemote:FireServer() -- Kirim sinyal siram langsung ke server!
                end)
            end
        end
    end
end)

-- ============================================================
-- THREAD 5: AUTO COLLECT MAGNET & TELEPORT PANEN (JARAK JAUH GLOBAL)
-- ============================================================
task.spawn(function()
    while task.wait(0.3) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        if _G_State.AutoCollect or _G_State.AutoPanen then
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local act = string.lower(v.ActionText or "")
                    local obj = string.lower(v.ObjectText or "")
                    
                    local isCollect = string.find(act, "ambil") or string.find(act, "collect") or string.find(act, "pick") or string.find(obj, "hasil") or string.find(obj, "telur") or string.find(obj, "wol") or string.find(obj, "wool") or string.find(obj, "susu")
                    local isPanen = string.find(act, "panen") or string.find(act, "harvest") or string.find(obj, "tomat") or string.find(obj, "gandum") or string.find(obj, "wortel")
                    
                    if (_G_State.AutoCollect and isCollect) or (_G_State.AutoPanen and isPanen) then
                        v.RequiresLineOfSight = false
                        if _G_State.GlobalRange then
                            v.MaxActivationDistance = math.huge -- Ambil dari jarak jauh manapun
                        end
                        
                        -- Jika server ketat, gunakan teleport kilat
                        if _G_State.CollectTeleport and v.Parent and v.Parent:IsA("BasePart") then
                            local oldCf = hrp.CFrame
                            hrp.CFrame = v.Parent.CFrame + Vector3.new(0,2,0)
                            task.wait(0.1)
                            if fireproximityprompt then fireproximityprompt(v) end
                            task.wait(0.05)
                            hrp.CFrame = oldCf
                        else
                            if fireproximityprompt then fireproximityprompt(v) end
                        end
                    end
                    
                -- Magnet Barang Jatuh (TouchInterest)
                elseif v:IsA("BasePart") and v:FindFirstChild("TouchInterest") and not v:IsDescendantOf(LocalPlayer.Character) then
                    if firetouchinterest then
                        firetouchinterest(hrp, v, 0)
                        task.wait(0.01)
                        firetouchinterest(hrp, v, 1)
                    else
                        v.CFrame = hrp.CFrame
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- TAMPILAN GRAPHIQUE USER INTERFACE (WINDUI MR. PANDA THEME)
-- ============================================================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title = "Panda Industri Pro v3",
    Icon = "box",
    Theme = "Dark",
    Size = UDim2.fromOffset(530, 400),
    Transparent = false
})

local TabFarm = Window:Tab({ Title = "Farming", Icon = "leaf" })
local TabFactory = Window:Tab({ Title = "Factory", Icon = "factory" })
local TabAnimal = Window:Tab({ Title = "Animals", Icon = "paw-print" })
local TabUpgrade = Window:Tab({ Title = "Upgrades", Icon = "trending-up" })
local TabToko = Window:Tab({ Title = "Toko Siluman", Icon = "shopping-cart" })
local TabLogs = Window:Tab({ Title = "Logs & Admin", Icon = "scroll-text" })

-- === TAB FARMING INTERFACE ===
TabFarm:Toggle({
    Title = "Auto Refill Water & Siram",
    Desc = "Otomatis isi gembor & siram via Server Package Bypass (Fix Toggle Lock)",
    Default = false,
    Callback = function(state) _G_State.AutoRefill = state; logAction("Menu -> Auto Refill Water", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Bypass Jarak Jauh (Global)",
    Desc = "Bypass aktivasi dan ambil dari mana saja di map",
    Default = true,
    Callback = function(state) _G_State.GlobalRange = state end
})

TabFarm:Toggle({
    Title = "Auto Panen Tanaman",
    Default = false,
    Callback = function(state) _G_State.AutoPanen = state; logAction("Menu -> Auto Panen", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Auto Collect Barang (Magnet Jauh)",
    Desc = "Menarik Telur, Woll, Susu otomatis dari jarak jauh",
    Default = false,
    Callback = function(state) _G_State.AutoCollect = state; logAction("Menu -> Auto Collect", true, state and "AKTIF" or "MATI") end
})

TabFarm:Toggle({
    Title = "Anti-Monster (Aura Kill)",
    Desc = "Membunuh Werewolf otomatis (Hitungan detik & Milidetik)",
    Default = true,
    Callback = function(state) _G_State.AntiMonster = state; logAction("Menu -> Anti-Monster", true, state and "AKTIF" or "MATI") end
})

TabFarm:Input({
    Title = "Atur Radius Hit Area Monster",
    Placeholder = "Contoh: 250",
    Callback = function(text)
        local num = tonumber(text)
        if num then _G_State.MonsterRadius = num; logAction("Admin", true, "Radius monster diatur ke: " .. num) end
    end
})

TabFarm:Input({
    Title = "Atur Kecepatan Hit Monster (Detik)",
    Placeholder = "Contoh: 0.2",
    Callback = function(text)
        local num = tonumber(text)
        if num then _G_State.AttackSpeed = num; logAction("Admin", true, "Speed hit monster diatur ke: " .. num) end
    end
})

-- === TAB FACTORY INTERFACE ===
TabFactory:Toggle({
    Title = "Auto Factory Realtime (PRODUKSI & AMBIL)",
    Desc = "Bypass remote server terenkripsi otomatis 100% tanpa delay UI",
    Default = false,
    Callback = function(state) _G_State.AutoFactory = state; logAction("Menu -> Auto Factory", true, state and "AKTIF" or "MATI") end
})

-- === TAB ANIMAL INTERFACE ===
TabAnimal:Toggle({
    Title = "Aktifkan Auto Beli Hewan",
    Default = false,
    Callback = function(state) _G_State.AutoBuyAnimal = state; logAction("Menu -> Auto Buy Animal", true, state and "AKTIF" or "MATI") end
})
TabAnimal:Toggle({ Title = "Beli Ayam", Default = false, Callback = function(state) _G_State.BuyAyam = state end })
TabAnimal:Toggle({ Title = "Beli Sapi", Default = false, Callback = function(state) _G_State.BuySapi = state end })
TabAnimal:Toggle({ Title = "Beli Domba", Default = false, Callback = function(state) _G_State.BuyDomba = state end })
TabAnimal:Toggle({ Title = "Beli Babi", Default = false, Callback = function(state) _G_State.BuyBabi = state end })

-- === TAB TOKO SILUMAN INTERFACE ===
TabToko:Dropdown({
    Title = "Mode Penjualan Otomatis (Truk)",
    Options = {"Mati", "Jual Semua (Mentah & Olahan)", "Jual Mentah Saja", "Jual Olahan Saja"},
    Default = "Mati",
    Callback = function(val)
        _G_State.DeliveryMode = val
        _G_State.AutoDelivery = (val ~= "Mati")
        logAction("Menu -> Mode Penjualan", true, tostring(val))
    end
})

-- === TAB UPGRADES INTERFACE ===
TabUpgrade:Toggle({
    Title = "Auto Universal Upgrade",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeUniversal = state end
})
TabUpgrade:Toggle({
    Title = "Auto Upgrade & Unlock Pabrik",
    Default = false,
    Callback = function(state) _G_State.AutoUpgradeFactory = state end
})

-- === TAB LOGS INTERFACE ===
local LogDisplay = TabLogs:Paragraph({
    Title = "Live Logs (Terbaru)",
    Desc = "Sistem Siap Digunakan!"
})

local logLines = {}
_G_State.UpdateUIDisplay = function(newMsg)
    table.insert(logLines, newMsg)
    if #logLines > 4 then table.remove(logLines, 1) end
    if LogDisplay and LogDisplay.SetDesc then
        LogDisplay:SetDesc(table.concat(logLines, "\n"))
    end
end

TabLogs:Button({
    Title = "Salin Seluruh Log ke Clipboard",
    Callback = function() setclipboard(_G_State.LiveLogs) end
})

pcall(function() game:GetService("CoreGui").PandaIndustriMini:Destroy() end)
windui:Notify({ Title = "Panda Industri Pro V3 Loaded!", Content = "Semua perbaikan & bypass berhasil diaktifkan sempurna!", Duration = 5 })
