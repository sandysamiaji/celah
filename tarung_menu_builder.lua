-- ==========================================
-- MENU BUILDER
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
local builderTab = Tabs.Builder
local logAction = getgenv().PandaHub.logAction

-- BUILDER TAB
local SavedBase = {}
local BaseDatabase = {}
local selectedBaseName = nil

local function loadBaseDatabase()
    if readfile and isfile and HttpService then
        if isfile("PandaBooga_BasesDB.json") then
            local success, err = pcall(function()
                local jsonString = readfile("PandaBooga_BasesDB.json")
                local serializedDB = HttpService:JSONDecode(jsonString)
                BaseDatabase = {}
                for key, baseArr in pairs(serializedDB) do
                    local arr = {}
                    for _, item in ipairs(baseArr) do
                        table.insert(arr, {
                            Name = item.Name,
                            Offset = Vector3.new(item.OffsetX, item.OffsetY, item.OffsetZ),
                            Rotation = CFrame.new(unpack(item.RotComponents)),
                            IsRelative = item.IsRelative or false
                        })
                    end
                    BaseDatabase[key] = arr
                end
            end)
            return success
        end
    end
    return false
end

local function saveBaseDatabase()
    if writefile and HttpService then
        local serializedDB = {}
        for key, baseArr in pairs(BaseDatabase) do
            local sArr = {}
            for _, item in ipairs(baseArr) do
                table.insert(sArr, {
                    Name = item.Name,
                    OffsetX = item.Offset.X,
                    OffsetY = item.Offset.Y,
                    OffsetZ = item.Offset.Z,
                    RotComponents = {item.Rotation:components()},
                    IsRelative = item.IsRelative or false
                })
            end
            serializedDB[key] = sArr
        end
        pcall(function()
            local jsonString = HttpService:JSONEncode(serializedDB)
            writefile("PandaBooga_BasesDB.json", jsonString)
        end)
    end
end

loadBaseDatabase()

local builderRadiusInput = Instance.new("TextBox")
builderRadiusInput.Size = UDim2.new(0.9, 0, 0, 30)
builderRadiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
builderRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
builderRadiusInput.Font = Enum.Font.Gotham
builderRadiusInput.TextSize = 13
builderRadiusInput.Text = tostring(State.CopyRadius)
builderRadiusInput.PlaceholderText = "Radius (Studs)"
builderRadiusInput.LayoutOrder = 1
builderRadiusInput.Parent = builderTab

local copyBaseBtn = Instance.new("TextButton")
copyBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
copyBaseBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
copyBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBaseBtn.Font = Enum.Font.GothamBold
copyBaseBtn.TextSize = 13
copyBaseBtn.Text = "Copy Base (Radius " .. State.CopyRadius .. ")"
copyBaseBtn.LayoutOrder = 2
copyBaseBtn.Parent = builderTab

local deleteRadiusInput = Instance.new("TextBox")
deleteRadiusInput.Size = UDim2.new(0.9, 0, 0, 30)
deleteRadiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
deleteRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteRadiusInput.Font = Enum.Font.Gotham
deleteRadiusInput.TextSize = 13
deleteRadiusInput.Text = tostring(State.DeleteRadius)
deleteRadiusInput.PlaceholderText = "Delete Radius (Studs)"
deleteRadiusInput.LayoutOrder = 12
deleteRadiusInput.Parent = builderTab

local deleteRadiusBtn = Instance.new("TextButton")
deleteRadiusBtn.Size = UDim2.new(0.9, 0, 0, 35)
deleteRadiusBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
deleteRadiusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteRadiusBtn.Font = Enum.Font.GothamBold
deleteRadiusBtn.TextSize = 13
deleteRadiusBtn.Text = "Delete in Area (Radius " .. State.DeleteRadius .. ")"
deleteRadiusBtn.LayoutOrder = 13
deleteRadiusBtn.Parent = builderTab

builderRadiusInput.FocusLost:Connect(function()
    local num = tonumber(builderRadiusInput.Text)
    if num then
        if num < 10 then num = 10 end
        if num > 5000 then num = 5000 end
        State.CopyRadius = num
        builderRadiusInput.Text = tostring(num)
        copyBaseBtn.Text = "Copy Base (Radius " .. num .. ")"
    else
        builderRadiusInput.Text = tostring(State.CopyRadius)
    end
end)

