-- ==========================================
-- MENU GIFT
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
local giftTab = Tabs.Gift
local logAction = getgenv().PandaHub.logAction

-- GIFT TAB LOGIC
--------------------------------------------------------------------------------
UI.createInfoBox("Auto Gift", "Drops the intercepted item -10 below selected player feet. Enable, then manually Drop any item to capture it.", 1, giftTab)

local autoGiftBtn = Instance.new("TextButton")
autoGiftBtn.Size = UDim2.new(0.9, 0, 0, 35)
autoGiftBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
autoGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoGiftBtn.Font = Enum.Font.GothamBold
autoGiftBtn.TextSize = 13
autoGiftBtn.Text = "Auto Gift: OFF"
autoGiftBtn.LayoutOrder = 2
autoGiftBtn.Parent = giftTab

local giftTpDelayContainer = Instance.new("Frame")
giftTpDelayContainer.Size = UDim2.new(0.9, 0, 0, 35)
giftTpDelayContainer.BackgroundTransparency = 1
giftTpDelayContainer.LayoutOrder = 3
giftTpDelayContainer.Parent = giftTab

local giftTpDelayLabel = Instance.new("TextLabel")
giftTpDelayLabel.Size = UDim2.new(0.55, 0, 1, 0)
giftTpDelayLabel.BackgroundTransparency = 1
giftTpDelayLabel.Text = "Teleport Delay:"
giftTpDelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giftTpDelayLabel.Font = Enum.Font.GothamBold
giftTpDelayLabel.TextSize = 13
giftTpDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
giftTpDelayLabel.Parent = giftTpDelayContainer

local giftTpDelayInput = Instance.new("TextBox")
giftTpDelayInput.Size = UDim2.new(0.4, 0, 0.8, 0)
giftTpDelayInput.Position = UDim2.new(0.6, 0, 0.1, 0)
giftTpDelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giftTpDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giftTpDelayInput.Font = Enum.Font.Gotham
giftTpDelayInput.TextSize = 13
giftTpDelayInput.Text = tostring(State.GiftTeleportDelay)
giftTpDelayInput.PlaceholderText = "Seconds"
giftTpDelayInput.Parent = giftTpDelayContainer

giftTpDelayInput.FocusLost:Connect(function()
    local val = tonumber(giftTpDelayInput.Text)
    if val then
        State.GiftTeleportDelay = val
    else
        giftTpDelayInput.Text = tostring(State.GiftTeleportDelay)
    end
end)

local giftDropDelayContainer = Instance.new("Frame")
giftDropDelayContainer.Size = UDim2.new(0.9, 0, 0, 35)
giftDropDelayContainer.BackgroundTransparency = 1
giftDropDelayContainer.LayoutOrder = 4
giftDropDelayContainer.Parent = giftTab

local giftDropDelayLabel = Instance.new("TextLabel")
giftDropDelayLabel.Size = UDim2.new(0.55, 0, 1, 0)
giftDropDelayLabel.BackgroundTransparency = 1
giftDropDelayLabel.Text = "Drop Speed:"
giftDropDelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giftDropDelayLabel.Font = Enum.Font.GothamBold
giftDropDelayLabel.TextSize = 13
giftDropDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
giftDropDelayLabel.Parent = giftDropDelayContainer

local giftDropDelayInput = Instance.new("TextBox")
giftDropDelayInput.Size = UDim2.new(0.4, 0, 0.8, 0)
giftDropDelayInput.Position = UDim2.new(0.6, 0, 0.1, 0)
giftDropDelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giftDropDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giftDropDelayInput.Font = Enum.Font.Gotham
giftDropDelayInput.TextSize = 13
giftDropDelayInput.Text = tostring(State.GiftDropDelay)
giftDropDelayInput.PlaceholderText = "Seconds"
giftDropDelayInput.Parent = giftDropDelayContainer

giftDropDelayInput.FocusLost:Connect(function()
    local val = tonumber(giftDropDelayInput.Text)
    if val then
        State.GiftDropDelay = val
    else
        giftDropDelayInput.Text = tostring(State.GiftDropDelay)
    end
end)

