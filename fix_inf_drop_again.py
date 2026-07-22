import re

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                args[i] = -9999999 -- Underflow hack: Coba tipu server bahwa kita nge-drop minus'''
replacement = '''                args[i] = State.CustomDropAmount or -9999999 -- Mengambil jumlah dari UI Gift'''

content = content.replace(target, replacement)

with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated InfiniteDrop to use State.CustomDropAmount")
