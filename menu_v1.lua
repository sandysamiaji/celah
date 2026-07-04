local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local getgenv = getgenv or function() return _G end
local typeOf = typeof or type
local hasHook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function"
getgenv().autoMerge = false
getgenv().autoCollect = false
getgenv().autoDefense = false
getgenv().isUnderAttack = false
getgenv().spyAllRemotes = false
getgenv().logToWebhook = false
getgenv().ignoreSpam = {
    ["Ping"] = true,
    ["Fps"] = true,
    ["Update"] = true,
    ["Accept"] = true,
    ["MousePos"] = true
}

-- ==================== WEBHOOK LOGGER ====================
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
local http_request = request or http_request or (http and http.request) or syn and syn.request

getgenv().logBuffer = getgenv().logBuffer or {}

local function sendLog(logText)
    table.insert(getgenv().logBuffer, tostring(logText))
end

if not getgenv().LogLoopStarted then
    getgenv().LogLoopStarted = true
    coroutine.wrap(function()
        while true do
            wait(5)
            if #getgenv().logBuffer > 0 then
                -- Gabungkan semua isi buffer yang terkumpul dengan baris baru (enter)
                local combinedText = table.concat(getgenv().logBuffer, "\n")
                getgenv().logBuffer = {} -- Kosongkan buffer setelah disalin
                
                if http_request then
                    pcall(function()
                        http_request({
                            Url = WEBHOOK_URL,
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode({
                                content = combinedText
                            })
                        })
                    end)
                end
            end
        end
    end)()
end

-- Spy / Hook untuk mendeteksi remote yang ditembakkan secara manual
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

if hasHook and not getgenv().PandaHooked then
    local ok, err = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            
            if method == "FireServer" or method == "InvokeServer" then
                local okName, name = pcall(function() return self.Name end)
                if okName and getgenv().spyAllRemotes and not getgenv().ignoreSpam[name] then
                    local argStr = formatArgs(...)
                    local okTs, ts = pcall(function() return os.date("%Y-%m-%d %H:%M:%S") end)
                    ts = (okTs and ts) or "unknown-time"
                    local logMsg = string.format("[%s] [SPY] %s | %s\n      Args: %s", ts, method, name, argStr)
                    
                    -- Tampilkan langsung di F9 (Developer Console)
                    print(logMsg)
                    
                    -- Kirim ke Webhook jika fitur dinyalakan
                    if getgenv().logToWebhook then
                        sendLog(logMsg)
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if ok then
        getgenv().PandaHooked = true
    else
        sendLog("Failed to hook namecall: " .. tostring(err))
    end
elseif not hasHook then
    sendLog("hookmetamethod/getnamecallmethod not available in this environment")
end

-- ==================== LOGIC FUNCTIONS ====================
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

local function getFullPath(inst)
    local ok, fullName = pcall(function()
        if inst and inst.GetFullName then
            return inst:GetFullName()
        end
    end)
    return (ok and fullName) or tostring(inst.Name)
end

local function isRemoteInstance(inst)
    if not inst then
        return false
    end
    local ok, isRemote = pcall(function()
        return inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction")
    end)
    return ok and isRemote
end

local function getAllRemotes(root, results)
    results = results or {}
    if not root or not root.GetChildren then
        return results
    end

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
    if not root or not root.GetChildren then
        return results
    end

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

local function toggleBomb(state)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes then
            if state then
                if remotes:FindFirstChild("PickUp") then
                    local lvl, obj = getBestBombArg()
                    
                    if lvl > 0 then
                        pcall(function() remotes.PickUp:FireServer(lvl) end)
                        pcall(function() remotes.PickUp:FireServer(tostring(lvl)) end)
                    end
                    if obj then
                        pcall(function() remotes.PickUp:FireServer(obj) end)
                    end
                    pcall(function() remotes.PickUp:FireServer() end)
                end
            else
                if remotes:FindFirstChild("Drop") then remotes.Drop:FireServer() end
            end
        end
    end)
end

-- Deteksi serangan
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
    if remotes and remotes:FindFirstChild("LockStateUpdate") then
        remotes.LockStateUpdate.OnClientEvent:Connect(function(state)
            if getgenv().autoDefense then
                if state == "locked" then
                    getgenv().isUnderAttack = true
                    toggleBomb(true)
                else
                    getgenv().isUnderAttack = false
                    toggleBomb(false)
                end
            end
        end)
    end
end)

