local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Bersihkan UI lama jika ada
local oldUI = CoreGui:FindFirstChild("SimpleNukeUI")
if oldUI then oldUI:Destroy() end

-- Buat UI Sangat Sederhana (Bawaan Roblox, Anti-Error)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleNukeUI"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 200)
Frame.Position = UDim2.new(0.5, -125, 0.8, -50)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(200, 50, 50)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Title.Text = "Nuke Auto Merge Sederhana"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local MergeBtn = Instance.new("TextButton")
MergeBtn.Size = UDim2.new(0.8, 0, 0, 30)
MergeBtn.Position = UDim2.new(0.1, 0, 0.25, 0)
MergeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
MergeBtn.Text = "Auto Merge: ON"
MergeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MergeBtn.Font = Enum.Font.SourceSansBold
MergeBtn.TextSize = 16
MergeBtn.Parent = Frame

local SpyBtn = Instance.new("TextButton")
SpyBtn.Size = UDim2.new(0.8, 0, 0, 30)
SpyBtn.Position = UDim2.new(0.1, 0, 0.50, 0)
SpyBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
SpyBtn.Text = "Spy Remotes: ON"
SpyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpyBtn.Font = Enum.Font.SourceSansBold
SpyBtn.TextSize = 16
SpyBtn.Parent = Frame

local DumpBtn = Instance.new("TextButton")
DumpBtn.Size = UDim2.new(0.8, 0, 0, 30)
DumpBtn.Position = UDim2.new(0.1, 0, 0.75, 0)
DumpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
DumpBtn.Text = "Dump Remote Tree"
DumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DumpBtn.Font = Enum.Font.SourceSansBold
DumpBtn.TextSize = 16
DumpBtn.Parent = Frame

_G.AutoMergeStatus = true
_G.SpyRemotesStatus = true

-- ============================================================
-- SYSTEM LOGGING & WEBHOOK
-- ============================================================
local HttpService = game:GetService("HttpService")
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
        sendBufferedLogs()
    end
end)

local lastLogs = {}
local function logAction(action, isSuccess, detail)
    local status = isSuccess and "SUKSES" or "GAGAL"
    local msg = string.format("[%s] %s | %s", status, action, tostring(detail))
    
    if lastLogs[action] == msg then return end
    lastLogs[action] = msg

    local fullMsg = os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg
    table.insert(logBuffer, fullMsg)
end

