-- ============================================================
--  Game Spy Mini - Mr. Panda
--  Compact GUI, 3 baris log
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("GameSpyMini"); if old then old:Destroy() end

local sg = Instance.new("ScreenGui"); sg.Name="GameSpyMini"; sg.ResetOnSpawn=false; sg.Parent=PlayerGui

local f = Instance.new("Frame")
f.Size=UDim2.new(0,340,0,140); f.Position=UDim2.new(0.5,-170,0.5,-70)
f.BackgroundColor3=Color3.fromHex("#6b0000"); f.BorderSizePixel=0
f.Active=true; f.Draggable=true; f.Parent=sg
Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)

-- title
local tr = Instance.new("Frame"); tr.Size=UDim2.new(1,0,0,26); tr.BackgroundColor3=Color3.fromHex("#9e0000"); tr.BorderSizePixel=0; tr.Parent=f
Instance.new("UICorner",tr).CornerRadius=UDim.new(0,8)
local tl = Instance.new("TextLabel"); tl.Size=UDim2.new(1,-30,1,0); tl.Position=UDim2.new(0,8,0,0)
tl.BackgroundTransparency=1; tl.TextColor3=Color3.fromHex("#ffffff"); tl.Font=Enum.Font.GothamBold
tl.TextSize=11; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Text="Game Spy Pro - Mr. Panda"; tl.Parent=tr

local xb = Instance.new("TextButton"); xb.Size=UDim2.new(0,22,0,22); xb.Position=UDim2.new(1,-24,0,2)
xb.BackgroundColor3=Color3.fromHex("#cc0000"); xb.TextColor3=Color3.fromHex("#ffffff")
xb.Font=Enum.Font.GothamBold; xb.TextSize=11; xb.Text="X"; xb.BorderSizePixel=0; xb.Parent=tr
Instance.new("UICorner",xb).CornerRadius=UDim.new(0,5)
xb.MouseButton1Click:Connect(function() sg:Destroy() end)

local mb = Instance.new("TextButton"); mb.Size=UDim2.new(0,22,0,22); mb.Position=UDim2.new(1,-48,0,2)
mb.BackgroundColor3=Color3.fromHex("#cc0000"); mb.TextColor3=Color3.fromHex("#ffffff")
mb.Font=Enum.Font.GothamBold; mb.TextSize=11; mb.Text="-"; mb.BorderSizePixel=0; mb.Parent=tr
Instance.new("UICorner",mb).CornerRadius=UDim.new(0,5)

-- no filters, show all
local fMode = "ALL"

-- scroll (approx 3 lines = 48px)
local scr = Instance.new("ScrollingFrame")
scr.Size=UDim2.new(1,-8,0,52); scr.Position=UDim2.new(0,4,0,54)
scr.BackgroundColor3=Color3.fromHex("#4a0000"); scr.BorderSizePixel=0
scr.ScrollBarThickness=4; scr.ScrollBarImageColor3=Color3.fromHex("#ffcccc")
scr.AutomaticCanvasSize=Enum.AutomaticSize.Y; scr.CanvasSize=UDim2.new(0,0,0,0)
scr.Parent=f; Instance.new("UICorner",scr).CornerRadius=UDim.new(0,4)
local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,1); ll.Parent=scr
local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,4); pad.PaddingTop=UDim.new(0,2); pad.Parent=scr

-- buttons
local bRow = Instance.new("Frame"); bRow.Size=UDim2.new(1,-8,0,24); bRow.Position=UDim2.new(0,4,1,-28)
bRow.BackgroundTransparency=1; bRow.Parent=f
local bL = Instance.new("UIListLayout"); bL.FillDirection=Enum.FillDirection.Horizontal; bL.Padding=UDim.new(0,2); bL.Parent=bRow

local function mkB(txt,col)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0.24,0,1,0); b.BackgroundColor3=col; b.TextColor3=Color3.fromHex("#ffffff")
    b.Font=Enum.Font.GothamBold; b.TextSize=10; b.Text=txt; b.BorderSizePixel=0; b.Parent=bRow
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); return b
end
local btnCpy = mkB("Copy", Color3.fromHex("#ff3333"))
local btnClr = mkB("Clr", Color3.fromHex("#cc0000"))
local btnPse = mkB("Pse", Color3.fromHex("#9e0000"))
local btnSav = mkB("Save", Color3.fromHex("#ff0000"))

