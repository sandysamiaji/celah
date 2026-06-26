-- ============================================================
-- Panda Industri - Auto Farm & Factory (Mr. Panda)
-- V4: Mobile & Logs Edition (Reverted Factory & Remote Detect)
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
_G_State.LiveLogs = "=== PANDA INDUSTRI LIVE LOGS ===\\n"
_G_State.AutoPabrikSiluman = false

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
    _G_State.LiveLogs = _G_State.LiveLogs .. fullMsg .. "\\n"
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
        if r ~= false and r ~= nil and r ~= "Error" and r ~= "AlreadyFull" then
            logAction(fullAction, true, r)
        end
    else
        logAction(fullAction, false, "ERROR SCRIPT: " .. tostring(r))
    end
end

-- ============================================================
-- REMOTE SERVICE DETECTION (DIKEMBALIKAN SEPERTI AWAL)
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
            table.insert(logBuffer, "=== REMOTE SERVICE DETECTION ===\\nDitemukan " .. #found .. " Remotes di ReplicatedStorage:\\n" .. table.concat(found, "\\n"))
        end
    end
end)

-- ============================================================
-- UI CLICKER UTILITY
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
-- FACTORY SILUMAN (DIKEMBALIKAN SEPERTI AWAL)
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
        logAction("Manual", false, "Gagal menemukan: " .. nameKey)
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
        if not fired then logAction("Siluman", false, "Gagal menemukan mesin pabrik"); return end
        
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
                                logAction("Siluman", true, "Sukses Produksi/Ambil " .. namaBarang)
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

-- ============================================================
-- MAIN LOOP: PABRIK, TOKO & AURA
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaIndustriExecution ~= ExecutionID then break end
        
        -- Auto Factory (Dikembalikan ke logika folder Remotes)
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
                end
            end
        end

        -- Auto Pabrik Siluman Background Loop
        if _G_State.AutoPabrikSiluman then
            if not _G_State.NextPabrikSiluman then _G_State.NextPabrikSiluman = 0 end
            if tick() > _G_State.NextPabrikSiluman then
                _G_State.NextPabrikSiluman = tick() + 5
                if _G_State.SelectedPabrik and _G_State.SelectedPabrik ~= "" then
                    produksiPabrikSiluman(_G_State.SelectedPabrik)
                end
            end
        end
        
        -- Auto Upgrade & Animal Universal Check
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

-- LOOP SERIGALA
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

-- LOOP AIR & MAGNET JAUH
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
    Title = "Panda Industri Pro v4",
    Icon = "box",
    Theme = "Dark",
    Size = UDim2.fromOffset(530, 420),
    Transparent = false
})

local TabToko = Window:Tab({ Title = "Toko & Pabrik (V2)", Icon = "shopping-cart" })
local TabFarm = Window:Tab({ Title = "Farming", Icon = "leaf" })
local TabLogs = Window:Tab({ Title = "Logs & Command", Icon = "terminal" })

-- TAB TOKO & PABRIK (LOGIKA V2)
local BarangMentah = {"Telur", "Susu", "Wol", "Bacon", "Gandum", "Tomat", "Wortel", "Tebu"}
local BarangOlahan = {"Tepung", "Roti", "Benang", "Kain", "Baju", "Keju", "Mentega", "Krim", "Selai", "Kue", "Sirup", "Gula", "Minyak", "Sosis", "Burger", "Pancake", "Waffle"}
_G_State.SelectedMentah = "Telur"
_G_State.SelectedOlahan = "Tepung"
_G_State.SelectedPabrik = "Tepung"

TabToko:Toggle({
    Title = "Auto Proses Pabrik (Dari Folder Remotes)",
    Default = false,
    Callback = function(state) _G_State.AutoFactory = state; logAction("Menu", true, "Auto Factory " .. (state and "ON" or "OFF")) end
})

TabToko:Dropdown({ Title = "Produksi & Ambil (UI Scanner)", Options = BarangOlahan, Default = "Tepung", Callback = function(val) _G_State.SelectedPabrik = val end })
TabToko:Button({ Title = "🏭 Proses Pabrik Ini (Siluman)", Callback = function() produksiPabrikSiluman(_G_State.SelectedPabrik) end })
TabToko:Toggle({ Title = "Auto Proses Pabrik Ini (Loop)", Default = false, Callback = function(state) _G_State.AutoPabrikSiluman = state end })
TabToko:Dropdown({ Title = "Jual Barang Olahan", Options = BarangOlahan, Default = "Tepung", Callback = function(val) _G_State.SelectedOlahan = val end })
TabToko:Button({ Title = "💰 Jual Olahan Ini", Callback = function() jualSiluman(_G_State.SelectedOlahan) end })

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
    -- Memastikan log yang tampil tepat 4 baris
    if #logLines > 4 then table.remove(logLines, 1) end
    if LogDisplay and LogDisplay.SetDesc then
        LogDisplay:SetDesc(table.concat(logLines, "\\n"))
    end
end

TabLogs:Input({
    Title = "Command & Catat Lokasi",
    Desc = "Ketik perintah, lokasi akan otomatis ditambahkan ke log & webhook",
    Placeholder = "Ketik perintah/test disini...",
    Callback = function(text)
        if text == "" then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local pos = hrp and string.format("X:%.1f, Y:%.1f, Z:%.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "Lokasi Tidak Diketahui"
        
        -- Catat ke log dengan format khusus
        logAction("COMMAND TEST", true, string.format("Posisi [%s] | Perintah: %s", pos, text))
        
        -- Alert ke user mobile
        windui:Notify({Title = "Command Terkirim!", Content = "Perintah dan lokasi telah dicatat ke Webhook Google.", Duration = 4})
    end
})

pcall(function() game:GetService("CoreGui").PandaIndustriMini:Destroy() end)
windui:Notify({ Title = "V4 Loaded", Content = "Log, Factory V2 & Command Input siap!", Duration = 5 })
