import glob
import re

files = ["tarung_menu_cheats.lua", "tarung_menu_farm.lua", "tarung_menu_anti.lua"]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "local track = getgenv().PandaHub.track" not in content:
        # insert after local UI = getgenv().PandaHub.UI or something similar, or just at the top after requires
        if "local UI = getgenv().PandaHub.UI" in content:
            content = content.replace("local UI = getgenv().PandaHub.UI", "local UI = getgenv().PandaHub.UI\nlocal track = getgenv().PandaHub.track")
        elif "local State = getgenv().PandaHub.State" in content:
            content = content.replace("local State = getgenv().PandaHub.State", "local State = getgenv().PandaHub.State\nlocal track = getgenv().PandaHub.track")
        else:
            # just inject at line 10
            lines = content.split('\n')
            lines.insert(9, "local track = getgenv().PandaHub.track")
            content = '\n'.join(lines)
            
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Injected track to {file}")
    else:
        print(f"{file} already has track")

