import re

# Karena tarung.lua depth=74 dan tarung_v3.lua depth=77, ada 3 extra open block di v3
# Kita cari di baris-baris yang ADA DI v3 TAPI TIDAK DI tarung.lua

with open('d:/PROJECT_SANDY/iseng lua/tarung.lua', 'r', encoding='utf-8', errors='replace') as f:
    base_lines = f.readlines()

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8', errors='replace') as f:
    v3_lines = f.readlines()

def strip_strings_and_comments(line):
    result = ''
    i = 0
    while i < len(line):
        if line[i] == '"':
            i += 1
            while i < len(line) and line[i] != '"':
                if line[i] == '\\': i += 1
                i += 1
            i += 1
        elif line[i] == "'":
            i += 1
            while i < len(line) and line[i] != "'":
                if line[i] == '\\': i += 1
                i += 1
            i += 1
        elif line[i:i+2] == '--':
            break
        else:
            result += line[i]
            i += 1
    return result

def count_depth_change(line):
    clean = strip_strings_and_comments(line)
    tokens = re.findall(r'\b(function|if|for|while|do|repeat|end|until)\b', clean)
    delta = 0
    for t in tokens:
        if t in ('function', 'if', 'for', 'while', 'do', 'repeat'):
            delta += 1
        elif t in ('end', 'until'):
            delta -= 1
    return delta

# Buat set baris dari tarung.lua untuk perbandingan cepat
base_set = set(l.strip() for l in base_lines if l.strip())

# Cari baris di v3 yang TIDAK ada di tarung.lua DAN punya depth change positif (opens block)
print('=== Baris di tarung_v3.lua yang BUKA block tapi tidak ada di tarung.lua ===')
count = 0
for i, line in enumerate(v3_lines):
    stripped = line.strip()
    if stripped not in base_set:
        delta = count_depth_change(line)
        if delta > 0:
            print('Line ' + str(i+1) + ' (+' + str(delta) + '): ' + stripped[:80])
            count += 1

print('')
print('Total extra open blocks: ' + str(count))