deleteRadiusInput.FocusLost:Connect(function()
    local num = tonumber(deleteRadiusInput.Text)
    if num then
        if num < 10 then num = 10 end
        if num > 5000 then num = 5000 end
        State.DeleteRadius = num
        deleteRadiusInput.Text = tostring(num)
        deleteRadiusBtn.Text = "Delete in Area (Radius " .. num .. ")"
    else
        deleteRadiusInput.Text = tostring(State.DeleteRadius)
    end
end)

local buildStatusLabel = Instance.new("TextLabel")
buildStatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
buildStatusLabel.BackgroundTransparency = 1
buildStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
buildStatusLabel.Font = Enum.Font.Gotham
buildStatusLabel.TextSize = 11
buildStatusLabel.Text = "0 Buildings Saved"
buildStatusLabel.LayoutOrder = 3
buildStatusLabel.Parent = builderTab

local baseNameInput = Instance.new("TextBox")
baseNameInput.Size = UDim2.new(0.9, 0, 0, 30)
baseNameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
baseNameInput.Font = Enum.Font.Gotham
baseNameInput.TextSize = 12
baseNameInput.Text = ""
baseNameInput.PlaceholderText = "Base Name (Example: my base)"
baseNameInput.LayoutOrder = 4
baseNameInput.Parent = builderTab

local saveBaseBtn = Instance.new("TextButton")
saveBaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
saveBaseBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
saveBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBaseBtn.Font = Enum.Font.GothamBold
saveBaseBtn.TextSize = 12
saveBaseBtn.Text = "Save Base to List"
saveBaseBtn.LayoutOrder = 5
saveBaseBtn.Parent = builderTab

local loadBaseBtn = Instance.new("TextButton")
loadBaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
loadBaseBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
loadBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBaseBtn.Font = Enum.Font.GothamBold
loadBaseBtn.TextSize = 12
loadBaseBtn.Text = "Sync JSON Data"
loadBaseBtn.LayoutOrder = 6
loadBaseBtn.Parent = builderTab

local baseDropdown = Instance.new("TextButton")
baseDropdown.Size = UDim2.new(0.9, 0, 0, 30)
baseDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
baseDropdown.Font = Enum.Font.Gotham
baseDropdown.TextSize = 12
baseDropdown.Text = "Select Base from List..."
baseDropdown.LayoutOrder = 7
baseDropdown.Parent = builderTab

local baseList = Instance.new("ScrollingFrame")
baseList.Size = UDim2.new(1, 0, 0, 150)
baseList.Position = UDim2.new(0, 0, 1, 0)
baseList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
baseList.BorderSizePixel = 0
baseList.ScrollBarThickness = 4
baseList.Visible = false
baseList.ZIndex = 10
baseList.Parent = baseDropdown

local baseListLayout = Instance.new("UIListLayout")
baseListLayout.Parent = baseList
baseListLayout.SortOrder = Enum.SortOrder.Name

local pasteHeightContainer = Instance.new("Frame")
pasteHeightContainer.Size = UDim2.new(0.9, 0, 0, 35)
pasteHeightContainer.BackgroundTransparency = 1
pasteHeightContainer.LayoutOrder = 9
pasteHeightContainer.Parent = builderTab

local pasteHeightLabel = Instance.new("TextLabel")
pasteHeightLabel.Size = UDim2.new(0.55, 0, 1, 0)
pasteHeightLabel.BackgroundTransparency = 1
pasteHeightLabel.Text = "Paste Height (Y):"
pasteHeightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteHeightLabel.Font = Enum.Font.GothamBold
pasteHeightLabel.TextSize = 13
pasteHeightLabel.TextXAlignment = Enum.TextXAlignment.Left
pasteHeightLabel.Parent = pasteHeightContainer

local pasteHeightInput = Instance.new("TextBox")
pasteHeightInput.Size = UDim2.new(0.4, 0, 0.8, 0)
pasteHeightInput.Position = UDim2.new(0.6, 0, 0.1, 0)
pasteHeightInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
pasteHeightInput.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteHeightInput.Font = Enum.Font.Gotham
pasteHeightInput.TextSize = 13
pasteHeightInput.Text = tostring(State.PasteHeight)
pasteHeightInput.PlaceholderText = "Height"
pasteHeightInput.Parent = pasteHeightContainer

pasteHeightInput.FocusLost:Connect(function()
    local num = tonumber(pasteHeightInput.Text)
    if num then
        State.PasteHeight = num
        pasteHeightInput.Text = tostring(num)
    else
        pasteHeightInput.Text = tostring(State.PasteHeight)
    end
end)

