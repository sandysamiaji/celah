import sys

with open(r'd:\PROJECT_SANDY\iseng lua\tarung_v3.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
out.append('-- ==========================================\n')
out.append('-- MENU FARM & LOGIC\n')
out.append('-- ==========================================\n')
out.append('local Players = game:GetService("Players")\n')
out.append('local RunService = game:GetService("RunService")\n')
out.append('local LocalPlayer = Players.LocalPlayer\n')
out.append('local ReplicatedStorage = game:GetService("ReplicatedStorage")\n\n')
out.append('local State = getgenv().PandaHub.State\n')
out.append('local UI = getgenv().PandaHub.UI\n')
out.append('local Tabs = getgenv().PandaHub.Tabs\n')
out.append('local track = getgenv().PandaHub.track\n\n')

# UI
ui_lines = lines[585:779]
for line in ui_lines:
    # replace createToggle(...) with UI.createToggle(...)
    line = line.replace('createToggle', 'UI.createToggle')
    out.append(line)

# Logic
logic_lines = lines[3282:3544]
for line in logic_lines:
    out.append(line)

with open(r'd:\PROJECT_SANDY\iseng lua\tarung_menu_farm.lua', 'w', encoding='utf-8') as f:
    f.writelines(out)
