import re

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('giftStatus.Text', 'State.GiftStatusLabel.Text')
content = content.replace('giftStatus.TextColor3', 'State.GiftStatusLabel.TextColor3')

with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated giftStatus references in tarung_menu_cheats.lua")
