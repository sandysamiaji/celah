import re

with open('tarung_menu_farm.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''track(RunService.RenderStepped:Connect(function()
    processLogQueue()
    local currentTime = tick()'''

replacement = '''track(RunService.RenderStepped:Connect(function()
    local currentTime = tick()'''

if target in content:
    content = content.replace(target, replacement)
    with open('tarung_menu_farm.lua', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Removed processLogQueue from farm loop")
else:
    print("Target not found")
