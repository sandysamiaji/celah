-- ==========================================
-- MENU INFO & TRACKING
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local State = getgenv().PandaHub.State
local UI = getgenv().PandaHub.UI
local Tabs = getgenv().PandaHub.Tabs
local track = getgenv().PandaHub.track
local infoTab = Tabs.Info
local logAction = getgenv().PandaHub.logAction

-- INFO TAB
local function UI.createInfoBox(titleText, descText, layoutOrder, parentTab)
    parentTab = parentTab or infoTab
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.LayoutOrder = layoutOrder
    container.Parent = parentTab

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 5)
    uicorner.Parent = container

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 25)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(241, 196, 15)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -10, 0, 0)
    desc.Position = UDim2.new(0, 5, 0, 30)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    desc.Parent = container

    -- Hitung ukuran deskripsi dengan asumsi lebar 230px
    local textBounds = game:GetService("TextService"):GetTextSize(descText, 12, Enum.Font.Gotham, Vector2.new(230, 9999))
    desc.Size = UDim2.new(1, -10, 0, textBounds.Y + 10)
    container.Size = UDim2.new(0.95, 0, 0, 30 + textBounds.Y + 10)
end

UI.createInfoBox("Aura Harvest & Kill", "Aura Harvest automatically gathers resources and items. Aura Kill specifically attacks nearby enemies or players. Split into two functions to reduce performance lag.", 1)
UI.createInfoBox("Auto Claim Reward", "Automatically claims any periodic or event rewards that pop up on your screen, ensuring you never miss free items while you're away.", 2)
UI.createInfoBox("Auto Respawn", "Bypasses the death screen and instantly respawns your character the moment you die, getting you back into the action without delay.", 3)
UI.createInfoBox("Anti Fall Dmg", "Completely disables fall damage. You can jump from any height without losing a single drop of health.", 4)
UI.createInfoBox("Noclip", "Allows your character to walk straight through solid walls, objects, and terrain. Essential for quick escapes or accessing hidden areas.", 5)
UI.createInfoBox("Infinite Drop", "Bypasses item dropping limits or restrictions in the game. Highly useful for transferring mass amounts of items to your friends.", 6)
UI.createInfoBox("Spy Trace", "A diagnostic tool to help find bugs or glitches within the application. If you experience any issues, enable this feature so Panda can check the automatically generated bug reports.", 7)
UI.createInfoBox("Night Mode", "Client-side visual change that forces the game time to night. Helps reduce eye strain while AFK farming. Only visible to you.", 8)
UI.createInfoBox("Fly & Fly Speed", "Enables true flight for your character. You can adjust your flying speed dynamically using the 'Fly Speed' input box right below the toggle.", 9)
UI.createInfoBox("Teleport Options", "Continuously pull any player to you using 'Player To Me', or sneak up right behind them using 'TP Behind Player' for a surprise attack.", 10)
UI.createInfoBox("Fling Player", "Select a target from the list, equip any Tool/Weapon in your hand, and click this to violently launch them into the sky using physics manipulation!", 11)
UI.createInfoBox("Touch Fling", "Turns your character into a walking hazard. Anyone who physically touches your character will instantly be flung away. Excellent for passive defense.", 12)
UI.createInfoBox("Fling Aura", "Fling that expands its area. Automatically teleport to and fling any player within your Aura Radius. Highly aggressive.", 13)
UI.createInfoBox("Scan RemoteEvents", "An advanced debugging feature that logs all RemoteEvents in the server. Helpful for developers analyzing the game's network structure.", 13)
UI.createInfoBox("Builder System", "A comprehensive saving system for your structures. Use 'Copy Base' to save buildings within a radius to your local file, and 'Load Base' to rebuild them instantly anywhere.", 14)
UI.createInfoBox("Auto Eat & Drink", "Automatically consumes food and water from your inventory in the background so you never starve or dehydrate while AFK farming.", 15)
UI.createInfoBox("Auto Cook in Area", "Automatically interacts with any cooking stations (Campfires, Grills) within the specified radius to cook your raw food.", 16)


-- ==========================================
-- LOGIC
-- ==========================================
