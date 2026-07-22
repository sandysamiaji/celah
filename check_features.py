import re

def get_toggles(file):
    with open(file, 'r', encoding='utf-8') as f:
        code = f.read()
    toggles = re.findall(r'createToggle\([^,]+,\s*"([^"]+)"', code)
    buttons = re.findall(r'\w+\.Text\s*=\s*"([^"]+)"', code)
    # just print all the distinct strings that look like button or toggle names
    return set(toggles), set(buttons)

v3_toggles, v3_btns = get_toggles('tarung_v3.lua')
v2_toggles, v2_btns = get_toggles('tarung_v2.lua')

modular_files = [
    'tarung_menu_farm.lua', 'tarung_menu_cheats.lua', 
    'tarung_menu_teleport.lua', 'tarung_menu_builder.lua', 
    'tarung_menu_gift.lua', 'tarung_menu_info.lua', 
    'tarung_menu_anti.lua'
]

mod_toggles = set()
mod_btns = set()
for m in modular_files:
    try:
        t, b = get_toggles(m)
        mod_toggles.update(t)
        mod_btns.update(b)
    except:
        pass

print("V3 Toggles missing in modular:", v3_toggles - mod_toggles)
print("V2 Toggles missing in modular:", v2_toggles - mod_toggles)

