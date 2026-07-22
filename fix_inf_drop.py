import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Make dropAmountInput update State.CustomDropAmount
injection = '''local dropAmountInput = Instance.new("TextBox")
State.CustomDropAmount = -9999999
dropAmountInput.FocusLost:Connect(function()
    State.CustomDropAmount = tonumber(dropAmountInput.Text) or -9999999
end)'''

content = content.replace('local dropAmountInput = Instance.new("TextBox")', injection)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Update InfiniteDrop to use State.CustomDropAmount
target = '''                args[i] = -999999 -- Underflow hack: Coba tipu server bahwa kita nge-drop minus'''
replacement = '''                args[i] = State.CustomDropAmount or -9999999 -- Underflow hack: Ambil dari UI depan'''
content = content.replace(target, replacement)

with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
    f.write(content)

print("Wired CustomDropAmount to UI and InfiniteDrop")
