-- ==========================================
-- MENU ANTI
-- ==========================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local State = getgenv().PandaHub.State
local UI = getgenv().PandaHub.UI
local Tabs = getgenv().PandaHub.Tabs
local track = getgenv().PandaHub.track
local antiTab = Tabs.Anti
local logAction = getgenv().PandaHub.logAction

local LocalPlayer = Players.LocalPlayer

-- State Default untuk Anti AFK
if State.AntiAFK == nil then
    State.AntiAFK = false
end

-- UI
UI.createToggle("AntiAFKToggle", "Anti AFK (Mencegah DC 20 Menit)", "AntiAFK", 1, antiTab)

-- ==========================================
-- LOGIC ANTI AFK
-- ==========================================
local idledConnection = nil

task.spawn(function()
    while true do
        wait(1)
        if State.AntiAFK then
            if not idledConnection then
                -- METODE 1: getconnections (Paling Ampuh untuk HP & PC, 100% tanpa klik)
                if getconnections then
                    pcall(function()
                        for _, v in pairs(getconnections(LocalPlayer.Idled)) do
                            v:Disable() -- Mematikan fungsi kick dari Roblox secara total
                        end
                    end)
                    if logAction then
                        logAction("SYSTEM", "Anti AFK (Metode getconnections) diaktifkan untuk HP/PC!")
                    end
                    -- Kita buat dummy connection agar script tahu AntiAFK sedang jalan
                    idledConnection = LocalPlayer.Idled:Connect(function() end)
                else
                    -- METODE 2: VirtualUser Fallback (Simulasi interaksi engine)
                    idledConnection = LocalPlayer.Idled:Connect(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                        if logAction then
                            logAction("ANTI-AFK", "Mencegah DC dengan interaksi virtual.")
                        end
                    end)
                    if logAction then
                        logAction("SYSTEM", "Anti AFK (Metode VirtualUser) diaktifkan!")
                    end
                end
            end
        else
            if idledConnection then
                idledConnection:Disconnect()
                idledConnection = nil
                
                -- Kembalikan fungsi kick jika dimatikan
                if getconnections then
                    pcall(function()
                        for _, v in pairs(getconnections(LocalPlayer.Idled)) do
                            v:Enable()
                        end
                    end)
                end
                
                if logAction then
                    logAction("SYSTEM", "Anti AFK dimatikan.")
                end
            end
        end
    end
end)
