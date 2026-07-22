-- =================================================================
-- MAIN LOADER: PANDA HUB (MODULAR VERSION)
-- =================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- 1. CLEANUP PREVIOUS EXECUTION (Mencegah Ghost Loop/Log & Duplicate GUI)
if getgenv().PandaHub and getgenv().PandaHub.Connections then
    for _, conn in ipairs(getgenv().PandaHub.Connections) do
        pcall(function() conn:Disconnect() end)
    end
end

pcall(function()
    if CoreGui:FindFirstChild("PandaHub") then CoreGui.PandaHub:Destroy() end
    if gethui and gethui():FindFirstChild("PandaHub") then gethui().PandaHub:Destroy() end
end)

-- 2. SETUP GLOBAL ENVIRONMENT
getgenv().PandaHub = {
    Connections = {},
    State = {
        -- Farm
        AuraHarvest = false, AuraKill = false, AutoClaimReward = false,
        AutoRespawn = false, AutoHeal = false, HealCooldown = 0.2, HealAmount = 5,
        AutoEat = false, EatCooldown = 30, AutoCook = false,
        -- Cheats
        AntiFallDamage = false, Noclip = false, Fly = false, FlySpeed = 16,
        FlingAura = false, FlingVelocity = 10000, AntiFling = false,
        FEInvisible = false, UndergroundMode = false,
        -- Builder
        PasteHeight = 20, CopyRadius = 200, DeleteRadius = 200,
        -- Info/Logs
        WebhookLogs = false, SpyTrace = false,
        -- Gift
        InfiniteDrop = false, AutoGift = false, IsLoopDropping = false,
        GiftTargets = {}, GiftRemote = nil, GiftArgs = nil,
        GiftTeleportDelay = 2, GiftDropDelay = 0.1,
        -- Combat/Aura
        AuraRadius = 40, AttackCooldown = 0.1, MultiHitCount = 10,
        SelectedPlayer = nil, LockFling = false, AutoLockKiller = false,
        -- Tracking
        LogQueue = {}, LastLogSend = tick()
    },
    UI = {}, -- Tempat menyimpan fungsi-fungsi UI (createToggle, createButton, dll)
    Tabs = {} -- Tempat menyimpan referensi tab-tab (farmTab, cheatsTab, dll)
}

-- Fungsi utility global untuk merekam connection
getgenv().PandaHub.track = function(conn)
    table.insert(getgenv().PandaHub.Connections, conn)
    return conn
end

-- LOGGING SYSTEM
local WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxy5F3vLrvEcKjN3fHFWZgaSm8AGAHiRX9gejqz6gsUAL3I-gO9G-mNipEGQnEt7gc/exec"
getgenv().PandaHub.logAction = function(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(getgenv().PandaHub.State.LogQueue, msg)
end

local function processLogQueue()
    local logQueue = getgenv().PandaHub.State.LogQueue
    if #logQueue == 0 then return end
    
    local payload = {
        content = table.concat(logQueue, "\n")
    }
    
    -- Clear queue
    getgenv().PandaHub.State.LogQueue = {}
    
    if not getgenv().PandaHub.State.WebhookLogs then return end

    local req = (syn and syn.request) or request or (http and http.request) or http_request
    if req then
        pcall(function()
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
end

coroutine.wrap(function()
    while true do
        wait(5)
        processLogQueue()
    end
end)()


local GITHUB_RAW_URL = "https://raw.githubusercontent.com/sandysamiaji/celah/main/"

local function loadModule(fileName)
    local success, err = pcall(function()
        loadstring(game:HttpGet(GITHUB_RAW_URL .. fileName))()
    end)
    if not success then
        warn("[PandaHub] Gagal meload " .. fileName .. ": " .. tostring(err))
    end
end

-- 3. LOAD UI FRAMEWORK
loadModule("tampilan_tarung_v1.lua")

-- 4. LOAD FEATURE MODULES
loadModule("tarung_menu_farm.lua")
loadModule("tarung_menu_cheats.lua")
loadModule("tarung_menu_teleport.lua")
loadModule("tarung_menu_builder.lua")
loadModule("tarung_menu_gift.lua")
loadModule("tarung_menu_info.lua")

print("[PandaHub] Berhasil di-load secara modular!")
