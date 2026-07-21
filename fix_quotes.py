with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

# Baris 2957-3100 pakai single quote, ganti jadi double quote
# Tapi hati-hati: hanya ubah baris yang kita tulis (yang pakai single quote konsisten)
new_lines = list(lines)
count = 0
for i in range(2956, min(3130, len(new_lines))):
    line = new_lines[i]
    # Jika baris ini punya single quote tapi tidak ada double quote: aman untuk convert
    if "'" in line and '"' not in line:
        # Ganti semua single quote jadi double quote
        new_lines[i] = line.replace("'", '"')
        count += 1
        print("Changed line " + str(i+1) + ": " + new_lines[i].strip())

new_content = '\n'.join(new_lines)
with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("\nTotal lines changed: " + str(count))
