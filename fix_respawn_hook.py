import re

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# AutoRespawn block
auto_respawn_hook = '''    -- Auto Respawn block
    if State.AutoRespawn and method == "FireServer" and self.Name == "OnDied" then
        return nil
    end
'''
# add it before Infinite Drop
target = '''    -- Infinite Drop / Duplication Exploit (Spoofing Drop Amount)'''
if "OnDied" not in content:
    content = content.replace(target, auto_respawn_hook + "\n" + target)

with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print("Injected AutoRespawn OnDied block")
