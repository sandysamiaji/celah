import re

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

# Track Lua block opens and closes
# Keywords yang MEMBUKA block: function, if, for, while, do, repeat
# Keywords yang MENUTUP block: end, until
# Keywords yang ADA DI TENGAH (tidak buka/tutup baru): then, else, elseif, in

depth = 0
issues = []

# Remove string content before checking keywords
def strip_strings_and_comments(line):
    # Remove inline string literals and comments to avoid false positives
    result = ''
    i = 0
    while i < len(line):
        # Skip double-quoted strings
        if line[i] == '"':
            i += 1
            while i < len(line) and line[i] != '"':
                if line[i] == '\\':
                    i += 1  # skip escape
                i += 1
            i += 1
        # Skip single-quoted strings
        elif line[i] == "'":
            i += 1
            while i < len(line) and line[i] != "'":
                if line[i] == '\\':
                    i += 1
                i += 1
            i += 1
        # Skip comments
        elif line[i:i+2] == '--':
            break
        else:
            result += line[i]
            i += 1
    return result

for lineno, raw_line in enumerate(lines, 1):
    line = strip_strings_and_comments(raw_line)

    # Use word boundaries to avoid false matches (e.g., 'endif' or 'doSomething')
    # Find all keywords in order
    tokens = re.findall(r'\b(function|if|for|while|do|repeat|end|until|then|else|elseif)\b', line)

    for token in tokens:
        if token in ('function', 'if', 'for', 'while', 'do', 'repeat'):
            depth += 1
        elif token in ('end', 'until'):
            depth -= 1
            if depth < 0:
                issues.append('Line ' + str(lineno) + ': EXTRA end/until (depth went negative!) -> ' + raw_line.rstrip()[:80])
                depth = 0

if depth != 0:
    issues.append('FINAL: Block depth = ' + str(depth) + ' (should be 0!) - missing ' + str(depth) + ' "end" keyword(s)')

if issues:
    print('=== MASALAH DITEMUKAN ===')
    for issue in issues:
        print(issue)
else:
    print('OK: Semua block if/for/while/function/do/repeat sudah ditutup dengan end!')

print('Final depth: ' + str(depth))