-- ==================== GUI CREATION ====================
local existingUI = nil
pcall(function() existingUI = CoreGui:FindFirstChild("PandaHelperUI") end)
if not existingUI then pcall(function() existingUI = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PandaHelperUI") end) end
if existingUI then existingUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PandaHelperUI"
local okCore = pcall(function() ScreenGui.Parent = CoreGui end)
if not okCore or not ScreenGui.Parent then
    pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
MainFrame.Size = UDim2.new(0, 200, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = " Panda Helper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BorderSizePixel = 0

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Title
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0

CloseBtn.MouseButton1Click:Connect(function()
    -- Matikan semua loop saat di-close
    getgenv().autoMerge = false
    getgenv().autoCollect = false
    getgenv().autoDefense = false
    ScreenGui:Destroy()
end)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Size = UDim2.new(1, 0, 1, -30)
ScrollFrame.Position = UDim2.new(0, 0, 0, 30)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 350)
ScrollFrame.ScrollBarThickness = 4

local List = Instance.new("UIListLayout")
List.Parent = ScrollFrame
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0, 5)
List.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function createToggle(name, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ScrollFrame
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 40, 40)
    btn.Text = name .. ": " .. (defaultState and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    
    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 40, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

local function createButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ScrollFrame
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    
    btn.MouseButton1Click:Connect(function()
        callback()
    end)
end

-- ==================== ADDING BUTTONS ====================
local pad = Instance.new("Frame", ScrollFrame)
pad.Size = UDim2.new(1,0,0,2)
pad.BackgroundTransparency = 1

createToggle("Auto Merge", false, function(Value)
    getgenv().autoMerge = Value
    coroutine.wrap(function()
        while getgenv().autoMerge do
            wait(1)
            if not getgenv().isUnderAttack then
                -- Safe fire helper with logging
                local function safeFire(remote, ...)
                    if not remote then
                        sendLog("safeFire: remote is nil")
                        return false
                    end
                    local ok, err = pcall(function() remote:FireServer(...) end)
                    if not ok then
                        sendLog("FireServer failed for " .. tostring(remote.Name) .. ": " .. tostring(err))
                    else
                        sendLog("FireServer succeeded for " .. tostring(remote.Name))
                    end
                    return ok
                end

                -- Search for any MergeRequest remote in ReplicatedStorage
                local mergeRemotes = findInstancesByNames(ReplicatedStorage, {"MergeRequest", "RE/Merge/MergeRequest"})
                if #mergeRemotes == 0 then
                    sendLog("Auto Merge: no MergeRequest remote found in ReplicatedStorage")
                else
                    for _, remote in ipairs(mergeRemotes) do
                        sendLog("Auto Merge: firing remote " .. tostring(remote.Name) .. " at " .. getFullPath(remote))
                        safeFire(remote)
                    end
                end
            end
        end
    end)()
end)

createToggle("Auto Touch Drops", false, function(Value)
    getgenv().autoCollect = Value
    coroutine.wrap(function()
        while getgenv().autoCollect do
            wait(0.5)
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("TouchTransmitter") then
                            if string.match(obj.Name, "RMB_") or obj.Name == "neon" then
                                firetouchinterest(hrp, obj, 0)
                                wait(0.01)
                                firetouchinterest(hrp, obj, 1)
                            end
                        end
                    end
                end
            end)
        end
    end)()
end)

createToggle("Auto Defense (Bomb)", false, function(Value)
    getgenv().autoDefense = Value
    if not Value then
        getgenv().isUnderAttack = false
        toggleBomb(false)
    end
end)

createToggle("Enable Remote Spy (F9)", false, function(Value)
    getgenv().spyAllRemotes = Value
end)

createToggle("Send Spy Logs to Webhook", false, function(Value)
    getgenv().logToWebhook = Value
end)

createButton("Confirm OP Launch", function()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes and remotes:FindFirstChild("ConfirmOPLaunch") then
            remotes.ConfirmOPLaunch:FireServer()
        end
    end)
end)

createButton("Claim Offline Earning", function()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes and remotes:FindFirstChild("OfflineEarnings") then
            remotes.OfflineEarnings:FireServer()
        end
    end)
end)

createButton("Rebuild Done", function()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if remotes and remotes:FindFirstChild("RebuildDone") then
            remotes.RebuildDone:FireServer()
        end
    end)
end)

local function dumpInstance(inst, depth, lines)
    depth = depth or 0
    lines = lines or {}
    local path = getFullPath(inst)
    table.insert(lines, string.rep("  ", depth) .. "- " .. tostring(inst.Name) .. " (" .. tostring(inst.ClassName) .. ") [" .. tostring(path) .. "]")
    for _, c in ipairs(inst:GetChildren()) do
        dumpInstance(c, depth + 1, lines)
    end
    return lines
end

local function dumpRemote(remote)
    local path = getFullPath(remote)
    local class = tostring(remote.ClassName or "Unknown")
    return string.format("- %s (%s) [%s]", tostring(remote.Name), class, tostring(path))
end

createButton("Dump Remotes", function()
    pcall(function()
        local lines = {}
        local ok, err = pcall(function()
            table.insert(lines, "=== ReplicatedStorage Remotes ===")
            for _, remote in ipairs(getAllRemotes(ReplicatedStorage, {})) do
                table.insert(lines, dumpRemote(remote))
            end

            local pkgs = ReplicatedStorage:FindFirstChild("Packages")
            if pkgs then
                table.insert(lines, "=== Packages Remotes ===")
                for _, remote in ipairs(getAllRemotes(pkgs, {})) do
                    table.insert(lines, dumpRemote(remote))
                end
            else
                table.insert(lines, "Packages not found in ReplicatedStorage")
            end
        end)

        if not ok then
            sendLog("Dump Remotes failed: " .. tostring(err))
        else
            sendLog("=== Dump Remotes ===\n" .. table.concat(lines, "\n"))
        end
    end)
end)

createButton("Scan All Remotes", function()
    pcall(function()
        local lines = {}
        local remotes = getAllRemotes(game, {})
        table.insert(lines, "=== All Active Remotes ===")
        if #remotes == 0 then
            table.insert(lines, "No remotes found")
        else
            for _, remote in ipairs(remotes) do
                table.insert(lines, dumpRemote(remote))
            end
        end
        sendLog(table.concat(lines, "\n"))
    end)
end)

createButton("Test MergeRequest", function()
    pcall(function()
        local mergeRemotes = findInstancesByNames(ReplicatedStorage, {"MergeRequest", "RE/Merge/MergeRequest"})
        if #mergeRemotes == 0 then
            sendLog("Test MergeRequest: no MergeRequest remote found")
            return
        end

        for _, remote in ipairs(mergeRemotes) do
            local path = getFullPath(remote)
            sendLog("Test MergeRequest: firing " .. tostring(remote.Name) .. " at " .. path)
            local ok, err = pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer()
                else
                    remote:FireServer()
                end
            end)
            if not ok then
                sendLog("Test MergeRequest failed: " .. tostring(err))
            else
                sendLog("Test MergeRequest sent successfully to " .. path)
            end
        end
    end)
end)