local giftStatus = Instance.new("TextLabel")
State.GiftStatusLabel = giftStatus
giftStatus.Name = "GiftStatusLabel"
giftStatus.Size = UDim2.new(0.9, 0, 0, 30)
giftStatus.BackgroundTransparency = 1
giftStatus.Text = "Status: Drop an item to capture..."
giftStatus.TextColor3 = Color3.fromRGB(241, 196, 15)
giftStatus.Font = Enum.Font.GothamBold
giftStatus.TextSize = 12
giftStatus.LayoutOrder = 5
giftStatus.Parent = giftTab

local refreshGiftBtn = Instance.new("TextButton")
refreshGiftBtn.Size = UDim2.new(0.9, 0, 0, 30)
refreshGiftBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
refreshGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshGiftBtn.Font = Enum.Font.GothamBold
refreshGiftBtn.TextSize = 12
refreshGiftBtn.Text = "Refresh Player List"
refreshGiftBtn.LayoutOrder = 6
refreshGiftBtn.Parent = giftTab

local giftBtnContainer = Instance.new("Frame")
giftBtnContainer.Size = UDim2.new(0.9, 0, 0, 30)
giftBtnContainer.BackgroundTransparency = 1
giftBtnContainer.LayoutOrder = 7
giftBtnContainer.Parent = giftTab

local ALL_GAME_ITEMS = {
    "Semua Item",
    "Wood", "Stone", "Rock", "Iron Ore", "Gold Ore",
    "Fiber", "Leaves", "Plant", "Raw Meat", "Cooked Meat",
    "Sun Fruit", "Blood Fruit", "Blue Fruit", "Jelly",
    "Ice", "Coconut", "Fish", "Cooked Fish", "Water",
    "Corn", "Berries", "Crystal", "Magnetite", "Steel",
    "Adurite", "Essence", "Crystal Chunk", "Steel Chunk",
    "God Rock", "Coin", "Coins", "Token", "Tokens", "Survivor Token", "Survivor Tokens",
    "Fiber Seeds", "Berry Seeds", "Corn Seeds",
    "Sun Fruit Seeds", "Blood Fruit Seeds", "Blue Fruit Seeds", "Animal Hide"
}



local dropDivider = Instance.new("TextLabel")
dropDivider.Size = UDim2.new(0.9, 0, 0, 20)
dropDivider.BackgroundTransparency = 1
dropDivider.Text = "--- Manual Drop (Isi Tas) ---"
dropDivider.TextColor3 = Color3.fromRGB(150, 150, 150)
dropDivider.Font = Enum.Font.GothamBold
dropDivider.TextSize = 12
dropDivider.LayoutOrder = 9
dropDivider.Parent = giftTab

local dropItemDropdownBtn = Instance.new("TextButton")

dropItemDropdownBtn.Size = UDim2.new(0.9, 0, 0, 30)
dropItemDropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropItemDropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropItemDropdownBtn.Font = Enum.Font.Gotham
dropItemDropdownBtn.TextSize = 12
dropItemDropdownBtn.Text = "Semua Item"
dropItemDropdownBtn.LayoutOrder = 10
dropItemDropdownBtn.ZIndex = 20
dropItemDropdownBtn.Parent = giftTab

local dropItemList = Instance.new("ScrollingFrame")
dropItemList.Size = UDim2.new(1, 0, 0, 150)
dropItemList.Position = UDim2.new(0, 0, 1, 0)
dropItemList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropItemList.BorderSizePixel = 0
dropItemList.ScrollBarThickness = 4
dropItemList.Visible = false
dropItemList.ZIndex = 10
dropItemList.Parent = dropItemDropdownBtn

local dropItemLayout = Instance.new("UIListLayout")
dropItemLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropItemLayout.Parent = dropItemList

for i = 1, #ALL_GAME_ITEMS do
    local itemName = ALL_GAME_ITEMS[i]
    itemBtn = Instance.new("TextButton")
    itemBtn.Size = UDim2.new(1, 0, 0, 25)
    itemBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    itemBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemBtn.Font = Enum.Font.Gotham
    itemBtn.TextSize = 12
    itemBtn.Text = itemName
    itemBtn.LayoutOrder = i
    itemBtn.ZIndex = 11
    itemBtn.Parent = dropItemList
    itemBtn.MouseButton1Click:Connect(function()
        dropItemDropdownBtn.Text = itemName
        dropItemList.Visible = false
    end)
end

