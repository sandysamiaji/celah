-- ============================================================
-- Nuke Game - Auto Farm & Exploit (Mr. Panda)
-- V8: Nuke Features Edition
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Variabel Toggle & Eksekusi
local ExecutionID = tick()
_G.NukeGameExecution = ExecutionID

local _G_State = {}
_G_State.AutoMerge = false
_G_State.MergeDelay = 0.5
_G_State.AutoCollect = false
_G_State.AutoDefense = false
_G_State.SpyRemotes = false
_G_State.LogEnabled = true
_G_State.LiveLogs = "=== NUKE GAME LIVE LOGS ===\n"

local typeOf = typeof or type
local hasHook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function"
local ignoreSpam = {
    ["Ping"] = true,
    ["Fps"] = true,
    ["Update"] = true,
    ["Accept"] = true,
    ["MousePos"] = true,
    ["Move"] = true
}

-- ============================================================
-- SYSTEM LOGGING & WEBHOOK
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
        pcall(function() http_request({ Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({content = combinedLogs}) }) end)
    end)
end

task.spawn(function()
    while task.wait(5) do
        if _G.NukeGameExecution ~= ExecutionID then break end
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
    
    if _G_State.UpdateUIDisplay then pcall(function() _G_State.UpdateUIDisplay(msg) end) end
    if #_G_State.LiveLogs > 50000 then _G_State.LiveLogs = string.sub(_G_State.LiveLogs, -40000) end
end

local function safeFire(remote, ...)
    if not remote then return false end
    local ok, err = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        else
            remote:FireServer(...)
        end
    end, ...)
    if not ok then
        logAction("Remote Fire", false, "Gagal menembakkan " .. remote.Name .. ": " .. tostring(err))
    end
    return ok
end

