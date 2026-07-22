import re

with open('tarung_menu_teleport.lua', 'r', encoding='utf-8') as f:
    content = f.read()

toggle_str = 'UI.createToggle("TeleportToSelectedBtn", "Teleport (Pilih Pemain)", "TeleportToSelected", 3.2, teleportTab)'

if "TeleportToSelectedBtn" not in content:
    target = 'UI.createToggle("TeleportToMouseBtn", "Teleport ke Mouse (C)", "TeleportToMouse", 3.3, teleportTab)'
    content = content.replace(target, toggle_str + "\n" + target)

    target2 = '''        if State.FlingAura then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= 15 then
                        hrp.Velocity = Vector3.new(0, flingVel, 0)
                        hrp.RotVelocity = Vector3.new(10000, 10000, 10000)
                    end
                end
            end
        end
    end
end))'''

    replacement2 = '''        if State.FlingAura then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= 15 then
                        hrp.Velocity = Vector3.new(0, flingVel, 0)
                        hrp.RotVelocity = Vector3.new(10000, 10000, 10000)
                    end
                end
            end
        end
        
        -- TELEPORT LOOP (Ke Pemain)
        if State.TeleportToSelected and State.SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(State.SelectedPlayer)
            local targetChar = targetPlayer and targetPlayer.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if hrp and targetHRP then
                hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end
end))'''
    
    content = content.replace(target2, replacement2)
    
    with open('tarung_menu_teleport.lua', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added TeleportToSelected logic")
else:
    print("Toggle already exists")

