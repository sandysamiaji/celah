with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    local dropRemote = State.GiftRemote
    if not dropRemote then
        autoDropBagBtn.Text = "Remote tidak ditemukan!"'''

replacement = '''    local dropRemote = State.GiftRemote
    if not dropRemote then
        -- Cari langsung di ReplicatedStorage kalau belum ter-capture
        for _, desc in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if desc:IsA("RemoteEvent") and (desc.Name == "Drop" or desc.Name == "DropItem" or desc.Name == "DropItems") then
                dropRemote = desc
                break
            end
        end
    end
    if not dropRemote then
        autoDropBagBtn.Text = "Remote tidak ditemukan!"'''

content = content.replace(target, replacement)

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'w', encoding='utf-8', newline='') as f:
    f.write(content)

print("Patch applied for auto-finding Drop Remote!")
