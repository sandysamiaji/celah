with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

depth = 0
for i, line in enumerate(lines):
    # Quick strip
    l = line.split('--')[0]
    # This is a naive line-by-line check just to pinpoint roughly where the mismatch occurs
    import re
    tokens = re.findall(r'\b(if|function|do|then|elseif|else|end)\b', l)
    for t in tokens:
        if t in ['if', 'function', 'do']:
            depth += 1
        elif t == 'end':
            depth -= 1
            if depth < 0:
                print(f"Mismatch at line {i+1}: {line.strip()}")
                depth = 0
