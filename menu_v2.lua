-- ============================================================
-- Nuke Game - Auto Farm Pro (Mr. Panda)
-- V2: Full Remote Rebuild berdasarkan Remote Spy Report
-- PlaceId: 128784467030899
-- ============================================================
-- REMOTE MAP (dari spy):
--   PickUp          -> NukeRemotes / RE/Pickup/PickUp
--   Drop            -> NukeRemotes / RE/Pickup/Drop
--   MergeRequest    -> NukeRemotes / RE/Merge/MergeRequest
--   MergeVFX        -> NukeRemotes (S2C, untuk deteksi hasil merge)
--   HoldStarted     -> NukeRemotes (S2C, konfirmasi PickUp berhasil)
--   HoldEnded       -> NukeRemotes (S2C, konfirmasi selesai)
--   LaunchRequest   -> RE/Launch/LaunchRequest
--   ConfirmOPLaunch -> NukeRemotes / RE/Launch/ConfirmOPLaunch
--   RequestRebirth  -> NukeRemotes
--   LockStateUpdate -> NukeRemotes (S2C, locked/unlocked)
--   RequestLockBase -> NukeRemotes (C2S, request kunci base)
-- ============================================================

local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService= game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- EXECUTION GUARD
-- ============================================================
local ExecutionID = tick()
_G.PandaExecution = ExecutionID
_G.NukeGameExecution = ExecutionID -- Mematikan loop dari script versi lama (v1) jika masih berjalan

local State = {
    AutoMerge      = false,
    StealNukes     = false,
    AutoCollect    = false,
    AutoDefense    = false,
    AutoRebirth    = false,
    AutoLaunch     = false,
    IsHolding      = false,
    IsUnderAttack  = false,
    CurrentNukeLevel = 0,
    MergeCount     = 0,
    LiveLogs       = "=== NUKE GAME LIVE LOGS ===\n",
    LogEnabled     = true,
}

-- ============================================================
-- WEBHOOK & LOGGING
-- ============================================================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local http_request = request or http_request or (http and http.request) or (syn and syn.request)
local logBuffer = {}
local lastLogs  = {}
local logLines  = {}

local function logAction(action, isSuccess, detail)
    if not State.LogEnabled then return end
    if type(detail) == "table" then detail = "[table]" end
    local status = isSuccess and "SUKSES" or "GAGAL"
    local msg    = string.format("[%s] %s | %s", status, action, tostring(detail))
    if lastLogs[action] == msg then return end
    lastLogs[action] = msg
    local fullMsg = os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg
    State.LiveLogs = State.LiveLogs .. fullMsg .. "\n"
    table.insert(logBuffer, fullMsg)
    table.insert(logLines, msg)
    if #logLines > 10 then table.remove(logLines, 1) end
    if State.UpdateUIDisplay then pcall(State.UpdateUIDisplay, msg) end
    if #State.LiveLogs > 60000 then State.LiveLogs = string.sub(State.LiveLogs, -50000) end
end

-- Flush log ke webhook setiap 5 detik
task.spawn(function()
    while task.wait(5) do
        if _G.PandaExecution ~= ExecutionID then break end
        if #logBuffer > 0 and http_request then
            local batch = table.concat(logBuffer, "\n")
            logBuffer = {}
            task.spawn(function()
                pcall(function()
                    http_request({
                        Url    = WEBHOOK_URL,
                        Method = "POST",
                        Headers= { ["Content-Type"] = "application/json" },
                        Body   = HttpService:JSONEncode({ content = batch })
                    })
                end)
            end)
        end
    end
end)

