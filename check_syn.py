import re
import sys

def check_balance(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        code = f.read()

    # Strip comments
    code = re.sub(r'--\[\[.*?\]\]', '', code, flags=re.DOTALL)
    code = re.sub(r'--.*', '', code)
    # Strip strings
    code = re.sub(r'\"(?:\\.|[^\\\"])*\"', '""', code)
    code = re.sub(r'\'(?:\\.|[^\\\'])*\'', "''", code)
    code = re.sub(r'\[\[.*?\]\]', '""', code, flags=re.DOTALL)

    tokens = re.findall(r'\b(if|function|do|then|elseif|else|end)\b', code)
    
    # Very basic balance check
    depth = 0
    for t in tokens:
        if t in ['if', 'function', 'do']:
            depth += 1
        elif t == 'end':
            depth -= 1
            if depth < 0:
                print(f"{file_path}: Found unexpected 'end'")
                return False

    if depth != 0:
        print(f"{file_path}: Mismatched block depth (depth={depth})")
        return False
    return True

files = ['tarung_menu_gift.lua', 'tarung_menu_cheats.lua', 'tarung_menu_farm.lua', 'menu_tarung.lua']
all_ok = True
for f in files:
    if not check_balance(f):
        all_ok = False

if all_ok:
    print("No blatant block mismatches found.")
