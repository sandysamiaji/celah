import sys

with open('d:\\PROJECT_SANDY\\iseng lua\\menu_v1.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_ui = """-- ==================== GUI CREATION (WINDUI) ====================
local windui = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandysamiaji/celah/main/tampilan.lua"))()

local Window = windui:CreateWindow({
    Title = "Panda Helper",
    Icon = "box",
    Theme = "Dark",
    Size = UDim2.fromOffset(530, 420),
    Transparent = false
})

local TabMain = Window:Tab({ Title = "Main Features", Icon = "home" })
local TabRemotes = Window:Tab({ Title = "Remote Spy", Icon = "terminal" })

TabMain:Toggle({
    Title = "Auto Merge",
    Default = false,
    Callback = function(Value)
        getgenv().autoMerge = Value
        coroutine.wrap(function()
            while getgenv().autoMerge do
                wait(1)
                if not getgenv().isUnderAttack then
                    local function safeFire(remote, ...)
                        if not remote then return false end
                        local ok, err = pcall(function() remote:FireServer(...) end)
                        return ok
                    end

                    local mergeRemotes = findInstancesByNames(ReplicatedStorage, {"MergeRequest", "RE/Merge/MergeRequest"})
                    if #mergeRemotes > 0 then
                        local nukes = {}
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v.Name == "Nuke" and v:IsA("BasePart") then
                                table.insert(nukes, v)
                            end
                        end
                        
                        for _, remote in ipairs(mergeRemotes) do
                            for _, nuke in ipairs(nukes) do
                                safeFire(remote, nuke)
                                if not getgenv().autoMerge then break end
                            end
                        end
                    end
                end
            end
        end)()
    end
})

TabMain:Toggle({
    Title = "Auto Touch Drops",
    Default = false,
    Callback = function(Value)
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
    end
})

TabMain:Toggle({
    Title = "Auto Defense (Bomb)",
    Default = false,
    Callback = function(Value)
        getgenv().autoDefense = Value
        if not Value then
            getgenv().isUnderAttack = false
            toggleBomb(false)
        end
    end
})

TabMain:Button({
    Title = "Confirm OP Launch",
    Callback = function()
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if remotes and remotes:FindFirstChild("ConfirmOPLaunch") then
                remotes.ConfirmOPLaunch:FireServer()
            end
        end)
    end
})

TabMain:Button({
    Title = "Claim Offline Earning",
    Callback = function()
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if remotes and remotes:FindFirstChild("OfflineEarnings") then
                remotes.OfflineEarnings:FireServer()
            end
        end)
    end
})

TabMain:Button({
    Title = "Rebuild Done",
    Callback = function()
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
            if remotes and remotes:FindFirstChild("RebuildDone") then
                remotes.RebuildDone:FireServer()
            end
        end)
    end
})

TabRemotes:Toggle({
    Title = "Enable Remote Spy (F9)",
    Default = false,
    Callback = function(Value)
        getgenv().spyAllRemotes = Value
    end
})

TabRemotes:Toggle({
    Title = "Send Spy Logs to Webhook",
    Default = false,
    Callback = function(Value)
        getgenv().logToWebhook = Value
    end
})

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

TabRemotes:Button({
    Title = "Dump Remotes",
    Callback = function()
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
                sendLog("=== Dump Remotes ===\\n" .. table.concat(lines, "\\n"))
            end
        end)
    end
})

TabRemotes:Button({
    Title = "Scan All Remotes",
    Callback = function()
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
            sendLog(table.concat(lines, "\\n"))
        end)
    end
})

TabRemotes:Button({
    Title = "Test MergeRequest",
    Callback = function()
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
    end
})
"""

with open('d:\\PROJECT_SANDY\\iseng lua\\menu_v1.lua', 'w', encoding='utf-8') as f:
    f.writelines(lines[:227])
    f.write(new_ui)