-- ============================================================
-- REMOTE FINDER (Multi-Path Support)
-- ============================================================
-- Semua kemungkinan path berdasarkan spy report
local REMOTE_PATHS = {
    PickUp          = { "NukeRemotes.PickUp",         "Packages.Remotes.Networking.RE/Pickup/PickUp" },
    Drop            = { "NukeRemotes.Drop",            "Packages.Remotes.Networking.RE/Pickup/Drop" },
    HoldStarted     = { "NukeRemotes.HoldStarted",    "Packages.Remotes.Networking.RE/Pickup/HoldStarted" },
    HoldEnded       = { "NukeRemotes.HoldEnded",      "Packages.Remotes.Networking.RE/Pickup/HoldEnded" },
    MergeRequest    = { "NukeRemotes.MergeRequest",   "Packages.Remotes.Networking.RE/Merge/MergeRequest" },
    MergeVFX        = { "NukeRemotes.MergeVFX",       "Packages.Remotes.Networking.RE/Merge/MergeVFX" },
    MergeSound      = { "NukeRemotes.MergeSound",     "Packages.Remotes.Networking.RE/Merge/MergeSound" },
    LaunchRequest   = { "Packages.Remotes.Networking.RE/Launch/LaunchRequest" },
    LaunchConfirm   = { "NukeRemotes.LaunchConfirm",  "Packages.Remotes.Networking.RE/Launch/LaunchConfirm" },
    ConfirmOPLaunch = { "NukeRemotes.ConfirmOPLaunch","Packages.Remotes.Networking.RE/Launch/ConfirmOPLaunch" },
    LockStateUpdate = { "NukeRemotes.LockStateUpdate","Packages.Remotes.Networking.RE/Combat/LockStateUpdate" },
    RequestLockBase = { "NukeRemotes.RequestLockBase" },
    RequestRebirth  = { "NukeRemotes.RequestRebirth" },
    RebirthSuccess  = { "NukeRemotes.RebirthSuccess" },
    OfflineEarnings = { "NukeRemotes.OfflineEarnings" },
    ClaimGroupReward= { "NukeRemotes.ClaimGroupReward" },
    RedeemCode      = { "NukeRemotes.RedeemCode" },
    GetLeaderboard  = { "NukeRemotes.GetLeaderboard" },
    RebuildDone     = { "NukeRemotes.RebuildDone" },
    AttackFeed      = { "NukeRemotes.AttackFeed",     "Packages.Remotes.Networking.RE/Combat/AttackFeed" },
}

-- Cache remote yang sudah ditemukan
local remoteCache = {}

local function resolveRemote(name)
    if remoteCache[name] then
        -- Validasi bahwa instance masih ada
        if remoteCache[name].Parent then return remoteCache[name] end
        remoteCache[name] = nil
    end
    local paths = REMOTE_PATHS[name]
    if not paths then return nil end
    for _, pathStr in ipairs(paths) do
        local parts  = string.split(pathStr, ".")
        local cursor = RS
        local ok = true
        for _, part in ipairs(parts) do
            local child = cursor:FindFirstChild(part)
            if not child then
                -- Coba cari dengan WaitForChild singkat
                child = cursor:FindFirstChild(part, true) -- recursive
                if not child then ok = false; break end
            end
            cursor = child
        end
        if ok and cursor ~= RS then
            remoteCache[name] = cursor
            return cursor
        end
    end
    return nil
end

local function helperKeys(t)
    local keys={}
    for key,_ in pairs(t) do
        table.insert(keys, key)
    end
    return keys
end

-- ============================================================
-- SAFE FIRE / INVOKE
-- ============================================================
local function safeFire(remote, ...)
    if not remote or not remote.Parent then return false end
    local ok, err = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        else
            remote:FireServer(...)
        end
    end, ...)
    return ok
end

local function safeInvoke(remote, ...)
    if not remote or not remote.Parent then return nil end
    local ok, result = pcall(function(...) return remote:InvokeServer(...) end, ...)
    if ok then return result end
    return nil
end

-- ============================================================
-- CHARACTER UTILITIES
-- ============================================================
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- NUKE FINDER
-- ============================================================
local function getAllNukes()
    local nukes = {}
    local hrp = getHRP()
    local hrpPos = hrp and hrp.Position or Vector3.new(0,0,0)
    
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Nuke" then
            local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
            if primary then
                local dist = (primary.Position - hrpPos).Magnitude
                -- Jika StealNukes OFF, hanya ambil nuke dalam radius 250 studs (area base sendiri)
                if State.StealNukes or dist <= 250 then
                    table.insert(nukes, { model = v, part = primary, pos = primary.Position, dist = dist })
                end
            end
        end
    end
    -- Urutkan dari yang terdekat ke karakter
    if hrp then
        table.sort(nukes, function(a, b)
            return a.dist < b.dist
        end)
    end
    return nukes
end

-- Cari nuke terdekat yang belum dipegang siapapun
local function getNearestFreeNuke()
    local hrp = getHRP()
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Nuke" then
            -- Nuke yang sedang dipegang biasanya dipindah ke luar workspace area normal
            -- Cek apakah nuke ada di posisi valid (Y sekitar 14-16)
            local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
            if primary and primary.Position.Y < 50 then
                local dist = hrp and (primary.Position - hrp.Position).Magnitude or 0
                if dist < bestDist then
                    bestDist = dist
                    best = v
                end
            end
        end
    end
    return best, bestDist