dropItemList.CanvasSize = UDim2.new(0, 0, 0, #ALL_GAME_ITEMS * 25)

dropItemDropdownBtn.MouseButton1Click:Connect(function()
    dropItemList.Visible = not dropItemList.Visible
end)

local dropAmountInput = Instance.new("TextBox")
dropAmountInput.Size = UDim2.new(0.9, 0, 0, 30)
dropAmountInput.BackgroundColor3 = Color3.fromRGB(45, 52, 54)
dropAmountInput.TextColor3 = Color3.fromRGB(223, 230, 233)
dropAmountInput.Font = Enum.Font.Gotham
dropAmountInput.TextSize = 12
dropAmountInput.PlaceholderText = "Jumlah Drop (misal: -9999999)"
dropAmountInput.Text = "-9999999"
dropAmountInput.LayoutOrder = 11
dropAmountInput.Parent = giftTab

local autoDropBagBtn = Instance.new("TextButton")
autoDropBagBtn.Size = UDim2.new(0.9, 0, 0, 35)
autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
autoDropBagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoDropBagBtn.Font = Enum.Font.GothamBold
autoDropBagBtn.TextSize = 12
autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
autoDropBagBtn.LayoutOrder = 12
autoDropBagBtn.Parent = giftTab

autoDropBagBtn.MouseButton1Click:Connect(function()
    local filterText = dropItemDropdownBtn.Text
    local dropAmount = tonumber(dropAmountInput.Text) or -9999999
    local dropRemote = State.GiftRemote
    if not dropRemote then
        -- Cari langsung di ReplicatedStorage kalau belum ter-capture
        for _, desc in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if desc:IsA("RemoteEvent") and (desc.Name == "Drop" or desc.Name == "DropItem" or desc.Name == "DropItems") then
                dropRemote = desc
                break
            end
        end
    end
    if not dropRemote then
        autoDropBagBtn.Text = "Remote tidak ditemukan!"
        wait(2)
        autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
        return
    end
    autoDropBagBtn.Text = "Proses Dropping..."
    autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    spawn(function()
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then
            autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
            autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
            return
        end
        local targetCFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
        if filterText == "Semua Item" then
            for i = 2, #ALL_GAME_ITEMS do
                pcall(function()
                    local itemName = ALL_GAME_ITEMS[i]
                    if string.find(itemName, "Seeds") then
                        dropRemote:FireServer(itemName, dropAmount)
                    else
                        dropRemote:FireServer(itemName, dropAmount, targetCFrame)
                    end
                end)
                wait(0.05)
            end
        else
            pcall(function()
                if string.find(filterText, "Seeds") then
                    dropRemote:FireServer(filterText, dropAmount)
                else
                    dropRemote:FireServer(filterText, dropAmount, targetCFrame)
                end
            end)
        end
        autoDropBagBtn.Text = "Drop Selesai!"
        autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        wait(2)
        autoDropBagBtn.Text = "Drop Isi Tas (Sesuai Pilihan)"
        autoDropBagBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    end)
end)

local selectAllGiftBtn = Instance.new("TextButton")
selectAllGiftBtn.Size = UDim2.new(0.48, 0, 1, 0)
selectAllGiftBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
selectAllGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAllGiftBtn.Font = Enum.Font.GothamBold
selectAllGiftBtn.TextSize = 12
selectAllGiftBtn.Text = "Select All"
selectAllGiftBtn.Parent = giftBtnContainer

local deselectAllGiftBtn = Instance.new("TextButton")
deselectAllGiftBtn.Size = UDim2.new(0.48, 0, 1, 0)
deselectAllGiftBtn.Position = UDim2.new(0.52, 0, 0, 0)
deselectAllGiftBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
deselectAllGiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deselectAllGiftBtn.Font = Enum.Font.GothamBold
deselectAllGiftBtn.TextSize = 12
deselectAllGiftBtn.Text = "Deselect All"
deselectAllGiftBtn.Parent = giftBtnContainer

local giftPlayerList = Instance.new("ScrollingFrame")
giftPlayerList.Size = UDim2.new(0.9, 0, 0, 200)
giftPlayerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
giftPlayerList.BorderSizePixel = 0
giftPlayerList.ScrollBarThickness = 4
giftPlayerList.LayoutOrder = 8
giftPlayerList.Parent = giftTab

local giftPlayerLayout = Instance.new("UIListLayout")
giftPlayerLayout.Parent = giftPlayerList
giftPlayerLayout.SortOrder = Enum.SortOrder.Name

local function populateGiftList()
    for _, child in ipairs(giftPlayerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local ySize = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            local isSelected = State.GiftTargets[player.Name] or false
            btn.BackgroundColor3 = isSelected and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Text = player.Name
            btn.Parent = giftPlayerList
            btn.MouseButton1Click:Connect(function()
                State.GiftTargets[player.Name] = not State.GiftTargets[player.Name]
                btn.BackgroundColor3 = State.GiftTargets[player.Name] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
            end)
            ySize = ySize + 25
        end
    end
    giftPlayerList.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

refreshGiftBtn.MouseButton1Click:Connect(populateGiftList)
selectAllGiftBtn.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then State.GiftTargets[player.Name] = true end
    end
    populateGiftList()
end)
deselectAllGiftBtn.MouseButton1Click:Connect(function()
    State.GiftTargets = {}
    populateGiftList()
end)
populateGiftList()

local autoGiftThread = nil
local function autoGiftLoop()
    while State.AutoGift do
        if not State.AutoGift then break end
        
        if State.GiftRemote and State.GiftArgs then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                local originalCFrame = myRoot.CFrame
                
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if not State.AutoGift then break end
                    
                    if targetPlayer ~= LocalPlayer and State.GiftTargets[targetPlayer.Name] then
                        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local targetRoot = targetPlayer.Character.HumanoidRootPart
                            local targetPos = targetRoot.Position + Vector3.new(0, -5, 0) -- Di bawah kaki
                            
                            -- 1. Teleport ke depan pemain target (jarak 2 stud, saling berhadapan)
                            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi, 0)
                            
                            -- 2. Jeda agar server mendaftarkan posisi baru kita
                            wait(State.GiftTeleportDelay)
                            
                            if not State.AutoGift then break end
                            
                            -- 3. Siapkan argumen drop (paksa posisi di bawah kaki target)
                            local newArgs = {}
                            local foundPos = false
                            local overrideAmount = tonumber(dropAmountInput.Text)
                            for i, v in ipairs(State.GiftArgs) do
                                if typeof(v) == "CFrame" then
                                    newArgs[i] = CFrame.new(targetPos)
                                    foundPos = true
                                elseif typeof(v) == "Vector3" then
                                    newArgs[i] = targetPos
                                    foundPos = true
                                elseif type(v) == "number" and overrideAmount then
                                    newArgs[i] = overrideAmount
                                else
                                    newArgs[i] = v
                                end
                            end
                            if not foundPos then
                                table.insert(newArgs, CFrame.new(targetPos))
                            end
                            
                            -- 4. Jatuhkan barang 10 kali
                            for dropCount = 1, 10 do
                                if not State.AutoGift then break end
                                pcall(function()
                                    State.IsLoopDropping = true
                                    State.GiftRemote:FireServer(unpack(newArgs))
                                    State.IsLoopDropping = false
                                end)
                                wait(State.GiftDropDelay) -- Jeda tipis antar drop biar tidak dianggap spam/kick
                            end
                            
                            -- 5. Jeda sebelum pindah ke pemain berikutnya
                            wait(State.GiftTeleportDelay)
                        end
                    end
                end
                
                -- Kembalikan ke posisi awal setelah selesai 1 putaran atau jika dimatikan
                if myRoot then
                    myRoot.CFrame = originalCFrame
                end
            end
        else
            wait(1) -- Tunggu sampai ada barang yang dicapture
        end
    end
end

autoGiftBtn.MouseButton1Click:Connect(function()
    State.AutoGift = not State.AutoGift
    if State.AutoGift then
        autoGiftBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        autoGiftBtn.Text = "Auto Gift: ON"
        if not autoGiftThread or coroutine.status(autoGiftThread) == "dead" then
            autoGiftThread = coroutine.create(autoGiftLoop)
            coroutine.resume(autoGiftThread)
        end
    else
        autoGiftBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        autoGiftBtn.Text = "Auto Gift: OFF"
    end
end)
--------------------------------------------------------------------------------

-- ==========================================
-- LOGIC
-- ==========================================