local minimized = false
mb.MouseButton1Click:Connect(function()
    minimized = not minimized
    scr.Visible = not minimized
    bRow.Visible = not minimized
    f.Size = minimized and UDim2.new(0,340,0,26) or UDim2.new(0,340,0,140)
end)

-- logic
local allE={}
local psd=false
local lCnt=0
local seenSignatures = {} -- menyimpan pola argumen agar remote berulang tidak nyepam

local function srz(v)
    local t=typeof(v)
    if t=="Vector3" then return string.format("V3(%.1f,%.1f,%.1f)",v.X,v.Y,v.Z)
    elseif t=="Instance" then return "["..v.ClassName..":"..v.Name.."]"
    elseif t=="string" then return '"'..v:sub(1,30)..'"'
    elseif t=="number" then return string.format("%.4g",v)
    end
    return tostring(v):sub(1,30)
end

local function addL(nm,dr,args,col)
    -- Buat signature dari tipe data argumen (misal: "C2S_Launch_number_number")
    local types = {}
    for _, a in ipairs(args) do table.insert(types, typeof(a)) end
    local sig = dr .. "_" .. nm .. "_" .. table.concat(types, "-")

    -- Jika remote dengan pola argumen ini sudah pernah dicatat, JANGAN dicatat lagi!
    if seenSignatures[sig] then return end
    seenSignatures[sig] = true

    local p={} for i,a in ipairs(args) do table.insert(p,srz(a)) end
    local txt = string.format("[%s] %s | %s", dr, nm, #p>0 and table.concat(p,", ") or "none")
    
    -- Hapus alert khusus agar tool ini 100% universal untuk game apapun
    -- tl.Text = "✅ KETEMU: " .. nm .. "! SILAKAN COPY"

    table.insert(allE,{txt=txt})
    if psd or (fMode~="ALL" and fMode~=dr) then return end
    lCnt=lCnt+1
    if lCnt>50 then
        for _,c in ipairs(scr:GetChildren()) do if c:IsA("TextLabel") then c:Destroy(); lCnt=lCnt-1; break end end
    end
    local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-4,0,14); lb.AutomaticSize=Enum.AutomaticSize.Y
    lb.BackgroundTransparency=1; lb.TextColor3=col; lb.Font=Enum.Font.Code; lb.TextSize=10
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.TextWrapped=true; lb.Text=txt; lb.Parent=scr
    task.defer(function() scr.CanvasPosition=Vector2.new(0,99999) end)
end

local function scn(p,d)
    if d>12 then return end
    local ok,ch=pcall(function() return p:GetChildren() end)
    if ok then 
        for _,c in ipairs(ch) do 
            if c:IsA("RemoteEvent") or c:IsA("RemoteFunction") then 
                -- S2C hanya bisa per-instance
                local nm = c.Name
                pcall(function() c.OnClientEvent:Connect(function(...) addL(nm,"S2C",{...},Color3.fromRGB(255,180,50)) end) end)
                
                if not table.find(_G.FoundRemotes, nm) then
                    table.insert(_G.FoundRemotes, nm)
                    table.insert(_G.FoundRemoteInstances, c)
                end
            end 
            scn(c,d+1) 
        end 
    end
end