end

-- ============================================================
-- AUTO MERGE - LOGIC UTAMA (BRING & MERGE BYPASS)
-- ============================================================
-- Strategi bypass tanpa teleport karakter:
-- 1. Pindahkan posisi Nuke (CFrame) ke posisi karakter secara lokal.
-- 2. Pastikan karakter sedang memegang satu Nuke (HoldStarted).
-- 3. Kirim MergeRequest untuk nuke lainnya.
-- ============================================================

local holdConfirmed = false
local holdLevel     = 0

pcall(function()
    local holdStartedRE = resolveRemote("HoldStarted") or (RS:WaitForChild("NukeRemotes", 5) and RS.NukeRemotes:FindFirstChild("HoldStarted"))
    if holdStartedRE and holdStartedRE:IsA("RemoteEvent") then
        holdStartedRE.OnClientEvent:Connect(function(level)
            holdConfirmed = true
            holdLevel = level or 0
            State.IsHolding = true
            logAction("Hold", true, "Memegang nuke level " .. tostring(level))
        end)
    end
end)

pcall(function()
    local holdEndedRE = resolveRemote("HoldEnded") or (RS:WaitForChild("NukeRemotes", 5) and RS.NukeRemotes:FindFirstChild("HoldEnded"))
    if holdEndedRE and holdEndedRE:IsA("RemoteEvent") then
        holdEndedRE.OnClientEvent:Connect(function()
            holdConfirmed = false
            State.IsHolding = false
        end)
    end
end)

pcall(function()
    local mergeVFX = resolveRemote("MergeVFX")
    if mergeVFX and mergeVFX:IsA("RemoteEvent") then
        mergeVFX.OnClientEvent:Connect(function(pos, level)
            State.MergeCount = State.MergeCount + 1
            State.CurrentNukeLevel = level or State.CurrentNukeLevel
            logAction("Merge Result", true, "Sukses level " .. tostring(level) .. " | Total: " .. State.MergeCount)
        end)
    end
end)

local function tweenTo(targetPos)
    local hrp = getHRP()
    if hrp then
        local dist = (hrp.Position - targetPos).Magnitude
        if dist < 5 then return true end -- Sudah dekat
        local tInfo = TweenInfo.new(dist / 50, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tInfo, {CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))})
        tween:Play()
        tween.Completed:Wait()
        task.wait(0.1)
        return true
    end
    return false
end

-- ============================================================
-- AUTO MERGE LOOP
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.PandaExecution ~= ExecutionID then break end
        if not State.AutoMerge then continue end
        if State.IsUnderAttack then continue end
        
        local nukes = getAllNukes()
        if #nukes == 0 then continue end
        
        local pickUpRE  = resolveRemote("PickUp")
        local mergeRE   = resolveRemote("MergeRequest")

        if pickUpRE and mergeRE then
            -- Jika kita BELUM memegang nuke, kita harus ambil 1 nuke terdekat dulu
            if not State.IsHolding then
                local nearest = nukes[1]
                if nearest and nearest.model and nearest.model.Parent then
                    -- Jalan/Tween ke Nuke pertama agar server validasi posisinya
                    tweenTo(nearest.pos)
                    
                    holdConfirmed = false
                    safeFire(pickUpRE, nearest.model)
                    
                    -- Tunggu konfirmasi hold
                    local waited = 0
                    while not holdConfirmed and waited < 1 do
                        task.wait(0.1)
                        waited = waited + 0.1
                    end
                    
                    if holdConfirmed then
                        logAction("Auto Merge", true, "Berhasil memegang 1 nuke sebagai Base")
                    else
                        logAction("Auto Merge", false, "Gagal mengambil nuke base, coba lagi...")
                    end
                end
            else
                -- Jika SUDAH memegang nuke, remote merge semua nuke lainnya TANPA perlu berjalan ke sana!
                -- Ini adalah bypass teleport yang sebenarnya.
                local merged = 0
                for i = 2, #nukes do
                    local nukeInfo = nukes[i]
                    if not State.AutoMerge then break end
                    if nukeInfo.model and nukeInfo.model.Parent then
                        safeFire(mergeRE, nukeInfo.model)
                        merged = merged + 1
                        task.wait(0.1)
                    end
                end
                if merged > 0 then
                    logAction("Auto Merge", true, "Remote Merge " .. merged .. " nuke(s)")
                end
            end
        end
    end
end)