local function isRemoteInstance(inst)
    if not inst then return false end
    local ok, isRemote = pcall(function() return inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") end)
    return ok and isRemote
end

local function getAllRemotes(root, results)
    results = results or {}
    if not root or not root.GetChildren then return results end
    for _, child in ipairs(root:GetChildren()) do
        if isRemoteInstance(child) then
            table.insert(results, child)
        end
        getAllRemotes(child, results)
    end
    return results
end

local function findInstancesByNames(root, names, results)
    results = results or {}
    if not root or not root.GetChildren then return results end
    for _, child in ipairs(root:GetChildren()) do
        for _, targetName in ipairs(names) do
            if child.Name == targetName then
                table.insert(results, child)
                break
            end
        end
        findInstancesByNames(child, names, results)
    end
    return results
end

-- ============================================================
-- REMOTE SPY & BOMB SENSOR
-- ============================================================
local function formatArgs(...)
    local args = {...}
    local str = ""
    for i, v in ipairs(args) do
        local typeV = typeOf(v)
        if typeV == "Instance" then
            str = str .. "Instance("..v.Name..")"
        elseif typeV == "string" then
            str = str .. '"' .. v .. '"'
        elseif typeV == "Vector3" then
            str = str .. "Vector3("..tostring(v)..")"
        elseif typeV == "table" then
            str = str .. "{...}"
        else
            str = str .. tostring(v)
        end
        if i < #args then str = str .. ", " end
    end
    return str
end

local function getFullPath(obj)
    local path = obj.Name
    local p = obj.Parent
    while p and p ~= game do
        path = p.Name .. "." .. path
        p = p.Parent
    end
    return path
end

if hasHook and not _G.NukeHooked then
    local ok, err = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local okName, name = pcall(function() return self.Name end)
                if okName and _G_State.SpyRemotes and not ignoreSpam[name] then
                    local argStr = formatArgs(...)
                    local fullPath = pcall(getFullPath, self) and getFullPath(self) or name
                    local logMsg = string.format("[SPY] C2S (%s) | %s | %s", method, fullPath, argStr)
                    logAction("REMOTE", true, logMsg)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if ok then
        _G.NukeHooked = true
    end
end

-- ============================================================
-- S2C SPY (SERVER TO CLIENT)
-- ============================================================
local function setupS2CSpy(remote)
    if remote:IsA("RemoteEvent") then
        if _G.S2CHooked_List[remote] then return end
        _G.S2CHooked_List[remote] = true
        
        remote.OnClientEvent:Connect(function(...)
            if _G_State.SpyRemotes then
                local name = remote.Name
                if not ignoreSpam[name] then
                    local argStr = formatArgs(...)
                    local fullPath = pcall(getFullPath, remote) and getFullPath(remote) or name
                    local logMsg = string.format("[SPY] S2C (OnClientEvent) | %s | %s", fullPath, argStr)
                    logAction("REMOTE", true, logMsg)
                end
            end
        end)
    end
end

if not _G.S2CHooked_List then
    _G.S2CHooked_List = {}
    -- Cari semua remote di RS & Workspace
    local function scanAndHook(root)
        pcall(function()
            for _, r in ipairs(root:GetDescendants()) do
                if isRemoteInstance(r) then setupS2CSpy(r) end
            end
        end)
    end
    scanAndHook(RS)
    scanAndHook(workspace)
    
    -- Pantau jika ada remote baru
    RS.DescendantAdded:Connect(function(v)
        if isRemoteInstance(v) then setupS2CSpy(v) end
    end)
    workspace.DescendantAdded:Connect(function(v)
        if isRemoteInstance(v) then setupS2CSpy(v) end
    end)
end

local function getBombValue(nuke)
    local gui = nuke:FindFirstChildWhichIsA("SurfaceGui") or nuke:FindFirstChildWhichIsA("BillboardGui")
    if gui then
        local tl = gui:FindFirstChildWhichIsA("TextLabel", true)
        if tl then return tl.Text end
    end
    return "?"
end

-- Deteksi Bom Muncul
if not _G.NukeSensor then
    _G.NukeSensor = true
    workspace.DescendantAdded:Connect(function(v)
        if v.Name == "Nuke" and v:IsA("BasePart") then
            -- Tunggu sebentar agar posisi bom update & UI termuat
            task.delay(1.0, function()
                local val = getBombValue(v)
                local pos = string.format("X:%.1f, Y:%.1f, Z:%.1f", v.Position.X, v.Position.Y, v.Position.Z)
                logAction("BOMB SPAWN", true, "Nuke [" .. val .. "] terdeteksi di " .. pos)
            end)
        end
    end)
end

-- ============================================================
-- MAIN LOOP: AUTO MERGE & AUTO COLLECT
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.NukeGameExecution ~= ExecutionID then break end
        
        -- AUTO MERGE
        if _G_State.AutoMerge and not _G_State.IsUnderAttack then
            -- BERDASARKAN LOG SPY: 
            -- PickUp yang bekerja ada di NukeRemotes
            -- MergeRequest yang menghasilkan efek (MergeVFX) ada di Packages.Remotes.Networking
            
            local pickUp
            if RS:FindFirstChild("NukeRemotes") then
                pickUp = RS.NukeRemotes:FindFirstChild("PickUp")
            end
            
            local mergeReq
            local pkgNet = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Remotes") and RS.Packages.Remotes:FindFirstChild("Networking")
            if pkgNet then
                mergeReq = pkgNet:FindFirstChild("RE/Merge/MergeRequest")
            end
            
            -- Fallback jika game update
            if not mergeReq and RS:FindFirstChild("NukeRemotes") then
                mergeReq = RS.NukeRemotes:FindFirstChild("MergeRequest")
            end
            
            if pickUp and mergeReq then
                local char = Players.LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    -- Cek apakah kita sedang memegang bom di tangan
                    local heldBomb = nil
                    for _, v in ipairs(char:GetDescendants()) do
                        if v.Name == "Nuke" and v:IsA("BasePart") then
                            heldBomb = v
                            break
                        end
                    end
                    
                    -- Kumpulkan semua bom di tanah (bukan di tangan) dalam radius 150
                    local groundNukes = {}
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v.Name == "Nuke" and v:IsA("BasePart") and v.Parent ~= char then
                            if (v.Position - hrp.Position).Magnitude < 150 then
                                table.insert(groundNukes, v)
                            end
                        end
                    end
                    
                    if heldBomb then
                        local heldVal = getBombValue(heldBomb)
                        -- Cari bom di tanah dengan nilai yang sama
                        local targetMerge = nil
                        for _, n in ipairs(groundNukes) do
                            if getBombValue(n) == heldVal then
                                targetMerge = n
                                break
                            end
                        end
                        
                        if targetMerge then
                            local origCFrame = hrp.CFrame
                            hrp.Anchored = true
                            hrp.CFrame = targetMerge.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.25) -- Tunggu sinkronisasi server (bypass anti-cheat jarak)
                            safeFire(mergeReq, targetMerge)
                            task.wait(0.1)
                            hrp.CFrame = origCFrame
                            hrp.Anchored = false
                            logAction("Auto Merge", true, "Menggabungkan Nuke [" .. heldVal .. "] dari jarak jauh")
                        end
                    else
                        -- Kelompokkan bom di tanah
                        local grouped = {}
                        for _, n in ipairs(groundNukes) do
                            local val = getBombValue(n)
                            if val ~= "?" then
                                if not grouped[val] then grouped[val] = {} end
                                table.insert(grouped[val], n)
                            end
                        end
                        
                        local targetPickUp = nil
                        -- Prioritas 1: Ambil bom yang sudah ada pasangannya di tanah
                        for val, list in pairs(grouped) do
                            if #list >= 2 then
                                targetPickUp = list[1]
                                break
                            end
                        end
                        
                        -- Prioritas 2: Jika tidak ada pasangan, ambil bom apa saja untuk 'di-hold'
                        if not targetPickUp then
                            for val, list in pairs(grouped) do
                                if #list == 1 then
                                    targetPickUp = list[1]
                                    break
                                end
                            end
                        end
                        
                        if targetPickUp then
                            local origCFrame = hrp.CFrame
                            hrp.Anchored = true
                            hrp.CFrame = targetPickUp.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.25) -- Tunggu sinkronisasi server
                            safeFire(pickUp, targetPickUp)
                            task.wait(0.1)
                            hrp.CFrame = origCFrame
                            hrp.Anchored = false
                            logAction("Auto Merge", true, "Mengambil Nuke [" .. getBombValue(targetPickUp) .. "] ke tangan")
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.NukeGameExecution ~= ExecutionID then break end
        
        -- AUTO COLLECT (TOUCH DROPS)
        if _G_State.AutoCollect then
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    local collectCount = 0
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("TouchTransmitter") then
                            local n = string.lower(obj.Name)
                            -- Deteksi: 
                            -- 1. Part tidak di-anchor (biasanya item drop fisik yang jatuh ke tanah)
                            -- 2. Nama part mengandung unsur uang/tombol klaim tycoon
                            local isDrop = not obj.Anchored
                            local isButton = string.find(n, "rmb") or string.find(n, "neon") or string.find(n, "coin") or string.find(n, "cash") or string.find(n, "money") or string.find(n, "drop") or string.find(n, "collect") or string.find(n, "claim") or string.find(n, "giver") or string.find(n, "reward")
                            
                            if isDrop or isButton then
                                local origCFrame = hrp.CFrame
                                hrp.Anchored = true
                                -- Blink teleport ke objek uang
                                hrp.CFrame = obj.CFrame + Vector3.new(0, 1, 0)
                                task.wait(0.1) -- Tunggu server mendaftarkan posisi baru
                                
                                firetouchinterest(hrp, obj, 0)
                                task.wait(0.01)
                                firetouchinterest(hrp, obj, 1)
                                
                                -- Kembali ke posisi awal
                                hrp.CFrame = origCFrame
                                hrp.Anchored = false
                                collectCount = collectCount + 1
                                task.wait(0.1) -- Jeda antar koleksi
                            end
                        end
                    end
                    if collectCount > 0 then
                        logAction("Auto Collect", true, "Menyentuh " .. tostring(collectCount) .. " drop items")
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- AUTO DEFENSE
-- ============================================================
local function getBestBombArg()
    local maxLvl = 0
    local bestObj = nil
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and tonumber(v.Name) then
            local lvl = tonumber(v.Name)
            if lvl > maxLvl then
                maxLvl = lvl
                bestObj = v
            end
        end
    end
    return maxLvl, bestObj
