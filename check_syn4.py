import sys
import glob
import re

files = glob.glob("*.lua")
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        code = file.read()
    
    # Strip strings
    code = re.sub(r'\"(?:\\.|[^\\\"])*\"', '""', code)
    code = re.sub(r'\'(?:\\.|[^\\\'])*\'', "''", code)
    code = re.sub(r'\[\[.*?\]\]', '""', code, flags=re.DOTALL)
    # Strip comments
    code = re.sub(r'--\[\[.*?\]\]', '', code, flags=re.DOTALL)
    code = re.sub(r'--.*', '', code)
    
    tokens = []
    lines = code.split('\n')
    for i, line in enumerate(lines):
        words = re.findall(r'\b(if|function|do|end)\b', line)
        for w in words:
            tokens.append((w, i+1))
    
    depth = 0
    for w, line in tokens:
        if w in ['if', 'function', 'do']:
            depth += 1
        elif w == 'end':
            depth -= 1
            if depth < 0:
                print(f"{f}: Unexpected 'end' at line {line}")
                depth = 0
    
    if depth != 0:
        print(f"{f}: Final depth {depth}")

print("Syntax check complete.")
