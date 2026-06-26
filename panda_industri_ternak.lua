-- ============================================================
-- Panda Industri - Auto Farm & Factory (Mr. Panda)
-- V5: Ultimate Auto-Refresh UI & Fixed Remotes
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
_G_State.AutoPabrikSiluman = false
_G_State.AutoBuyAnimal = false
_G_State.AutoCollect = false
_G_State.AutoUpgradeUniversal = false
_G_State.AutoUpgradeFactory = false
_G_State.AutoBuyMastery = false
_G_State.AntiMonster = true
_G_State.LogEnabled = true
_G_State.LiveLogs = "=== PANDA INDUSTRI LIVE LOGS ===\\n"

-- Konfigurasi Kustom Admin
_G_State.MonsterRadius = 250
_G_State.AttackSpeed = 0.2
_G_State.GlobalRange = true

-- Animal toggles
_G_State.BuyAyam = false
_G_State.BuySapi = false
_G_State.BuyDomba = false
_G_State.BuyBabi = false

local AllRecipes = {
    "Tepung", "Roti", "Benang", "Kain", "Baju",
    "Keju", "Mentega", "Krim", "Selai", "Kue",
    "Sirup", "Gula", "Minyak", "Sosis", "Burger",
    "Pancake", "Waffle"
}

local function getTool(name)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild(name) then return char[name] end
    if LocalPlayer.Backpack:FindFirstChild(name) then return LocalPlayer.Backpack[name] end
    return nil
end

-- ============================================================
-- SYSTEM LOGGING (WEBHOOK & MEMORY)
-- ============================================================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local http_request = request or http_request or (http and http.request) or syn and syn.request
local logBuffer = {}

