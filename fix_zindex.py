import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'dropItemDropdownBtn.LayoutOrder = 10',
    'dropItemDropdownBtn.LayoutOrder = 10\ndropItemDropdownBtn.ZIndex = 20'
)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)
