import sys

# Read v3
with open('tarung_v3.lua', 'r', encoding='utf-8') as f:
    lines_v3 = f.readlines()

# Extract tp container buttons
start_btn = -1
for i, l in enumerate(lines_v3):
    if l.startswith('local tpBtn = Instance.new("TextButton")'):
        start_btn = i
        break

end_btn = -1
for i in range(start_btn, len(lines_v3)):
    if 'markPosBtn.MouseButton1Click:Connect(function()' in lines_v3[i]:
        for j in range(i, len(lines_v3)):
            if 'end)' in lines_v3[j] and 'logAction("TELEPORT", "Telah kembali ke tempat yang ditandai")' in lines_v3[j-1]:
                end_btn = j + 1
                break
        break

if start_btn != -1 and end_btn != -1:
    buttons_code = ''.join(lines_v3[start_btn:end_btn])
else:
    print('Failed to find buttons')
    sys.exit(1)

# Extract checkTeleportRequirements
start_req = -1
end_req = -1
for i, l in enumerate(lines_v3):
    if l.startswith('local function checkTeleportRequirements()'):
        start_req = i
        break

for i in range(start_req, len(lines_v3)):
    if 'return true, myChar, targetChar, targetName' in lines_v3[i]:
        end_req = i + 2
        break

if start_req != -1 and end_req != -1:
    req_code = ''.join(lines_v3[start_req:end_req])
else:
    print('Failed to find req')
    sys.exit(1)

# Modify teleport_menu
with open('tarung_menu_teleport.lua', 'r', encoding='utf-8') as f:
    t_lines = f.readlines()

out = []
found_toggle = False
for l in t_lines:
    if 'UI.createToggle("TeleportToSelectedBtn"' in l:
        found_toggle = True
        continue
    out.append(l)
    if 'local refreshBtn = Instance.new("TextButton")' in l:
        # inject req_code above it? No, wait, refreshBtn is part of the player list container
        pass

# We will inject the req_code and buttons_code right after the player list refreshBtn logic.
# In tarung_menu_teleport.lua, let's find the end of refreshBtn.MouseButton1Click
inject_idx = -1
for i, l in enumerate(out):
    if 'populatePlayerList()' in l and 'refreshBtn.MouseButton1Click' in out[i-2]:
        inject_idx = i + 1
        break

if inject_idx != -1:
    # Inject 
    final_out = out[:inject_idx] + ['\n', req_code, '\n', buttons_code, '\n'] + out[inject_idx:]
    with open('tarung_menu_teleport.lua', 'w', encoding='utf-8') as f:
        f.writelines(final_out)
    print('Successfully patched tarung_menu_teleport.lua')
else:
    print('Could not find injection point.')