end

local function toggleBomb(state)
    pcall(function()
        local remotes = RS:FindFirstChild("NukeRemotes") or RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Remotes") and RS.Packages.Remotes:FindFirstChild("Networking")
        if remotes then
            -- Mencoba berbagai kemungkinan letak remote Drop/PickUp
            local pickUp = remotes:FindFirstChild("PickUp") or findInstancesByNames(RS, {"PickUp", "RE/Pickup/PickUp"})[1]
            local drop = remotes:FindFirstChild("Drop") or findInstancesByNames(RS, {"Drop", "RE/Pickup/Drop"})[1]
            
            if state then
                if pickUp then
                    local lvl, obj = getBestBombArg()
                    if lvl > 0 then
                        safeFire(pickUp, lvl)
                        safeFire(pickUp, tostring(lvl))
                    end
                    if obj then
                        safeFire(pickUp, obj)
                    end
                    safeFire(pickUp)
                    logAction("Defense", true, "Mengaktifkan pertahanan (PickUp bom)")
                end
            else
                if drop then 
                    safeFire(drop) 
                    logAction("Defense", true, "Menonaktifkan pertahanan (Drop bom)")
                end
            end
        end
    end)
end

pcall(function()
    local lockStateRemotes = findInstancesByNames(RS, {"LockStateUpdate", "RE/Combat/LockStateUpdate"})
    for _, remote in ipairs(lockStateRemotes) do
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(state)
                if _G_State.AutoDefense then
                    if state == "locked" then
                        _G_State.IsUnderAttack = true
                        toggleBomb(true)
                    else
                        _G_State.IsUnderAttack = false
                        toggleBomb(false)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- GUI (WINDUI)
-- ============================================================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title = "Panda Helper - Nuke Edition",
    Icon = "box",
    Theme = "Dark",
    Size = UDim2.fromOffset(530, 420),
    Transparent = false
})