-- ============================================================
-- AUTO COLLECT (TOUCH DROP ITEMS)
-- ============================================================
task.spawn(function()
    while task.wait(0.4) do
        if _G.PandaExecution ~= ExecutionID then break end
        if not State.AutoCollect then continue end
        
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            local collected = 0
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("TouchTransmitter") then
                    local name = obj.Name
                    if string.find(name, "RMB_") or name == "neon" or name == "Coin" or name == "Cash" then
                        firetouchinterest(hrp, obj, 0)
                        task.wait(0.01)
                        firetouchinterest(hrp, obj, 1)
                        collected = collected + 1
                    end
                end
            end
            if collected > 0 then
                logAction("Auto Collect", true, "Menyentuh " .. collected .. " item")
            end
        end)
    end
end)

-- ============================================================
-- AUTO REBIRTH
-- ============================================================
task.spawn(function()
    while task.wait(10) do
        if _G.PandaExecution ~= ExecutionID then break end
        if not State.AutoRebirth then continue end
        
        pcall(function()
            local rebirthRE = resolveRemote("RequestRebirth")
            if rebirthRE then
                safeFire(rebirthRE)
                logAction("Auto Rebirth", true, "RequestRebirth dikirim")
            end
        end)
    end
end)

-- Dengarkan RebirthSuccess
pcall(function()
    local rebirthSuccessRE = resolveRemote("RebirthSuccess")
    if rebirthSuccessRE and rebirthSuccessRE:IsA("RemoteEvent") then
        rebirthSuccessRE.OnClientEvent:Connect(function(a, b)
            logAction("Rebirth", true, "Sukses! Arg: " .. tostring(a) .. ", " .. tostring(b))
        end)
    end
end)

-- ============================================================
-- AUTO DEFENSE (LOCK BASE)
-- ============================================================
local function triggerDefense(lock)
    pcall(function()
        local lockRE = resolveRemote("RequestLockBase")
        if lockRE and lock then
            safeFire(lockRE)
            logAction("Defense", true, "Base dikunci (RequestLockBase)")
        end
        -- Ambil bom terbaik
        local pickUpRE = resolveRemote("PickUp")
        local dropRE   = resolveRemote("Drop")
        if lock then
            if pickUpRE then
                -- Cari model dengan level tertinggi
                local bestModel, maxLvl = nil, 0
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Model") and tonumber(v.Name) then
                        local lvl = tonumber(v.Name)
                        if lvl > maxLvl then maxLvl = lvl; bestModel = v end
                    end
                end
                if bestModel then
                    safeFire(pickUpRE, bestModel)
                    logAction("Defense", true, "Mengambil bom level " .. maxLvl)
                end
            end
        else
            if dropRE then
                local hrp = getHRP()
                if hrp then
                    local p = hrp.Position
                    -- Kirim posisi drop + orientasi (format dari spy: x, y, z, r00, r01, r02, ...)
                    safeFire(dropRE, p.X, p.Y, p.Z)
                end
                logAction("Defense", true, "Bom di-drop")
            end
        end
    end)
end

-- Dengarkan LockStateUpdate (S2C)
pcall(function()
    local lockRE = resolveRemote("LockStateUpdate")
    if lockRE and lockRE:IsA("RemoteEvent") then
        lockRE.OnClientEvent:Connect(function(state, value)
            logAction("Lock State", true, tostring(state) .. " | " .. tostring(value))
            if State.AutoDefense then
                if state == "locked" then
                    State.IsUnderAttack = true
                    triggerDefense(true)
                else
                    State.IsUnderAttack = false
                    triggerDefense(false)
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO LAUNCH (NUKE LAUNCH)
-- ============================================================
-- Dari spy: LaunchRequest → server → LaunchAllowed → kita → LaunchConfirm
local launchAllowed = false

pcall(function()
    local launchAllowedRE = RS:WaitForChild("NukeRemotes", 5) and RS.NukeRemotes:FindFirstChild("LaunchAllowed")
    if launchAllowedRE and launchAllowedRE:IsA("RemoteEvent") then
        launchAllowedRE.OnClientEvent:Connect(function(...)
            launchAllowed = true
            logAction("Launch", true, "Server setujui launch!")
            if State.AutoLaunch then
                task.delay(0.1, function()
                    local confirmRE = resolveRemote("ConfirmOPLaunch")
                    if confirmRE then
                        safeFire(confirmRE)
                        logAction("Launch", true, "ConfirmOPLaunch dikirim")
                    end
                end)
            end
        end)
    end
end)

-- ============================================================
-- GUI (WINDUI)
-- ============================================================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title   = "🐼 Panda Helper - Nuke Pro v2",
    Icon    = "zap",
    Theme   = "Dark",
    Size    = UDim2.fromOffset(560, 480),
    Transparent = false
})

