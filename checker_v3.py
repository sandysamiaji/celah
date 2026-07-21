import re

def check(filename):
    with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()

    # Remove block comments
    text = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.DOTALL)
    # Remove line comments
    text = re.sub(r'--[^\n]*', '', text)
    # Remove double-quoted strings
    text = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '', text)
    # Remove single-quoted strings
    text = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", '', text)

    stack_paren = 0
    stack_curly = 0
    stack_square = 0
    lines = text.split('\n')

    for lineno, line in enumerate(lines, 1):
        for col, char in enumerate(line):
            if char == '(': stack_paren += 1
            elif char == ')': stack_paren -= 1
            elif char == '{': stack_curly += 1
            elif char == '}': stack_curly -= 1
            elif char == '[': stack_square += 1
            elif char == ']': stack_square -= 1
            
            if stack_paren < 0 or stack_curly < 0 or stack_square < 0:
                print(f'ERROR: NEGATIVE BRACKET at Line {lineno}, col {col}')
                print(f'  paren={stack_paren} curly={stack_curly} square={stack_square}')
                # Print surrounding lines for context
                start = max(0, lineno - 3)
                end = min(len(lines), lineno + 2)
                for i in range(start, end):
                    marker = '>>>' if i == lineno - 1 else '   '
                    print(f'  {marker} Line {i+1}: {lines[i]}')
                break
        else:
            continue
        break

    print(f'\nFINAL BRACKET COUNT: Paren={stack_paren}, Curly={stack_curly}, Square={stack_square}')
    if stack_paren == 0 and stack_curly == 0 and stack_square == 0:
        print('STATUS: ALL BALANCED - SYNTAX OK!')
    else:
        print('STATUS: ERROR - UNBALANCED BRACKETS!')

check('tarung_v3.lua')
