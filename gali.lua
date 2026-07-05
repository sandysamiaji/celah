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
}

local logLines = {}
local function logAction(action, text)
    if not State.EnableLogs then return end
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
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
    while task.wait(0.05) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoClick then
            safeFire(Remotes.Click)
            clickCount = clickCount + 1
            if clickCount % 100 == 0 then logAction("Farm", "Berhasil Click/Swing 100x") end
        end
        if State.AutoHitWall then
            safeFire(Remotes.HitWall)
            hitCount = hitCount + 1
            if hitCount % 100 == 0 then logAction("Farm", "Berhasil HitWall 100x") end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if _G.PandaGaliExecution ~= ExecutionID then break end
        
        if State.AutoSell then
            safeFire(Remotes.SellAllLoot)
            logAction("Sell", "Menjual semua loot")
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
