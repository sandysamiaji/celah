import re

with open('tarung_menu_teleport.lua', 'r', encoding='utf-8') as f:
    content = f.read()

toggle_str = 'UI.createToggle("TeleportToSelectedBtn", "Teleport (Pilih Pemain)", "TeleportToSelected", 3.2, teleportTab)'

if "TeleportToSelectedBtn" not in content:
    target = 'UI.createToggle("TeleportToMouseBtn", "Teleport ke Mouse (C)", "TeleportToMouse", 3.3, teleportTab)'
    content = content.replace(target, toggle_str + "\n" + target)

    # And we also need the logic in the main loop! But wait, teleport logic is usually in tarung_menu_cheats.lua or 
teleport menu?
    # In modular version, I moved all loops to tarung_menu_cheats.lua ?
    # No, each module has its own loops.
    
    with open('tarung_menu_teleport.lua', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added TeleportToSelected toggle")
else:
    print("Toggle already exists")

