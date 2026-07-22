import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target1 = '''dropItemDropdownBtn.Text = "Semua Item"'''
replacement1 = '''dropItemDropdownBtn.Text = "Semua Item"
State.CustomDropItem = "Semua Item"'''
content = content.replace(target1, replacement1)

target2 = '''        dropItemDropdownBtn.Text = itemName
        dropItemList.Visible = false'''
replacement2 = '''        dropItemDropdownBtn.Text = itemName
        State.CustomDropItem = itemName
        dropItemList.Visible = false'''
content = content.replace(target2, replacement2)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target3 = '''    if State.InfiniteDrop and method == "FireServer" and (self.Name == "Drop" or self.Name == "DropItem" or self.Name == "DropItems") then
        for i, v in ipairs(args) do
            if type(v) == "number" then
                args[i] = State.CustomDropAmount or -9999999 -- Mengambil jumlah dari UI Gift
            end
        end
        return oldNamecall(self, unpack(args))
    end'''

replacement3 = '''    if State.InfiniteDrop and method == "FireServer" and (self.Name == "Drop" or self.Name == "DropItem" or self.Name == "DropItems") then
        for i, v in ipairs(args) do
            if type(v) == "number" then
                args[i] = State.CustomDropAmount or -9999999 -- Mengambil jumlah dari UI Gift
            elseif type(v) == "string" and State.CustomDropItem and State.CustomDropItem ~= "Semua Item" then
                args[i] = State.CustomDropItem -- Mengambil nama item dari UI Gift
            end
        end
        return oldNamecall(self, unpack(args))
    end'''
content = content.replace(target3, replacement3)

with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated InfiniteDrop to spoof both amount and item name")