local TabMain    = Window:Tab({ Title = "🏠 Main",     Icon = "home" })
local TabLaunch  = Window:Tab({ Title = "🚀 Launch",   Icon = "zap" })
local TabTools   = Window:Tab({ Title = "🔧 Tools",    Icon = "tool" })
local TabLogs    = Window:Tab({ Title = "📋 Logs",     Icon = "book" })

-- =====================
-- TAB MAIN
-- =====================
TabMain:Toggle({
    Title    = "⚡ Auto Merge Nuke",
    Default  = false,
    Callback = function(v)
        State.AutoMerge = v
        logAction("Menu", true, "Auto Merge " .. (v and "ON" or "OFF"))
    end
})

TabMain:Toggle({
    Title    = "😈 Steal Opponents' Nukes (Global)",
    Default  = false,
    Callback = function(v)
        State.StealNukes = v
        logAction("Menu", true, "Steal Nukes " .. (v and "ON" or "OFF"))
    end
})

TabMain:Toggle({
    Title    = "💰 Auto Collect Drop",
    Default  = false,
    Callback = function(v)
        State.AutoCollect = v
        logAction("Menu", true, "Auto Collect " .. (v and "ON" or "OFF"))
    end
})

TabMain:Toggle({
    Title    = "🛡️ Auto Defense",
    Default  = false,
    Callback = function(v)
        State.AutoDefense = v
        if not v then
            State.IsUnderAttack = false
            triggerDefense(false)
        end
        logAction("Menu", true, "Auto Defense " .. (v and "ON" or "OFF"))
    end
})

TabMain:Toggle({
    Title    = "🔄 Auto Rebirth",
    Default  = false,
    Callback = function(v)
        State.AutoRebirth = v
        logAction("Menu", true, "Auto Rebirth " .. (v and "ON" or "OFF"))
    end
})

TabMain:Divider()

TabMain:Label({ Title = "📊 Status" })
local statusPara = TabMain:Paragraph({ Title = "Game Status", Desc = "Idle" })

-- Update status setiap 2 detik
task.spawn(function()
    while task.wait(2) do
        if _G.PandaExecution ~= ExecutionID then break end
        pcall(function()
            local nukes = getAllNukes()
            local statusText = string.format(
                "Nukes: %d | Merges: %d | Level: %d\nHolding: %s | Attack: %s",
                #nukes, State.MergeCount, State.CurrentNukeLevel,
                State.IsHolding and "Ya" or "Tidak",
                State.IsUnderAttack and "⚠️ YA" or "Aman"
            )
            if statusPara and statusPara.SetDesc then
                statusPara:SetDesc(statusText)
            end
        end)
    end
end)

-- =====================
-- TAB LAUNCH
-- =====================
TabLaunch:Toggle({
    Title    = "🚀 Auto Confirm Launch",
    Default  = false,
    Callback = function(v)
        State.AutoLaunch = v
        logAction("Menu", true, "Auto Launch " .. (v and "ON" or "OFF"))
    end
})

TabLaunch:Divider()

TabLaunch:Button({
    Title    = "🚀 Manual: ConfirmOPLaunch",
    Callback = function()
        local remote = resolveRemote("ConfirmOPLaunch")
        if remote then
            safeFire(remote)
            logAction("Manual Launch", true, "ConfirmOPLaunch dikirim")
            windui:Notify({ Title = "Launch", Content = "ConfirmOPLaunch terkirim!", Duration = 3 })
        else
            logAction("Manual Launch", false, "Remote tidak ditemukan")
        end
    end
})

TabLaunch:Button({
    Title    = "🔒 Manual: Request Lock Base",
    Callback = function()
        local remote = resolveRemote("RequestLockBase")
        if remote then
            safeFire(remote)
            logAction("Manual", true, "RequestLockBase dikirim")
            windui:Notify({ Title = "Defense", Content = "Base dikunci!", Duration = 3 })
        else
            logAction("Manual", false, "RequestLockBase tidak ditemukan")
        end
    end
})