task.spawn(function()
    _G.FoundRemotes = {}
    _G.FoundRemoteInstances = {}
    
    -- Global C2S Hook (Bulletproof)
    local function logC2S(remoteName, ...)
        local n = select("#", ...)
        local safeArgs = {}
        for i=1, n do
            table.insert(safeArgs, select(i, ...))
        end
        task.spawn(function()
            pcall(function() addL(remoteName, "C2S", safeArgs, Color3.fromHex("#50dc50")) end)
        end)
    end

    pcall(function()
        local mt = getrawmetatable(game)
        local oldNC = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if tostring(m) == "FireServer" or tostring(m) == "InvokeServer" or tostring(m) == "fireServer" or tostring(m) == "invokeServer" then
                if typeof(self) == "Instance" then
                    logC2S(self.Name, ...)
                end
            end
            return oldNC(self, ...)
        end)
        setreadonly(mt, true)
    end)
    
    local hookedFS = {}
    local hookedIS = {}
    local function hookSpecific(r)
        if r:IsA("RemoteEvent") then
            pcall(function()
                local fs = r.FireServer
                if not hookedFS[fs] then
                    hookedFS[fs] = true
                    local oldFS
                    oldFS = hookfunction(fs, newcclosure(function(self, ...)
                        if typeof(self) == "Instance" then logC2S(self.Name, ...) end
                        return oldFS(self, ...)
                    end))
                end
            end)
        elseif r:IsA("RemoteFunction") then
            pcall(function()
                local is = r.InvokeServer
                if not hookedIS[is] then
                    hookedIS[is] = true
                    local oldIS
                    oldIS = hookfunction(is, newcclosure(function(self, ...)
                        if typeof(self) == "Instance" then logC2S(self.Name, ...) end
                        return oldIS(self, ...)
                    end))
                end
            end)
        end
    end

    pcall(function() hookSpecific(Instance.new("RemoteEvent")) end)
    pcall(function() hookSpecific(Instance.new("RemoteFunction")) end)
    
    for _, r in ipairs(_G.FoundRemoteInstances) do pcall(hookSpecific, r) end
    game.DescendantAdded:Connect(function(d) pcall(hookSpecific, d) end)

    local services = {
        "ReplicatedStorage","ReplicatedFirst","Players","Workspace",
        "Lighting"
    }
    for _,n in ipairs(services) do
        local ok,s=pcall(function() return game:GetService(n) end); if ok and s then scn(s,0) end
    end
    
    local allNames = ""
    for i, name in ipairs(_G.FoundRemotes) do
        allNames = allNames .. name .. (i < #_G.FoundRemotes and ", " or "")
    end
    addL("System","INFO",{"Remotes Ditemukan:", allNames},Color3.fromRGB(150,200,255))
    addL("System","INFO",{"Spy Aktif! Silakan tes fitur-fitur di atas."},Color3.fromRGB(100,200,100))
end)

-- === FULL REPORT GENERATOR ===
local function generateReport()
    local lines = {
        "===============================================",
        "        GAME SPY & REMOTE EXPLORER PRO         ",
        "              by Mr. Panda                  ",
        "===============================================\n",
        "PlaceId: " .. tostring(game.PlaceId),
        "Waktu: " .. tostring(os.date("%Y-%m-%d %H:%M:%S")),
        "\n=== 1. STRUKTUR REMOTE (LOKASI) ===\n"
    }

    -- Kelompokkan berdasarkan Parent
    local parentGroups = {}
    local total = 0
    for _, r in ipairs(_G.FoundRemoteInstances) do
        local pName = r.Parent and r.Parent:GetFullName() or "Unknown"
        if not parentGroups[pName] then parentGroups[pName] = {} end
        table.insert(parentGroups[pName], r)
        total = total + 1
    end

    table.insert(lines, "TOTAL: " .. total .. " remote(s) ditemukan.\n")

    for pName, remotes in pairs(parentGroups) do
        table.insert(lines, "[ " .. pName .. " ]")
        for _, r in ipairs(remotes) do
            local icon = r:IsA("RemoteEvent") and "🟢 RE " or "🟡 RF "
            table.insert(lines, "  " .. icon .. " " .. r.Name)
            table.insert(lines, "       " .. r:GetFullName())
        end
        table.insert(lines, "")
    end

    table.insert(lines, "=== 2. CARA KERJA REMOTE (BEHAVIOR) ===")
    table.insert(lines, "Format: [Arah] NamaRemote | TipeArgumen1, TipeArgumen2, ...\n")

    if #allE == 0 then
        table.insert(lines, "(Belum ada data terekam. Silakan mainkan gamenya dulu!)")
    else
        for _, e in ipairs(allE) do
            if not string.find(e.txt, "System") then
                table.insert(lines, e.txt)
            end
        end
    end

    return table.concat(lines, "\n")
end

btnCpy.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(generateReport()) end)
    btnCpy.Text="OK"; task.delay(1,function() btnCpy.Text="Copy" end)
end)
btnClr.MouseButton1Click:Connect(function() allE={}; seenSignatures={}; lCnt=0; for _,c in ipairs(scr:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end end)
btnPse.MouseButton1Click:Connect(function() psd=not psd; btnPse.Text=psd and "Res" or "Pse"; btnPse.BackgroundColor3=psd and Color3.fromRGB(140,80,20) or Color3.fromRGB(100,80,20) end)
btnSav.MouseButton1Click:Connect(function()
    local txt = generateReport()
    for _,p in ipairs({"/sdcard/Download/spy_"..game.PlaceId..".txt","spy_"..game.PlaceId..".txt"}) do 
        if pcall(writefile,p,txt) then btnSav.Text="OK "..p:match("([^/]+)$"); break end 
    end
    task.delay(2,function() btnSav.Text="Save" end)
end)
