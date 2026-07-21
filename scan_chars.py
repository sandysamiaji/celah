with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'rb') as f:
    content = f.read()

lines = content.split(b'\r\n')
suspicious = []
for lineno, line in enumerate(lines, 1):
    for col, byte in enumerate(line):
        if byte > 127 or (byte < 32 and byte not in [9, 10, 13]):
            ctx = ''
            try:
                ctx = line.decode('utf-8', errors='replace').strip()[:80]
            except:
                ctx = repr(line[:40])
            suspicious.append((lineno, col, byte, ctx))

if suspicious:
    print('DITEMUKAN KARAKTER MENCURIGAKAN:')
    for lineno, col, byte, ctx in suspicious[:50]:
        hex_val = format(byte, '02x')
        print('Line ' + str(lineno) + ', Col ' + str(col) + ': 0x' + hex_val + ' (' + str(byte) + ')')
        print('  Context: ' + ctx[:70])
else:
    print('Tidak ada karakter mencurigakan - file bersih')

print('')
print('Total lines: ' + str(len(lines)))
print('Total bytes: ' + str(len(content)))