local pasteBaseBtn = Instance.new("TextButton")
pasteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
pasteBaseBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
pasteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteBaseBtn.Font = Enum.Font.GothamBold
pasteBaseBtn.TextSize = 13
pasteBaseBtn.Text = "Paste Selected Base"
pasteBaseBtn.LayoutOrder = 10
pasteBaseBtn.Parent = builderTab

local deleteBaseBtn = Instance.new("TextButton")
deleteBaseBtn.Size = UDim2.new(0.9, 0, 0, 35)
deleteBaseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
deleteBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteBaseBtn.Font = Enum.Font.GothamBold
deleteBaseBtn.TextSize = 13
deleteBaseBtn.Text = "Delete Selected Base"
deleteBaseBtn.LayoutOrder = 11
deleteBaseBtn.Parent = builderTab

local clearMyBuildsBtn = Instance.new("TextButton")
clearMyBuildsBtn.Size = UDim2.new(0.9, 0, 0, 35)
clearMyBuildsBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
clearMyBuildsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearMyBuildsBtn.Font = Enum.Font.GothamBold
clearMyBuildsBtn.TextSize = 13
clearMyBuildsBtn.Text = "Delete All My Buildings"
clearMyBuildsBtn.LayoutOrder = 12
clearMyBuildsBtn.Parent = builderTab

local function updateBaseList()
    for _, child in ipairs(baseList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local ySize = 0
    for bName, _ in pairs(BaseDatabase) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Text = bName
        btn.Name = bName
        btn.ZIndex = 11
        btn.Parent = baseList
        
        btn.MouseButton1Click:Connect(function()
            selectedBaseName = bName
            baseDropdown.Text = bName
            baseNameInput.Text = bName -- Set nama base ke textbox biar mudah diedit
            baseList.Visible = false
            
            -- Set SavedBase ke base yang dipilih agar siap di-paste
            SavedBase = BaseDatabase[bName]
            buildStatusLabel.Text = #SavedBase .. " Buildings (" .. bName .. ") Ready to Paste"
        end)
        ySize = ySize + 25
    end
    baseList.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

baseDropdown.MouseButton1Click:Connect(function()
    baseList.Visible = not baseList.Visible
    if baseList.Visible then
        updateBaseList()
    end
end)

copyBaseBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    SavedBase = {}
    -- Mengambil posisi murni karakter (XYZ)
    local originPos = root.Position

    -- Cari bangunan di sekitar
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local isBuilding = false
            
            -- Indikator kuat: Jika punya Owner/Creator
            if obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Placer") then
                isBuilding = true
            end
            
            -- Filter berdasarkan kata kunci nama (Wall, Foundation, dll)
            local n = obj.Name:lower()
            if not isBuilding then
                if (string.find(n, "wall") or string.find(n, "foundation") or string.find(n, "stairs") or 
                    string.find(n, "door") or string.find(n, "window") or string.find(n, "bed") or 
                    string.find(n, "fire") or string.find(n, "well") or string.find(n, "torch") or 
                    string.find(n, "chest") or string.find(n, "gate") or string.find(n, "bridge")) then
                    
                    -- Pastikan BUKAN sumber daya alam
                    if not string.find(n, "tree") and not string.find(n, "rock") and not string.find(n, "ore") and not string.find(n, "bush") then
                        isBuilding = true
                    end
                end
            end

            if isBuilding then
                local primary = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildOfClass("BasePart")
                if primary then
                    local dist = (primary.Position - originPos).Magnitude
                    if dist <= State.CopyRadius then
                        -- Simpan CFrame relatif terhadap tubuh karakter (Posisi & Rotasi)
                        local relativeCFrame = root.CFrame:ToObjectSpace(primary.CFrame)
                        table.insert(SavedBase, {
                            Name = obj.Name,
                            Offset = relativeCFrame.Position,
                            Rotation = relativeCFrame - relativeCFrame.Position,
                            IsRelative = true
                        })
                    end
                end
            end
        end
    end
    
    buildStatusLabel.Text = #SavedBase .. " Buildings Saved"
    logAction("BUILDER", "Successfully copied " .. #SavedBase .. " buildings!")
end)

saveBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "Failed: No base is currently copied!")
        return
    end
    local bName = baseNameInput.Text
    if bName == "" or bName:match("^%s*$") then
        logAction("BUILDER", "Failed: Enter base name first! (Example: my base)")
        return
    end
    
    -- Load dulu dari file untuk memastikan kita punya data terbaru sebelum save (biar tidak tertimpa)
    loadBaseDatabase()
    
    -- Simpan base saat ini ke database internal
    BaseDatabase[bName] = {}
    for _, item in ipairs(SavedBase) do
        table.insert(BaseDatabase[bName], {
            Name = item.Name,
            Offset = item.Offset,
            Rotation = item.Rotation,
            IsRelative = item.IsRelative
        })
    end
    
    saveBaseDatabase()
    logAction("BUILDER", "Base '" .. bName .. "' successfully saved/edited in list!")
    updateBaseList()
