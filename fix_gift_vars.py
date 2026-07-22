import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Make giftStatus global to State so the hook in cheats can access it
content = content.replace(
    'local giftStatus = Instance.new("TextLabel")',
    'local giftStatus = Instance.new("TextLabel")\nState.GiftStatusLabel = giftStatus'
)

# And dropItemDropdownBtn
content = content.replace(
    'dropItemDropdownBtn = Instance.new("TextButton")',
    'local dropItemDropdownBtn = Instance.new("TextButton")'
)

content = content.replace(
    'dropItemList = Instance.new("ScrollingFrame")',
    'local dropItemList = Instance.new("ScrollingFrame")'
)

content = content.replace(
    'dropItemLayout = Instance.new("UIListLayout")',
    'local dropItemLayout = Instance.new("UIListLayout")'
)

content = content.replace(
    'dropAmountInput = Instance.new("TextBox")',
    'local dropAmountInput = Instance.new("TextBox")'
)

content = content.replace(
    'autoDropBagBtn = Instance.new("TextButton")',
    'local autoDropBagBtn = Instance.new("TextButton")'
)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed variable scope in tarung_menu_gift.lua")