local TabMain = Window:Tab({ Title = "Main Features", Icon = "home" })
local TabRemotes = Window:Tab({ Title = "Remote Spy & Action", Icon = "terminal" })
local TabLogs = Window:Tab({ Title = "Live Logs", Icon = "book" })

-- TAB MAIN
TabMain:Toggle({ 
    Title = "⚡ Auto Merge Nuke", 
    Default = false, 
    Callback = function(state) 
        _G_State.AutoMerge = state
        logAction("Menu", true, "Auto Merge " .. (state and "ON" or "OFF")) 
    end 
})

TabMain:Slider({
    Title = "⏱️ Kecepatan Merge (0.1s - 1.0s)",
    Step = 1,
    Min = 1,
    Max = 10,
    Default = 5,
    Callback = function(value)
        _G_State.MergeDelay = value / 10
        logAction("Menu", true, "Kecepatan diubah ke " .. tostring(_G_State.MergeDelay) .. " detik")
    end
})

TabMain:Toggle({ 
    Title = "💰 Auto Touch Drops (Koleksi Reward)", 
    Default = false, 
    Callback = function(state) 
        _G_State.AutoCollect = state 
        logAction("Menu", true, "Auto Collect " .. (state and "ON" or "OFF")) 
    end 
})

TabMain:Toggle({ 
    Title = "🛡️ Auto Defense (Berlindung di Bom)", 
    Default = false, 
    Callback = function(state) 
        _G_State.AutoDefense = state
        if not state then
            _G_State.IsUnderAttack = false
            toggleBomb(false)
        end
        logAction("Menu", true, "Auto Defense " .. (state and "ON" or "OFF")) 
    end 
})

TabMain:Divider()

TabMain:Button({
    Title = "🚀 Confirm OP Launch",
    Callback = function()
        pcall(function()
            local launch = findInstancesByNames(RS, {"ConfirmOPLaunch", "RE/Launch/ConfirmOPLaunch"})[1]
            if launch then
                safeFire(launch)
                logAction("Manual", true, "ConfirmOPLaunch ditekan")
            else
                logAction("Manual", false, "Remote ConfirmOPLaunch tidak ditemukan")
            end
        end)
    end
})

TabMain:Button({
    Title = "💵 Claim Offline Earning",
    Callback = function()
        pcall(function()
            local offline = findInstancesByNames(RS, {"OfflineEarnings"})[1]
            if offline then
                safeFire(offline)
                logAction("Manual", true, "OfflineEarnings ditekan")
            else
                logAction("Manual", false, "Remote OfflineEarnings tidak ditemukan")
            end
        end)
    end
})

