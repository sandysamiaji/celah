import sys

with open(r'd:\PROJECT_SANDY\iseng lua\tarung_v3.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_header(title):
    return f"""-- ==========================================
-- {title}
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

"""

def write_file(filename, title, ui_range, logic_ranges):
    out = [get_header(title)]
    
    if ui_range:
        for i in range(ui_range[0], ui_range[1] + 1):
            line = lines[i]
            # Replace UI creation functions
            line = line.replace('createToggle', 'UI.createToggle')
            line = line.replace('createInfoBox', 'UI.createInfoBox')
            line = line.replace('createNavBtn', 'UI.createNavBtn')
            out.append(line)
            
    out.append('\n-- ==========================================\n')
    out.append('-- LOGIC\n')
    out.append('-- ==========================================\n')
    
    for logic_range in logic_ranges:
        for i in range(logic_range[0], logic_range[1] + 1):
            out.append(lines[i])

    with open(f'd:\\PROJECT_SANDY\\iseng lua\\{filename}', 'w', encoding='utf-8') as f:
        f.writelines(out)

# Note: Python uses 0-indexed arrays, so line X is index X-1.
# - INFO TAB: 524 - 585
write_file('tarung_menu_info.lua', 'MENU INFO & TRACKING', (523, 584), [])

# - FARM TAB: 586 - 824 and 3283 - 3545
write_file('tarung_menu_farm.lua', 'MENU FARM & AURA', (585, 823), [(3282, 3544)])

# - CHEATS TAB: 825 - 1596 and 3546 - 3844
write_file('tarung_menu_cheats.lua', 'MENU CHEATS', (824, 1595), [(3545, 3842)])

# - TELEPORT TAB: 1597 - 2186
write_file('tarung_menu_teleport.lua', 'MENU TELEPORT', (1596, 2185), [])

# - BUILDER TAB: 2187 - 2833
write_file('tarung_menu_builder.lua', 'MENU BUILDER', (2186, 2832), [])

# - GIFT TAB: 2834 - 3244
write_file('tarung_menu_gift.lua', 'MENU GIFT', (2833, 3243), [])

print("All menus extracted successfully!")
