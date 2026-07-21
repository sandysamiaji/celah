with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

checkpoints = [1, 50, 100, 150, 200, 250, 300, 500, 1000, 1500, 2000, 2500, 2900, 2957, 3000, 3050, 3100]
output = []
for i, line in enumerate(lines):
    lineno = i + 1
    if lineno in checkpoints:
        checkpoint_line = 'print("[CHECK ' + str(lineno) + '] OK")\n'
        output.append(checkpoint_line)
    output.append(line)

with open('d:/PROJECT_SANDY/iseng lua/tarung_debug.lua', 'w', encoding='utf-8') as f:
    f.writelines(output)

print('Debug file created!')
print('Total lines: ' + str(len(output)))