TabMain:Button({
    Title = "🏗️ Rebuild Done",
    Callback = function()
        pcall(function()
            local rebuild = findInstancesByNames(RS, {"RebuildDone"})[1]
            if rebuild then
                safeFire(rebuild)
                logAction("Manual", true, "RebuildDone ditekan")
            else
                logAction("Manual", false, "Remote RebuildDone tidak ditemukan")
            end
        end)
    end
})

TabMain:Divider()

TabMain:Button({
    Title = "💰 Force Infinite Money (Eksploit) ⚠️",
    Callback = function()
        pcall(function()
            local offline = RS:FindFirstChild("NukeRemotes") and RS.NukeRemotes:FindFirstChild("OfflineEarnings")
            local group = RS:FindFirstChild("NukeRemotes") and RS.NukeRemotes:FindFirstChild("ClaimGroupReward")
            local city = RS:FindFirstChild("NukeRemotes") and RS.NukeRemotes:FindFirstChild("CityRewardPaid")
            
            -- Cari bom dengan level tertinggi di workspace (berdasarkan atribut/nama angka)
            local maxLvl = 0
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and tonumber(v.Name) then
                    local lvl = tonumber(v.Name)
                    if lvl > maxLvl then
                        maxLvl = lvl
                    end
                end
            end
            
            -- Jika tidak ada bom, gunakan default 1000
            local baseLvl = maxLvl > 0 and maxLvl or 1000
            local massiveMoney = baseLvl
            
            -- Fungsi untuk mendapatkan jumlah uang pemain saat ini
            local function getCurrentMoney()
                local p = Players.LocalPlayer
                if p and p:FindFirstChild("leaderstats") then
                    for _, stat in ipairs(p.leaderstats:GetChildren()) do
                        if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                            local n = string.lower(stat.Name)
                            if string.find(n, "cash") or string.find(n, "money") or string.find(n, "coin") or string.find(n, "point") or string.find(n, "nuke") then
                                return stat.Value
                            end
                        end
                    end
                end
                return 0 -- Return 0 jika leaderstats tidak ditemukan
            end
            
            local startingMoney = getCurrentMoney()
            
            -- Kirimkan permintaan hadiah sebanyak 900 kali secara terpisah (seolah-olah 900 kali hit beruntun)
            task.spawn(function()
                logAction("Eksploit", true, "Memulai eksploit uang (900x hit beruntun)... Saldo Awal: " .. tostring(startingMoney))
                
                for i = 1, 900 do
                    if not _G_State.SpyRemotes then -- Opsional: Tambahkan kill-switch ke depannya jika butuh
                        -- Kita jalankan loop tanpa kill switch khusus, tapi biarkan player tetap bisa main
                    end
                    
                    if offline then
                        safeFire(offline, massiveMoney)
                        safeFire(offline, tostring(massiveMoney))
                    end
                    
                    if group then
                        safeFire(group, massiveMoney)
                    end
                    
                    if city then
                        safeFire(city, massiveMoney)
                    end
                    
                    task.wait(0.01) -- Jeda super cepat agar 900 hit selesai dalam 9 detik
                end
                
                -- Tunggu sebentar agar server memproses sisa antrian
                task.wait(1)
                
                local endingMoney = getCurrentMoney()
                local profit = endingMoney - startingMoney
                
                if profit > 0 then
                    logAction("Eksploit", true, "BERHASIL! 🤑 Uang Bertambah: " .. tostring(profit) .. " | Saldo Akhir: " .. tostring(endingMoney))
                else
                    logAction("Eksploit", false, "GAGAL! ❌ Server Anti-Cheat menolak eksploit. Saldo tetap: " .. tostring(endingMoney))
                end
            end)
        end)
    end
})

-- TAB REMOTES
TabRemotes:Toggle({ 
    Title = "👁️ Enable Remote Spy (Hook)", 
    Default = false, 
    Callback = function(state) 
        _G_State.SpyRemotes = state
        logAction("Menu", true, "Remote Spy " .. (state and "ON" or "OFF")) 
    end 
})

TabRemotes:Divider()