end)

loadBaseBtn.MouseButton1Click:Connect(function()
    local success = loadBaseDatabase()
    if success then
        logAction("BUILDER", "Successfully synced base data from json file!")
        updateBaseList()
    else
        logAction("BUILDER", "Failed to load file (PandaBooga_BasesDB.json might not exist yet).")
    end
end)

deleteBaseBtn.MouseButton1Click:Connect(function()
    if not selectedBaseName or not BaseDatabase[selectedBaseName] then
        logAction("BUILDER", "Failed: Select a base from the list first to delete!")
        return
    end
    
    loadBaseDatabase() -- sinkronisasi dengan file terbaru
    BaseDatabase[selectedBaseName] = nil
    saveBaseDatabase()
    
    logAction("BUILDER", "Base '" .. selectedBaseName .. "' successfully deleted!")
    selectedBaseName = nil
    baseDropdown.Text = "Select Base from List..."
    baseNameInput.Text = ""
    SavedBase = {}
    buildStatusLabel.Text = "0 Buildings Saved"
    updateBaseList()
end)

clearMyBuildsBtn.MouseButton1Click:Connect(function()
    local deleteEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "DeleteBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            deleteEvent = desc
            break
        end
    end
    
    if not deleteEvent then
        logAction("BUILDER", "Failed! 'DeleteBuild' remote not found!")
        return
    end

    logAction("BUILDER", "Starting to delete your buildings...")
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Placer")
            if ownerVal then
                local isMine = false
                if ownerVal:IsA("StringValue") and ownerVal.Value == LocalPlayer.Name then
                    isMine = true
                elseif ownerVal:IsA("ObjectValue") and ownerVal.Value == LocalPlayer then
                    isMine = true
                end
                
                if isMine then
                    coroutine.wrap(function()
                        if deleteEvent:IsA("RemoteEvent") then
                            deleteEvent:FireServer(obj)
                        else
                            deleteEvent:InvokeServer(obj)
                        end
                    end)()
                    count = count + 1
                    -- Jangan terlalu spam sekaligus agar tidak disconnect
                    if count % 20 == 0 then wait(0.1) end
                end
            end
        end
    end
    logAction("BUILDER", "Done! " .. count .. " of your buildings have been deleted from the map.")
end)

deleteRadiusBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local deleteEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "DeleteBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            deleteEvent = desc
            break
        end
    end
    
    if not deleteEvent then
        logAction("BUILDER", "Failed! 'DeleteBuild' remote not found!")
        return
    end

    local originPos = root.Position
    logAction("BUILDER", "Starting to process deletion for buildings in area (Radius " .. State.DeleteRadius .. ")...")
    local count = 0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Placer")
            if ownerVal then
                local primary = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildOfClass("BasePart")
                if primary then
                    local dist = (primary.Position - originPos).Magnitude
                    if dist <= State.DeleteRadius then
                        coroutine.wrap(function()
                            if deleteEvent:IsA("RemoteEvent") then
                                deleteEvent:FireServer(obj)
                            else
                                deleteEvent:InvokeServer(obj)
                            end
                        end)()
                        count = count + 1
                        if count % 20 == 0 then wait(0.1) end
                    end
                end
            end
        end
    end
    logAction("BUILDER", "Done! " .. count .. " buildings in area processed for deletion.")
end)

