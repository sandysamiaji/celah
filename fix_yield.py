import re

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''pcall(function()
    local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
    local controls = PlayerModule:GetControls()
    getMoveVector = function()
        return controls:GetMoveVector()
    end
end)'''

replacement = '''task.spawn(function()
    pcall(function()
        local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5))
        local controls = PlayerModule:GetControls()
        getMoveVector = function()
            return controls:GetMoveVector()
        end
    end)
end)'''

if target in content:
    content = content.replace(target, replacement)
    with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed getMoveVector yielding")
else:
    print("Target not found")
