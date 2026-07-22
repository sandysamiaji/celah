import sys
with open('tarung_v3.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if line.startswith('local tpBtn = Instance.new("TextButton")'):
        start_idx = i
        break

if start_idx != -1:
    for i in range(start_idx, len(lines)):
        if 'markPosBtn.MouseButton1Click:Connect(function()' in lines[i]:
            # find end of markPosBtn connection
            for j in range(i, len(lines)):
                if 'end)' in lines[j] and 'logAction("TELEPORT", "Telah kembali ke tempat yang ditandai")' in lines[j-1]:
                    end_idx = j + 1
                    break
            break

if start_idx != -1 and end_idx != -1:
    with open('teleport_buttons.lua', 'w', encoding='utf-8') as f:
        f.writelines(lines[start_idx:end_idx])
    print(f'Extracted {end_idx - start_idx} lines of teleport buttons.')
else:
    print('Could not find boundaries.')
