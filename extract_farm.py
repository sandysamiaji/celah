import sys
with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if line.startswith('local autoEatThread'):
        start_idx = i
        break

if start_idx != -1:
    # Find the end of auraHarvestLoop or where the old AuraKill comment is
    for i in range(start_idx, len(lines)):
        if '-- Old AuraKill loop removed' in lines[i]:
            end_idx = i
            break

if start_idx != -1 and end_idx != -1:
    farm_code = ''.join(lines[start_idx:end_idx])
    
    # Remove from cheats
    new_cheats = lines[:start_idx] + lines[end_idx:]
    with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
        f.writelines(new_cheats)
        
    with open('farm_logic.lua', 'w', encoding='utf-8') as f:
        f.write(farm_code)
    print(f'Extracted {end_idx - start_idx} lines of farm logic.')
else:
    print('Could not find boundaries.')