TabLaunch:Button({
    Title    = "💥 Manual: Satu Kali Merge",
    Callback = function()
        local nuke, dist = getNearestFreeNuke()
        if nuke then
            tweenTo(nuke.PrimaryPart.Position)
            local pickUpRE = resolveRemote("PickUp")
            local mergeRE = resolveRemote("MergeRequest")
            if pickUpRE and mergeRE then
                safeFire(pickUpRE, nuke)
                task.wait(0.2)
                safeFire(mergeRE, nuke)
                logAction("Manual Merge", true, "Mencoba merge (Bypass Tween)")
            end
        else
            logAction("Manual Merge", false, "Tidak ada nuke tersedia")
        end
    end
})

-- =====================
-- TAB TOOLS
-- =====================
TabTools:Button({
    Title    = "💵 Claim Offline Earnings",
    Callback = function()
        local r = resolveRemote("OfflineEarnings")
        if r then safeFire(r); logAction("Tool", true, "OfflineEarnings dikirim")
        else logAction("Tool", false, "OfflineEarnings tidak ditemukan") end
    end
})

TabTools:Button({
    Title    = "🏆 Claim Group Reward",
    Callback = function()
        local r = resolveRemote("ClaimGroupReward")
        if r then
            local result = safeInvoke(r)
            logAction("Tool", true, "ClaimGroupReward → " .. tostring(result))
        else
            logAction("Tool", false, "ClaimGroupReward tidak ditemukan")
        end
    end
})

TabTools:Button({
    Title    = "🏗️ Rebuild Done",
    Callback = function()
        local r = resolveRemote("RebuildDone")
        if r then safeFire(r); logAction("Tool", true, "RebuildDone dikirim")
        else logAction("Tool", false, "RebuildDone tidak ditemukan") end
    end
})

TabTools:Input({
    Title       = "🎟️ Redeem Code",
    Placeholder = "Masukkan kode...",
    Callback    = function(text)
        if text == "" then return end
        local r = resolveRemote("RedeemCode")
        if r then
            local result = safeInvoke(r, text)
            logAction("Redeem", result ~= nil, "Kode: " .. text .. " → " .. tostring(result))
            windui:Notify({ Title = "Redeem", Content = tostring(result), Duration = 4 })
        else
            logAction("Redeem", false, "Remote RedeemCode tidak ditemukan")
        end
    end
})

TabTools:Divider()

TabTools:Button({
    Title    = "🔍 Scan Semua Nuke di Workspace",
    Callback = function()
        local nukes = getAllNukes()
        logAction("Scan", true, "Ditemukan " .. #nukes .. " nuke(s) di workspace")
        windui:Notify({ Title = "Scan", Content = "Nuke count: " .. #nukes, Duration = 3 })
    end
})

TabTools:Button({
    Title    = "📡 Test Semua Remote (Ping)",
    Callback = function()
        local found, notFound = 0, 0
        for name, _ in pairs(REMOTE_PATHS) do
            local r = resolveRemote(name)
            if r then found = found + 1
            else notFound = notFound + 1 end
        end
        logAction("Remote Check", true, "Found: " .. found .. " | Missing: " .. notFound)
        windui:Notify({
            Title   = "Remote Check",
            Content = "✅ " .. found .. " remote ditemukan\n❌ " .. notFound .. " tidak ditemukan",
            Duration = 5
        })
    end
})

-- =====================
-- TAB LOGS
-- =====================
local LogDisplay = TabLogs:Paragraph({ Title = "Live Logs", Desc = "Menunggu aktivitas..." })

State.UpdateUIDisplay = function(msg)
    if LogDisplay and LogDisplay.SetDesc then
        LogDisplay:SetDesc(table.concat(logLines, "\n"))
    end
end

TabLogs:Button({
    Title    = "🗑️ Hapus Log",
    Callback = function()
        logLines = {}
        State.LiveLogs = "=== RESET ===\n"
        lastLogs = {}
        if LogDisplay and LogDisplay.SetDesc then LogDisplay:SetDesc("Log dihapus.") end
    end
})

TabLogs:Input({
    Title       = "💬 Kirim Pesan ke Webhook",
    Placeholder = "Ketik pesan...",
    Callback    = function(text)
        if text == "" then return end
        logAction("MANUAL MSG", true, text)
        windui:Notify({ Title = "Terkirim", Content = "Dicatat ke webhook.", Duration = 3 })
    end
})

-- ============================================================
-- SELESAI
-- ============================================================
Window:SelectTab(1)
windui:Notify({
    Title   = "🐼 Panda Helper",
    Content = "Nuke Pro v2 berhasil dimuat!\n" .. #helperKeys(REMOTE_PATHS) .. " remote dipetakan.",
    Duration = 5
})

logAction("System", true, "Script Nuke Pro v2 loaded | PlaceId: 128784467030899")
