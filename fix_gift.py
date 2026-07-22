import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix layout orders
content = re.sub(r'autoGiftBtn\.LayoutOrder = .*', 'autoGiftBtn.LayoutOrder = 2', content)
content = re.sub(r'giftTpDelayContainer\.LayoutOrder = .*', 'giftTpDelayContainer.LayoutOrder = 3', content)
content = re.sub(r'giftDropDelayContainer\.LayoutOrder = .*', 'giftDropDelayContainer.LayoutOrder = 4', content)
content = re.sub(r'giftStatus\.LayoutOrder = .*', 'giftStatus.LayoutOrder = 5', content)
content = re.sub(r'refreshGiftBtn\.LayoutOrder = .*', 'refreshGiftBtn.LayoutOrder = 6', content)
content = re.sub(r'giftBtnContainer\.LayoutOrder = .*', 'giftBtnContainer.LayoutOrder = 7', content)
content = re.sub(r'giftPlayerList\.LayoutOrder = .*', 'giftPlayerList.LayoutOrder = 8', content)

# Drop bag section
content = re.sub(r'dropItemDropdownBtn\.LayoutOrder = .*', 'dropItemDropdownBtn.LayoutOrder = 10', content)
content = re.sub(r'dropAmountInput\.LayoutOrder = .*', 'dropAmountInput.LayoutOrder = 11', content)
content = re.sub(r'autoDropBagBtn\.LayoutOrder = .*', 'autoDropBagBtn.LayoutOrder = 12', content)

# Inject the divider before dropItemDropdownBtn
divider_code = '''
local dropDivider = Instance.new("TextLabel")
dropDivider.Size = UDim2.new(0.9, 0, 0, 20)
dropDivider.BackgroundTransparency = 1
dropDivider.Text = "--- Manual Drop (Isi Tas) ---"
dropDivider.TextColor3 = Color3.fromRGB(150, 150, 150)
dropDivider.Font = Enum.Font.GothamBold
dropDivider.TextSize = 12
dropDivider.LayoutOrder = 9
dropDivider.Parent = giftTab

dropItemDropdownBtn = Instance.new("TextButton")
'''
content = content.replace('dropItemDropdownBtn = Instance.new("TextButton")', divider_code)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated layout orders and added divider.')