MergeBtn.MouseButton1Click:Connect(function()
    _G.AutoMergeStatus = not _G.AutoMergeStatus
    if _G.AutoMergeStatus then
        MergeBtn.Text = "Auto Merge: ON"
        MergeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        MergeBtn.Text = "Auto Merge: OFF"
        MergeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

SpyBtn.MouseButton1Click:Connect(function()
    _G.SpyRemotesStatus = not _G.SpyRemotesStatus
    if _G.SpyRemotesStatus then
        SpyBtn.Text = "Spy Remotes: ON"
        SpyBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
    else
        SpyBtn.Text = "Spy Remotes: OFF"
        SpyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

-- Fungsi untuk membaca text UI di dalam bom
local function getBombValue(nuke)
    local gui = nuke:FindFirstChildWhichIsA("SurfaceGui", true) or nuke:FindFirstChildWhichIsA("BillboardGui", true)
    if gui then
        local tl = gui:FindFirstChildWhichIsA("TextLabel", true)
        if tl then return tl.Text end
    end
    return "?"
end

-- ============================================================
-- REMOTE SPY & DUMP LOGIC
-- ============================================================
local typeOf = typeof or type
local hasHook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function"
local ignoreSpam = { ["Ping"] = true, ["Fps"] = true, ["Update"] = true, ["Accept"] = true, ["MousePos"] = true, ["Move"] = true }

local function formatArgs(...)
    local args = {...}
    local str = ""
    for i, v in ipairs(args) do
        local typeV = typeOf(v)
        if typeV == "Instance" then
            str = str .. "[" .. v.ClassName .. ":" .. v.Name .. "]"
        elseif typeV == "string" then
            str = str .. '"' .. v .. '"'
        elseif typeV == "Vector3" then
            str = str .. string.format("%.6f, %.6f, %.2f", v.X, v.Y, v.Z)
        elseif typeV == "table" then
            str = str .. tostring(v)
        else
            str = str .. tostring(v)
        end
        if i < #args then str = str .. ", " end
    end
    if str == "" then str = "none" end
    return str
end

if hasHook and not _G.NukeHooked then
    local ok, err = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") and _G.SpyRemotesStatus then
                local okName, name = pcall(function() return self.Name end)
                if okName and not ignoreSpam[name] then
                    local argStr = formatArgs(...)
                    local path = "Unknown"
                    pcall(function() path = self.Parent.Name .. "/" .. name end)
                    local logMsg = string.format("REMOTE | [C2S] %s | %s", name, argStr)
                    logAction("SPY", true, logMsg)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if ok then _G.NukeHooked = true end
end

local function setupS2CSpy(remote)
    if remote:IsA("RemoteEvent") and not _G.S2CHooked[remote] then
        _G.S2CHooked[remote] = true
        remote.OnClientEvent:Connect(function(...)
            if _G.SpyRemotesStatus then
                local name = remote.Name
                if not ignoreSpam[name] then
                    local argStr = formatArgs(...)
                    local logMsg = string.format("REMOTE | [S2C] %s | %s", name, argStr)
                    logAction("SPY", true, logMsg)
                end
            end
        end)
    end
end

if not _G.S2CHooked then
    _G.S2CHooked = {}
    local function scanAndHook(root)
        pcall(function()
            for _, r in ipairs(root:GetDescendants()) do
                if r:IsA("RemoteEvent") then setupS2CSpy(r) end
            end
        end)
    end
    scanAndHook(RS)
    RS.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") then setupS2CSpy(v) end
    end)
end

local function getAllRemotes(root, results)
    results = results or {}
    if not root or not root.GetChildren then return results end
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            table.insert(results, child)
        end
        getAllRemotes(child, results)
    end
    return results
end

DumpBtn.MouseButton1Click:Connect(function()
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
        
        if http_request then
            task.spawn(function()
                http_request({
                    Url = WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({content = fullText})
                })
            end)
            logAction("DUMP", true, "Dump " .. tostring(#remotes) .. " remotes sukses dikirim ke webhook")
        end
    end)
end)

-- Mencegah dobel loop jika di-execute ulang
local ExecutionID = tick()
_G.NukeLoopID = ExecutionID
_G.LastVal = nil

task.spawn(function()
    while task.wait(0.5) do
        if _G.NukeLoopID ~= ExecutionID then break end
        
        if _G.AutoMergeStatus then
            pcall(function()
                -- Mengambil remote sesuai dengan log terbaru Anda
                local pickUp = RS:FindFirstChild("NukeRemotes") and RS.NukeRemotes:FindFirstChild("PickUp")
                local drop = RS:FindFirstChild("NukeRemotes") and RS.NukeRemotes:FindFirstChild("Drop")
                
                local mergeReq = nil
                local pkgNet = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Remotes") and RS.Packages.Remotes:FindFirstChild("Networking")
                if pkgNet then
                    mergeReq = pkgNet:FindFirstChild("RE/Merge/MergeRequest")
                end

                if pickUp and drop and mergeReq then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if hrp then
                        -- Cek apakah kita sedang memegang bom (ada model bom di dalam karakter)
                        local heldBomb = nil
                        for _, v in ipairs(char:GetDescendants()) do
                            if v.Name == "Nuke" and (v:IsA("BasePart") or v:IsA("Model")) then
                                heldBomb = v
                                break
                            end
                        end
                        
                        -- Cek bom yang ada di lantai
                        local groundNukes = {}
                        for _, v in ipairs(workspace:GetDescendants()) do
                            if v.Name == "Nuke" and (v:IsA("BasePart") or v:IsA("Model")) and v.Parent ~= char then
                                local pos = v:IsA("Model") and v:GetPivot().Position or v.Position
                                local dist = (pos - hrp.Position).Magnitude
                                if dist < 150 then -- Jarak jangkauan ambil bom
                                    table.insert(groundNukes, {part = v, distance = dist})
                                end
                            end
                        end
                        
                        -- Urutkan dari yang terdekat
                        table.sort(groundNukes, function(a, b) return a.distance < b.distance end)
                        
                        if heldBomb then
                            -- Jika kita sedang pegang bom, cari pasangannya
                            local heldVal = _G.LastVal or getBombValue(heldBomb)
                            local targetMerge = nil
                            
                            for _, n in ipairs(groundNukes) do
                                if getBombValue(n.part) == heldVal then
                                    targetMerge = n.part
                                    break
                                end
                            end
                            
                            if targetMerge then
                                -- Teleport karakter ke bom target sebelum merge
                                local targetPos = targetMerge:IsA("Model") and targetMerge:GetPivot().Position or targetMerge.Position
                                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                                task.wait(0.1)

                                -- Gabungkan! Sesuai log: [C2S] RE/Merge/MergeRequest | [Model:Nuke]
                                mergeReq:FireServer(targetMerge)
                                logAction("Auto Merge", true, "Menggabungkan Nuke [" .. tostring(heldVal) .. "] via Teleport")
                                _G.LastVal = nil
                                task.wait(0.2)
                            else
                                -- Pasangan tidak ada, buang bom! Sesuai log: [C2S] Drop | 12 angka CFrame
                                drop:FireServer(hrp.CFrame:GetComponents())
                                logAction("Auto Merge", false, "Membuang Nuke [" .. tostring(heldVal) .. "] (pasangan hilang)")
                                _G.LastVal = nil
                                task.wait(0.5)
                            end
                        else
                            -- Jika tangan kosong, cari bom kembar di lantai lalu pungut salah satunya
                            local grouped = {}
                            for _, n in ipairs(groundNukes) do
                                local val = getBombValue(n.part)
                                if val ~= "?" then
                                    if not grouped[val] then grouped[val] = {} end
                                    table.insert(grouped[val], n.part)
                                end
                            end
                            
                            local targetPickUp = nil
                            for val, list in pairs(grouped) do
                                if #list >= 2 then
                                    targetPickUp = list[1]
                                    break
                                end
                            end
                            
                            if targetPickUp then
                                local val = getBombValue(targetPickUp)
                                _G.LastVal = val
                                
                                -- Teleport karakter ke bom kembar sebelum ambil
                                local targetPos = targetPickUp:IsA("Model") and targetPickUp:GetPivot().Position or targetPickUp.Position
                                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                                task.wait(0.1)

                                -- Pungut bom! Sesuai log: [C2S] PickUp | [Model:Nuke]
                                pickUp:FireServer(targetPickUp)
                                logAction("Auto Merge", true, "Teleport & Mengambil Nuke [" .. tostring(val) .. "]")
                            end
                        end
                    end
                end
            end)
        end
    end
end)
