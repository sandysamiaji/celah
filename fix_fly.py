import re

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''            local moveVec = getMoveVector()
            local dir = camera.CFrame.LookVector * -moveVec.Z + camera.CFrame.RightVector * moveVec.X
            if dir.Magnitude > 0 then
                dir = dir.Unit
            end
            
            bve.velocity = dir * State.FlySpeed'''

replacement = '''            local moveVec = getMoveVector()
            local dir = camera.CFrame.LookVector * -moveVec.Z + camera.CFrame.RightVector * moveVec.X
            if dir.Magnitude > 0 then
                dir = dir.Unit
            else
                -- Mencegah bug karakter melayang pelan ke atas setelah fitur Lock/Assassin dimatikan
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
            
            bve.velocity = dir * State.FlySpeed'''

if target in content:
    content = content.replace(target, replacement)
    
    # Also fix the fakeFloor height calculation
    target2 = '''            -- Pasang lantai di bawah kaki agar animasi jalan/idle tetap berjalan
            fakeFloor.CFrame = root.CFrame - Vector3.new(0, 3.2, 0)'''
            
    replacement2 = '''            -- Pasang lantai di bawah kaki agar animasi jalan/idle tetap berjalan secara dinamis
            local hipHeight = hum.HipHeight > 0 and hum.HipHeight or 2
            local dropOffset = hipHeight + (root.Size.Y / 2) + 0.2
            fakeFloor.CFrame = root.CFrame - Vector3.new(0, dropOffset, 0)'''
            
    content = content.replace(target2, replacement2)
    
    with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed Fly logic in cheats menu")
else:
    print("Target not found")