TabRemotes:Button({
    Title = "🖨️ Dump Remotes (Game Spy Pro)",
    Callback = function()
        pcall(function()
            local remotes = getAllRemotes(RS, {})
            local grouped = {}
            for _, r in ipairs(remotes) do
                local parentPath = "Unknown"
                pcall(function() parentPath = r.Parent:GetFullName() end)
                if not grouped[parentPath] then grouped[parentPath] = {} end
                table.insert(grouped[parentPath], r)
            end
            
            local lines = {}
            table.insert(lines, "=== INITIAL FULL REMOTE REPORT ===")
            table.insert(lines, "===============================================")
            table.insert(lines, "        GAME SPY & REMOTE EXPLORER PRO         ")
            table.insert(lines, "              by Mr. Panda                  ")
            table.insert(lines, "===============================================")
            table.insert(lines, "")
            table.insert(lines, "PlaceId: " .. tostring(game.PlaceId))
            table.insert(lines, "Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))
            table.insert(lines, "")
            table.insert(lines, "=== 1. STRUKTUR REMOTE (LOKASI) ===")
            table.insert(lines, "TOTAL: " .. tostring(#remotes) .. " remote(s) ditemukan.\n")
            
            for parentPath, remoteList in pairs(grouped) do
                table.insert(lines, "[ " .. parentPath .. " ]")
                for _, r in ipairs(remoteList) do
                    local icon = r:IsA("RemoteEvent") and "🟢 RE " or "🟡 RF "
                    local rName = "Unknown"
                    local rFull = "Unknown"
                    pcall(function() rName = r.Name; rFull = r:GetFullName() end)
                    table.insert(lines, "  " .. icon .. " " .. rName)
                    table.insert(lines, "       " .. rFull)
                end
                table.insert(lines, "")
            end
            
            local fullText = table.concat(lines, "\n")
            logAction("DUMP", true, "Mencetak " .. tostring(#remotes) .. " remotes ke Webhook")
            
            -- Kirim langsung ke webhook
            if http_request then
                task.spawn(function()
                    http_request({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode({content = fullText})
                    })
                end)
            end
        end)
    end
})

TabRemotes:Button({
    Title = "🔍 Scan All Remotes (Seluruh Game)",
    Callback = function()
        pcall(function()
            local remotes = getAllRemotes(game, {})
            logAction("SCAN", true, "Ditemukan " .. tostring(#remotes) .. " remotes di seluruh game. (Gunakan Dump untuk melihat detail)")
        end)
    end
})

TabRemotes:Button({
    Title = "🔍 Test MergeRequest (Force)",
    Callback = function()
        local mergeRemotes = findInstancesByNames(RS, {"MergeRequest", "RE/Merge/MergeRequest"})
        if #mergeRemotes == 0 then
            logAction("Test Remote", false, "MergeRequest tidak ditemukan")
            return
        end
        
        local targetNuke = nil
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Nuke" and v:IsA("BasePart") then
                targetNuke = v
                break
            end
        end
        
        if not targetNuke then
            logAction("Test Remote", false, "Gagal test, tidak ada Nuke di workspace")
            return
        end

        for _, remote in ipairs(mergeRemotes) do
            local path = remote:GetFullName()
            local ok = safeFire(remote, targetNuke)
            if ok then
                logAction("Test Remote", true, "MergeRequest dikirim ke " .. path)
            end
        end
    end
})

-- TAB LOGS
local LogDisplay = TabLogs:Paragraph({ Title = "Live Logs (Terbaru)", Desc = "Memuat log..." })
local logLines = {}
_G_State.UpdateUIDisplay = function(newMsg)
    table.insert(logLines, newMsg)
    if #logLines > 8 then table.remove(logLines, 1) end
    if LogDisplay and LogDisplay.SetDesc then LogDisplay:SetDesc(table.concat(logLines, "\n")) end
end

TabLogs:Input({
    Title = "Kirim Command / Test",
    Placeholder = "Ketik sesuatu...",
    Callback = function(text)
        if text == "" then return end
        logAction("COMMAND", true, text)
        windui:Notify({Title = "Terkirim", Content = "Dicatat ke Webhook.", Duration = 3})
    end
})

Window:SelectTab(1)
windui:Notify({ Title = "Panda Helper", Content = "Script Nuke v8 Berhasil Dimuat!", Duration = 5 })
