import re

def check():
    with open('tarung_v1.lua', 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()

    text = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.DOTALL)
    text = re.sub(r'--.*', '', text)
    text = re.sub(r'".*?"', '', text)
    text = re.sub(r'\'.*?\'', '', text)

    stack_paren = 0
    stack_curly = 0
    stack_square = 0
    
    for char in text:
        if char == '(': stack_paren += 1
        elif char == ')': stack_paren -= 1
        elif char == '{': stack_curly += 1
        elif char == '}': stack_curly -= 1
        elif char == '[': stack_square += 1
        elif char == ']': stack_square -= 1
        
        if stack_paren < 0 or stack_curly < 0 or stack_square < 0:
            print("Negative stack!")
            break

    print(f"Paren: {stack_paren}, Curly: {stack_curly}, Square: {stack_square}")

check()
