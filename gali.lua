-- ============================================================
-- PANDA HELPER - DIGGING/MINING SIMULATOR PRO
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Proteksi Multiple Execution
_G.PandaGaliExecution = (_G.PandaGaliExecution or 0) + 1
local ExecutionID = _G.PandaGaliExecution

local State = {
    AutoClick = false,
    AutoHitWall = false,
    AutoSell = false,
    AutoRebirth = false,
    AutoEquip = false,
    EnableLogs = true,
    AutoCollect = false,
    AutoAura = false,
    OneHitExploit = false,
    FakeDamage = 100,
}

local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local logQueue = {}
local lastLogSend = tick()

local function processLogQueue()
    if #logQueue > 0 and tick() - lastLogSend >= 5 then
        local payload = table.concat(logQueue, "\n")
        logQueue = {}
        lastLogSend = tick()
        
        task.spawn(function()
            pcall(function()
                local requestFunc = request or http_request or (http and http.request)
                if requestFunc then
                    requestFunc({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = game:GetService("HttpService"):JSONEncode({ content = payload })
                    })
                end
            end)
        end)
    end
end

local logLines = {}
local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    
    if State.EnableLogs then
        table.insert(logQueue, msg)
    end
    
    table.insert(logLines, 1, msg)
    if #logLines > 100 then table.remove(logLines, 101) end
    if State.UpdateUIDisplay then State.UpdateUIDisplay() end
end

-- Resolusi Remote Cepat
local Remotes = {}
pcall(function()
    local serverRemotes = RS:WaitForChild("Remotes", 5) and RS.Remotes:WaitForChild("Server", 5)
    if serverRemotes then
        Remotes.Click = serverRemotes:WaitForChild("Click", 2)
        Remotes.HitWall = serverRemotes:WaitForChild("HitWall", 2)
        Remotes.SellAllLoot = serverRemotes:WaitForChild("SellAllLoot", 2)
        Remotes.Rebirth = serverRemotes:WaitForChild("Rebirth", 2)
        Remotes.GotoSurface = serverRemotes:WaitForChild("GotoSurface", 2)
        Remotes.PurchaseAura = serverRemotes:WaitForChild("PurchaseAura", 2)
        Remotes.EquipAura = serverRemotes:WaitForChild("EquipAura", 2)
    end
end)

local function safeFire(remote, ...)
    if remote and remote:IsA("RemoteEvent") then
        pcall(function(...) remote:FireServer(...) end, ...)
    end
end

-- =====================
-- CORE LOOPS
-- =====================
local clickCount = 0
local hitCount = 0

task.spawn(function()
    local RunService = game:GetService("RunService")
    while true do
        RunService.Heartbeat:Wait()
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoClick then
            for i = 1, 50 do
                if State.OneHitExploit then
                    safeFire(Remotes.Click, 1, State.FakeDamage)
                else
                    safeFire(Remotes.Click, 1, 1)
                end
                clickCount = clickCount + 1
            end
            if clickCount % 5000 == 0 then logAction("Farm", "Berhasil Click/Swing 5000x") end
        end
        if State.AutoHitWall then
            for i = 1, 50 do
                if State.OneHitExploit then
                    safeFire(Remotes.HitWall, 1, State.FakeDamage)
                else
                    safeFire(Remotes.HitWall, 1, 1)
                end
                hitCount = hitCount + 1
            end
            if hitCount % 5000 == 0 then logAction("Farm", "Berhasil HitWall 5000x") end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoSell then
            -- Bypass Jarak Jauh menggunakan fireproximityprompt (tanpa teleport!)
            pcall(function()
                if fireproximityprompt then
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local txt = string.lower(obj.ActionText .. " " .. obj.ObjectText)
                            if string.find(txt, "sell") then
                                fireproximityprompt(obj, 1, true)
                            end
                        end
                    end
                end
            end)
            -- Tetap coba tembak remote servernya juga
            safeFire(Remotes.SellAllLoot)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoCollect then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.ActionText == "Pickup?" then
                            if fireproximityprompt then
                                fireproximityprompt(obj, 1, true)
                            else
                                -- Fallback: Pindahkan loot ke kaki karakter
                                local p = obj.Parent
                                if p and p:IsA("BasePart") then
                                    p.CFrame = hrp.CFrame
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoRebirth then
            safeFire(Remotes.Rebirth, "Rebirth")
            logAction("Rebirth", "Mencoba request Rebirth")
        end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoAura then
            if Remotes.PurchaseAura then safeFire(Remotes.PurchaseAura) end
            if Remotes.EquipAura then safeFire(Remotes.EquipAura) end
            logAction("Aura", "Mencoba Purchase & Equip Aura")
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoEquip then
            pcall(function()
                local char = LocalPlayer.Character
                if char and not char:FindFirstChildOfClass("Tool") then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        -- Ambil tool apa saja yang ada di ransel (misal pickaxe)
                        local tool = backpack:FindFirstChildOfClass("Tool")
                        if tool then
                            char.Humanoid:EquipTool(tool)
                        end
                    end
                end
            end)
        end
    end
end)

