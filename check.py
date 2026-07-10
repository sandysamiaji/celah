import sys, re

def check_lua_balance(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Hapus komentar multiline
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    # Hapus komentar single line
    content = re.sub(r'--.*', '', content)
    # Hapus string
    content = re.sub(r'"(?:\\.|[^"\\])*"', '""', content)
    content = re.sub(r"'(?:\\.|[^'\\])*'", "''", content)

    # Kata kunci yang menambah blok (disederhanakan, if/do/while/for/function)
    # Peringatan: if/do/while/for/function masing-masing menambah 1.
    # elseif/else tidak menambah atau mengurangi.
    tokens = re.findall(r'\b(function|if|do|while|for|end)\b', content)
    
    count = 0
    for t in tokens:
        if t in ['function', 'if', 'do', 'while', 'for']:
            count += 1
        elif t == 'end':
            count -= 1
            if count < 0:
                print(f"Error: Too many 'end's! Encountered extra 'end' at some point.")
                return False

    print(f"Final block count: {count}")
    if count == 0:
        print("Blocks are balanced!")
    else:
        print("Blocks are NOT balanced!")

check_lua_balance('rem.lua')