local function sendBufferedLogs()
    if #logBuffer == 0 then return end
    if not http_request then return end
    local combinedLogs = table.concat(logBuffer, "\\n")
    logBuffer = {}
    task.spawn(function()
        pcall(function()
            http_request({ Url = WEBHOOK_URL, Method = "POST", Body = combinedLogs })
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
    _G_State.LiveLogs = _G_State.LiveLogs .. fullMsg .. "\\n"
    table.insert(logBuffer, fullMsg)
    
    if _G_State.UpdateUIDisplay then pcall(function() _G_State.UpdateUIDisplay(msg) end) end
    if #_G_State.LiveLogs > 50000 then _G_State.LiveLogs = string.sub(_G_State.LiveLogs, -40000) end
end

local function safeInvoke(remote, actionName, ...)
    if not remote then return end
    local remoteName = remote.Name or "UnknownRemote"
    local fullAction = actionName .. " -> " .. remoteName
    local s, r = pcall(function(...) return remote:InvokeServer(...) end, ...)
    if s then
        if r ~= false and r ~= nil and r ~= "Error" and r ~= "AlreadyFull" then
            logAction(fullAction, true, r)
        end
    else
        logAction(fullAction, false, "ERROR SCRIPT: " .. tostring(r))
    end
end

task.spawn(function()
    if not _G.HasScannedRemotes then
        _G.HasScannedRemotes = true
        task.wait(3)
        local found = {}
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(found, (v:IsA("RemoteEvent") and "[RE] " or "[RF] ") .. v.Name)
            end
        end
        if #found > 0 then
            table.insert(logBuffer, "=== DETEKSI REMOTE BARU ===\\nDitemukan " .. #found .. " Remotes:\\n" .. table.concat(found, "\\n"))
        end
    end
end)

-- ============================================================
-- UI CLICKER UTILITY & SENSOR UANG
-- ============================================================
local function getPlayerMoney()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local money = 999999999
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
            btn:Click()
        end
    end)
end

-- ============================================================
-- FACTORY SILUMAN & AUTO SCAN AREA
-- ============================================================
-- Cache untuk Dropdown UI agar bisa Auto-Refresh
_G_State.FactoryListCache = {"Mencari Pabrik..."}
_G_State.DeliveryListCache = {"Mencari Tempat Jual..."}
_G_State.FactoryPrompts = {}
_G_State.DeliveryPrompts = {}

local function jualSiluman(namaBarang)
    if not namaBarang or namaBarang == "" then return end
    task.spawn(function()
        local fired = false
        -- Tembak semua prompt delivery yang ada
        for dName, prompt in pairs(_G_State.DeliveryPrompts) do
            prompt.RequiresLineOfSight = false
            if fireproximityprompt then fireproximityprompt(prompt) end
            fired = true
        end
        if not fired then logAction("Siluman", false, "Belum ada tempat jual terdeteksi map!"); return end
        
        task.wait(0.5)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not string.find(string.lower(gui.Name), "windui") then
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
                                logAction("Siluman", true, "Sukses menjual " .. namaBarang)
                                return
                            end
                        end
                    end
                end
            end
        end
        logAction("Siluman", false, "Gagal menemukan " .. namaBarang .. " di UI Truk")
    end)
end

local function produksiPabrikSiluman(namaPabrik, namaBarang)
    if not namaPabrik or namaPabrik == "" or not namaBarang then return end
    task.spawn(function()
        local prompt = _G_State.FactoryPrompts[namaPabrik]
        if not prompt then 
            logAction("Siluman", false, "Pabrik " .. namaPabrik .. " tidak terdeteksi!"); 
            return 
        end
        
        prompt.RequiresLineOfSight = false
        if fireproximityprompt then fireproximityprompt(prompt) end
        
        task.wait(0.5)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not string.find(string.lower(gui.Name), "windui") then
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
                                
                                for _, btn2 in ipairs(gui:GetDescendants()) do
                                    if btn2:IsA("GuiButton") then
                                        local txt2 = string.lower(btn2.Name)
                                        if btn2:IsA("TextButton") then txt2 = txt2 .. " " .. string.lower(btn2.Text) end
                                        if string.find(txt2, "max") or string.find(txt2, ">>") then clickGuiButton(btn2) end
                                    end
                                end
                                task.wait(0.2)
                                
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
                                logAction("Siluman", true, "Sukses Produksi/Ambil " .. namaBarang .. " di " .. namaPabrik)
                                return
                            end
                        end
                    end
                end
            end
        end
        logAction("Siluman", false, "Gagal menemukan " .. namaBarang .. " di UI Pabrik")
    end)
end

-- ============================================================
-- MAIN LOOP: PABRIK, TOKO, SCANNER AREA (0.5 Detik)
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        -- 1. AUTO SCANNER: Mencari Pabrik & Tempat Jual Secara Real-Time (Setiap 0.5s)
        local newFactories = {}
        local newDeliveries = {}
        _G_State.FactoryPrompts = {}
        _G_State.DeliveryPrompts = {}
        
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local act = string.lower(prompt.ActionText or "")
                local obj = string.lower(prompt.ObjectText or "")
                local pName = string.lower(prompt.Parent and prompt.Parent.Name or "")
                
                -- Cek Pabrik
                if string.find(act, "kelola") or string.find(obj, "pabrik") or string.find(act, "produksi") or string.find(pName, "factory") then
                    local fName = prompt.ObjectText
                    if not fName or fName == "" then fName = prompt.Parent.Name end
                    if fName ~= "" and not table.find(newFactories, fName) then
                        table.insert(newFactories, fName)
                        _G_State.FactoryPrompts[fName] = prompt
                    end
                end
                
                -- Cek Tempat Jual / Truk
                if string.find(pName, "delivery") or string.find(act, "jual") or string.find(act, "kirim") or string.find(pName, "sell") then
                    local dName = prompt.ObjectText
                    if not dName or dName == "" then dName = prompt.Parent.Name end
                    if dName ~= "" and not table.find(newDeliveries, dName) then
                        table.insert(newDeliveries, dName)
                        _G_State.DeliveryPrompts[dName] = prompt
                    end
                end
            end
        end
        
        if #newFactories == 0 then table.insert(newFactories, "Belum Ter-Render") end
        if #newDeliveries == 0 then table.insert(newDeliveries, "Belum Ter-Render") end
        
        -- Update UI Dropdown jika ada perubahan
        if _G_State.UIDropdown_Factory and table.concat(newFactories) ~= table.concat(_G_State.FactoryListCache) then
            _G_State.FactoryListCache = newFactories
            _G_State.UIDropdown_Factory:Refresh(_G_State.FactoryListCache)
        end
        if _G_State.UIDropdown_Delivery and table.concat(newDeliveries) ~= table.concat(_G_State.DeliveryListCache) then
            _G_State.DeliveryListCache = newDeliveries
            _G_State.UIDropdown_Delivery:Refresh(_G_State.DeliveryListCache)
        end
        
        -- 2. AUTO FACTORY (BERDASARKAN LOG ASLI, LANGSUNG DI REPLICATEDSTORAGE)
        if _G_State.AutoFactory then
            -- BUKAN di folder "Remotes", tapi langsung di RS sesuai Log yang dikirim Admin!
            local startR = RS:FindFirstChild("RequestStartProduction")
            local claimR = RS:FindFirstChild("RequestClaimProduction")
            if startR and claimR then
                for _, recipe in ipairs(AllRecipes) do
                    task.spawn(function() safeInvoke(startR, "Pabrik_Start_"..recipe, recipe) end)
                    task.spawn(function() safeInvoke(claimR, "Pabrik_Claim_"..recipe, recipe) end)
                end
            else
                logAction("Factory", false, "Remote RequestStartProduction tidak ada di RS!")
            end
        end

        -- 3. AUTO PABRIK SILUMAN BACKGROUND LOOP
        if _G_State.AutoPabrikSiluman then
            if not _G_State.NextPabrikSiluman then _G_State.NextPabrikSiluman = 0 end
            if tick() > _G_State.NextPabrikSiluman then
                _G_State.NextPabrikSiluman = tick() + 5
                if _G_State.SelectedTargetPabrik and _G_State.SelectedPabrikBarang then
                    produksiPabrikSiluman(_G_State.SelectedTargetPabrik, _G_State.SelectedPabrikBarang)
                end
            end
        end
        
        -- 4. AUTO UPGRADE & UNIVERSAL CHECK
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
                    
                    if _G_State.AutoDelivery then
                        local isAdd = string.find(txt, ">>") or string.find(txt, "max")
                        local isSend = string.find(txt, "kirim") or string.find(txt, "jual")
                        local isItem = string.find(txt, "stok:")
                        local hasStock = isItem and not string.find(txt, "stok: 0")
                        if (isItem and hasStock) or isAdd or isSend then clickGuiButton(v) end
                    end
                    
                    if _G_State.AutoUpgradeUniversal or _G_State.AutoUpgradeFactory or _G_State.AutoBuyAnimal then
                        if string.find(txt, "rp") or string.find(txt, "$") then
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
                                
                                if shouldBuy then clickGuiButton(v) end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- LOOP SERIGALA
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
                    if string.find(name, "wolf") or string.find(name, "werewolf") or string.find(name, "monster") then
                        local mHrp = v:FindFirstChild("HumanoidRootPart")
                        local mHum = v:FindFirstChild("Humanoid")
                        if mHrp and mHum and mHum.Health > 0 then
                            if (mHrp.Position - hrp.Position).Magnitude < (_G_State.MonsterRadius or 250) then
                                pcall(function()
                                    mHum.Health = 0
                                    mHrp.CFrame = CFrame.new(mHrp.Position.X, -999, mHrp.Position.Z)
                                end)
                                logAction("Anti-Monster", true, "Serang Werewolf Berhasil")
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- LOOP AIR & MAGNET JAUH
-- ============================================================
task.spawn(function()
    while task.wait(0.3) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        if _G_State.AutoRefill then
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local obj = string.lower(prompt.ObjectText or "")
                    local pName = string.lower(prompt.Parent and prompt.Parent.Name or "")
                    if string.find(obj, "air") or string.find(pName, "sumur") or string.find(pName, "water") then
                        prompt.RequiresLineOfSight = false
                        if _G_State.GlobalRange then prompt.MaxActivationDistance = math.huge end
                        if fireproximityprompt then fireproximityprompt(prompt) end
                    end
                end
            end
            local tool = getTool("Watering Can")
            if tool and tool:FindFirstChild("WaterRemote") then pcall(function() tool.WaterRemote:FireServer() end) end
        end

        if _G_State.AutoCollect or _G_State.AutoPanen then
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local act = string.lower(v.ActionText or "")
                    local obj = string.lower(v.ObjectText or "")
                    local isCollect = string.find(act, "ambil") or string.find(act, "collect") or string.find(obj, "hasil") or string.find(obj, "telur") or string.find(obj, "wol")
                    local isPanen = string.find(act, "panen") or string.find(obj, "tomat") or string.find(obj, "gandum")
                    
                    if (_G_State.AutoCollect and isCollect) or (_G_State.AutoPanen and isPanen) then
                        v.RequiresLineOfSight = false
                        if _G_State.GlobalRange then v.MaxActivationDistance = math.huge end
                        if fireproximityprompt then fireproximityprompt(v) end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- GUI (WINDUI)
-- ============================================================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title = "Panda Industri Pro v5",
    Icon = "box",
    Theme = "Dark",
    Size = UDim2.fromOffset(530, 420),
    Transparent = false
})

local TabToko = Window:Tab({ Title = "Toko & Pabrik (Auto-Scan)", Icon = "shopping-cart" })
local TabFarm = Window:Tab({ Title = "Farming", Icon = "leaf" })
local TabLogs = Window:Tab({ Title = "Logs & Command", Icon = "terminal" })

-- TAB TOKO & PABRIK (AUTO REFRESH 0.5s)
local BarangOlahan = {"Tepung", "Roti", "Benang", "Kain", "Baju", "Keju", "Mentega", "Krim", "Selai", "Kue", "Sirup", "Gula", "Minyak", "Sosis", "Burger", "Pancake", "Waffle"}
_G_State.SelectedTargetPabrik = nil
_G_State.SelectedPabrikBarang = "Tepung"
_G_State.SelectedTargetJual = nil
_G_State.SelectedOlahanJual = "Tepung"

TabToko:Toggle({
    Title = "⚡ Auto Proses Pabrik (Bypass Remote Asli)",
    Default = false,
    Callback = function(state) _G_State.AutoFactory = state; logAction("Menu", true, "Auto Factory " .. (state and "ON" or "OFF")) end
})

-- Dropdown Pabrik yang me-refresh otomatis
_G_State.UIDropdown_Factory = TabToko:Dropdown({ 
    Title = "Pilih Mesin Pabrik (Auto Refreshing...)", 
    Options = _G_State.FactoryListCache, 
    Default = _G_State.FactoryListCache[1], 
    Callback = function(val) _G_State.SelectedTargetPabrik = val end 
})

TabToko:Dropdown({ 
    Title = "Pilih Barang Produksi", 
    Options = BarangOlahan, 
    Default = "Tepung", 
    Callback = function(val) _G_State.SelectedPabrikBarang = val end 
})

TabToko:Button({ 
    Title = "🏭 Buka & Proses Pabrik Siluman", 
    Callback = function() produksiPabrikSiluman(_G_State.SelectedTargetPabrik, _G_State.SelectedPabrikBarang) end 
})

TabToko:Toggle({ 
    Title = "Auto Proses Pabrik Siluman (Loop Background)", 
    Default = false, 
    Callback = function(state) _G_State.AutoPabrikSiluman = state end 
})

TabToko:Divider()

-- Dropdown Delivery yang me-refresh otomatis
_G_State.UIDropdown_Delivery = TabToko:Dropdown({ 
    Title = "Pilih Truk Jual (Auto Refreshing...)", 
    Options = _G_State.DeliveryListCache, 
    Default = _G_State.DeliveryListCache[1], 
    Callback = function(val) _G_State.SelectedTargetJual = val end 
})

TabToko:Dropdown({ 
    Title = "Pilih Barang Olahan Dijual", 
    Options = BarangOlahan, 
    Default = "Tepung", 
    Callback = function(val) _G_State.SelectedOlahanJual = val end 
})

TabToko:Button({ 
    Title = "💰 Buka & Jual Barang", 
    Callback = function() jualSiluman(_G_State.SelectedOlahanJual) end 
})

-- TAB FARMING
TabFarm:Toggle({ Title = "Auto Refill Water & Siram Jauh", Default = false, Callback = function(state) _G_State.AutoRefill = state end })
TabFarm:Toggle({ Title = "Bypass Jarak Jauh (Global)", Default = true, Callback = function(state) _G_State.GlobalRange = state end })
TabFarm:Toggle({ Title = "Auto Panen", Default = false, Callback = function(state) _G_State.AutoPanen = state end })
TabFarm:Toggle({ Title = "Auto Collect Barang (Magnet)", Default = false, Callback = function(state) _G_State.AutoCollect = state end })
TabFarm:Toggle({ Title = "Anti-Monster (Aura Kill)", Default = true, Callback = function(state) _G_State.AntiMonster = state end })

-- TAB LOGS & COMMAND (FIX 4 BARIS)
local LogDisplay = TabLogs:Paragraph({
    Title = "Live Logs (4 Baris Terakhir)",
    Desc = "Memuat log..."
})

local logLines = {}
_G_State.UpdateUIDisplay = function(newMsg)
    table.insert(logLines, newMsg)
    if #logLines > 4 then table.remove(logLines, 1) end
    if LogDisplay and LogDisplay.SetDesc then LogDisplay:SetDesc(table.concat(logLines, "\\n")) end
end

TabLogs:Input({
    Title = "Command & Catat Lokasi",
    Desc = "Ketik perintah, lokasi akan otomatis ditambahkan ke log & webhook",
    Placeholder = "Ketik perintah/test disini...",
    Callback = function(text)
        if text == "" then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local pos = hrp and string.format("X:%.1f, Y:%.1f, Z:%.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "Lokasi Tidak Diketahui"
        logAction("COMMAND TEST", true, string.format("Posisi [%s] | Perintah: %s", pos, text))
        windui:Notify({Title = "Command Terkirim!", Content = "Perintah dan lokasi telah dicatat ke Webhook Google.", Duration = 4})
    end
})

pcall(function() game:GetService("CoreGui").PandaIndustriMini:Destroy() end)
windui:Notify({ Title = "V5 Loaded", Content = "Auto-Scanner 0.5s & Factory Bypass Aktif!", Duration = 5 })


with open("Panda_Industri_Pro_V5.lua", "w") as f:
    f.write(lua_code)
print("File generated successfully")
