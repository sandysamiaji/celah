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
    SellCFrame = nil,
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
    while task.wait() do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoClick then
            safeFire(Remotes.Click)
            clickCount = clickCount + 1
            if clickCount % 200 == 0 then logAction("Farm", "Berhasil Click/Swing 200x") end
        end
        if State.AutoHitWall then
            safeFire(Remotes.HitWall)
            hitCount = hitCount + 1
            if hitCount % 200 == 0 then logAction("Farm", "Berhasil HitWall 200x") end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoSell then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if State.SellCFrame and hrp then
                local oldCFrame = hrp.CFrame
                -- Teleport secepat kilat
                hrp.CFrame = State.SellCFrame
                task.wait() -- Jeda 1 frame agar server sadar kita di atas
                safeFire(Remotes.SellAllLoot)
                hrp.CFrame = oldCFrame -- Langsung balik ke lubang tambang!
            else
                -- Jika belum di-set, cara jadul
                if Remotes.GotoSurface then safeFire(Remotes.GotoSurface) end
                safeFire(Remotes.SellAllLoot)
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
    Title    = "💰 Auto Sell All Loot",
    Default  = false,
    Callback = function(v) State.AutoSell = v end
})

TabMain:Button({
    Title    = "📍 Set Lokasi Sell (Berdiri di tempat jual lalu klik)",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            State.SellCFrame = hrp.CFrame
            windui:Notify({ Title = "Lokasi Diatur", Content = "Lokasi jual berhasil direkam!", Duration = 3 })
            logAction("System", "Lokasi Sell ditetapkan")
        end
    end
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
