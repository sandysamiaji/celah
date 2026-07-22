import sys
import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    code = f.read()

# Strip strings
code = re.sub(r'\"(?:\\.|[^\\\"])*\"', '""', code)
code = re.sub(r'\'(?:\\.|[^\\\'])*\'', "''", code)
code = re.sub(r'\[\[.*?\]\]', '""', code, flags=re.DOTALL)
# Strip comments
code = re.sub(r'--\[\[.*?\]\]', '', code, flags=re.DOTALL)
code = re.sub(r'--.*', '', code)

# Tokenize with line numbers
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
            print(f"Unexpected 'end' at line {line}")
            depth = 0

print(f"Final depth: {depth}")