pasteBaseBtn.MouseButton1Click:Connect(function()
    if #SavedBase == 0 then
        logAction("BUILDER", "No buildings copied!")
        return
    end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Mengambil CFrame karakter utuh saat tombol paste ditekan (untuk rotasi dan posisi)
    local currentCFrame = root.CFrame
    local currentPos = root.Position
    
    -- Cari remote PlaceBuild sekali saja
    local placeEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "PlaceBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            placeEvent = desc
            break
        end
    end
    
    if not placeEvent then
        logAction("BUILDER", "Failed! 'PlaceBuild' remote not found!")
        return
    end
    
    logAction("BUILDER", "Starting Paste process for " .. #SavedBase .. " buildings...")
    
    local tribeEvents = ReplicatedStorage:FindFirstChild("TribeEvents")
    local leaveTribe = tribeEvents and tribeEvents:FindFirstChild("LeaveTribe")
    local createTribe = tribeEvents and tribeEvents:FindFirstChild("CreateTribe")
    
    if leaveTribe and createTribe then
        logAction("BUILDER", "[INFO] Auto Tribe-Hop feature found & active!")
    end

    -- Mulai proses Paste di background agar tidak hang
    coroutine.wrap(function()
        local count = 0
        
        for _, data in ipairs(SavedBase) do
            -- TRIBE HOPPING: Reset Limit sebelum menyentuh 1200
            if count > 0 and count % 1155 == 0 and leaveTribe and createTribe then
                logAction("BUILDER", "Limit almost full (1150). Executing Auto Tribe-Hop...")
                leaveTribe:FireServer()
                wait(0.5)
                createTribe:FireServer("InfinityBase" .. tostring(math.random(100,999)))
                wait(0.5)
                logAction("BUILDER", "Limit successfully reset! Continuing building...")
            end

            -- Menentukan target posisi dan rotasi
            local targetCFrame
            if data.IsRelative then
                -- Sistem Baru: Mengikuti arah hadap (rotasi) karakter
                local relativeBaseCFrame = CFrame.new(data.Offset) * data.Rotation
                targetCFrame = currentCFrame * relativeBaseCFrame
                -- Tambah offset Y sesuai setingan di UI
                targetCFrame = targetCFrame + Vector3.new(0, State.PasteHeight, 0)
            else
                -- Sistem Lama (Backward Compatibility): Tetap menghadap arah asli dunia
                local targetPos = currentPos + Vector3.new(0, State.PasteHeight, 0) + data.Offset
                targetCFrame = CFrame.new(targetPos) * data.Rotation
            end
            
            if placeEvent:IsA("RemoteEvent") then
                placeEvent:FireServer(data.Name, targetCFrame)
            else
                placeEvent:InvokeServer(data.Name, targetCFrame)
            end
            
            count = count + 1
            wait(State.AttackCooldown > 0 and State.AttackCooldown or 0.1) -- Jeda kecepatan naruh barang ngikutin setingan AttackCooldown
        end
        
        logAction("BUILDER", "Successfully built Skybase with " .. count .. " buildings (Limit By-passed)!")
    end)()
end)

-- TOMBOL DUPE LIMIT (GLITCH SERVER)
local dupeLimitBtn = Instance.new("TextButton")
dupeLimitBtn.Size = UDim2.new(0.9, 0, 0, 35)
dupeLimitBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
dupeLimitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dupeLimitBtn.Font = Enum.Font.GothamBold
dupeLimitBtn.TextSize = 13
dupeLimitBtn.Text = "GLITCH / DUPE LIMIT (-3000)"
dupeLimitBtn.LayoutOrder = 5
dupeLimitBtn.Parent = builderTab

dupeLimitBtn.MouseButton1Click:Connect(function()
    local deleteEvent
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "DeleteBuild" and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            deleteEvent = desc
            break
        end
    end
    
    if not deleteEvent then
        logAction("BUILDER", "Failed! 'DeleteBuild' remote not found!")
        return
    end

    -- Cari SEMBARANG bangunan yang ada di map untuk dikorbankan sebagai tumbal spam
    local tumbalObj = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == "Wood Wall" or obj.Name == "Stone Wall" or obj:FindFirstChild("Owner") or obj:FindFirstChild("Creator")) then
            tumbalObj = obj
            break
        end
    end

    if not tumbalObj then
        logAction("BUILDER", "Failed! You need at least 1 building (Wood Wall) on the ground as a sacrifice.")
        return
    end

    logAction("BUILDER", "Executing EXTREME SPAM on DeleteBuild (Bypassing Limit)...")
    
    -- Eksekusi bom 10000 sinyal bersamaan TANPA JEDA (Race Condition)
    for i = 1, 10000 do
        coroutine.wrap(function()
            if deleteEvent:IsA("RemoteEvent") then
                deleteEvent:FireServer(tumbalObj)
            else
                deleteEvent:InvokeServer(tumbalObj)
            end
        end)()
    end
    
    logAction("BUILDER", "10000 requests attack finished! Your limit is now drastically Minus/Infinite!")
end)


--------------------------------------------------------------------------------

-- ==========================================
-- LOGIC
-- ==========================================