-- Webhook Processor Loop
task.spawn(function()
    while task.wait(1) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        processLogQueue()
    end
end)

-- =====================
-- GUI (WINDUI)
-- =====================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title   = "🐼 Panda Helper - Mining Pro",
    Icon    = "pickaxe",
    Theme   = "Dark",
    Size    = UDim2.fromOffset(500, 380),
    Transparent = false
})

local TabMain = Window:Tab({ Title = "🏠 Main Farm", Icon = "home" })

TabMain:Toggle({
    Title    = "⚡ Auto Click / Swing",
    Default  = false,
    Callback = function(v) State.AutoClick = v end
})

TabMain:Toggle({
    Title    = "🧱 Auto Hit Wall",
    Default  = false,
    Callback = function(v) State.AutoHitWall = v end
})

TabMain:Toggle({
    Title    = "💰 Auto Sell All Loot (Proximity Bypass)",
    Default  = false,
    Callback = function(v) State.AutoSell = v end
})

TabMain:Toggle({
    Title    = "🧲 Auto Collect / Magnet",
    Default  = false,
    Callback = function(v) State.AutoCollect = v end
})

TabMain:Toggle({
    Title    = "🔄 Auto Rebirth",
    Default  = false,
    Callback = function(v) State.AutoRebirth = v end
})

TabMain:Toggle({
    Title    = "⛏️ Auto Equip Pickaxe",
    Default  = false,
    Callback = function(v) State.AutoEquip = v end
})

TabMain:Toggle({
    Title    = "✨ Auto Gacha & Equip Aura (DMG)",
    Default  = false,
    Callback = function(v) State.AutoAura = v end
})

TabMain:Toggle({
    Title    = "💥 1-Hit Exploit (Suntik Fake Damage)",
    Default  = false,
    Callback = function(v) 
        State.OneHitExploit = v 
        if v then logAction("Exploit", "Fake damage aktif: " .. tostring(State.FakeDamage)) end
    end
})

TabMain:Input({
    Title    = "🔢 Atur Jumlah Fake Damage",
    Desc     = "Sesuaikan dengan HP tembok (Contoh: 50, 100, 500)",
    Default  = "100",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            State.FakeDamage = num
            logAction("Exploit", "Fake damage diubah ke: " .. tostring(num))
        end
    end
})

local TabLogs = Window:Tab({ Title = "📋 Logs", Icon = "book" })

TabLogs:Toggle({
    Title    = "📝 Aktifkan Pencatatan Log",
    Default  = true,
    Callback = function(v) State.EnableLogs = v end
})

TabLogs:Button({
    Title    = "🗑️ Bersihkan Log",
    Callback = function() 
        logLines = {} 
        if State.UpdateUIDisplay then State.UpdateUIDisplay() end
    end
})

local LogDisplay = TabLogs:Paragraph({ Title = "Live Logs", Desc = "Menunggu aktivitas..." })

State.UpdateUIDisplay = function()
    if LogDisplay and LogDisplay.SetDesc then
        LogDisplay:SetDesc(table.concat(logLines, "\n"))
    end
end

Window:SelectTab(1)
windui:Notify({
    Title   = "🐼 Panda Helper",
    Content = "Script Mining Pro berhasil dimuat!\nSemua Remote siap digunakan.",
    Duration = 5
})
