import re

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Hapus semua karakter di luar Basic Multilingual Plane (emoji 4-byte)
# Karakter valid: U+0000 sampai U+FFFF (2-byte atau kurang)
# Emoji biasanya di U+1F000 dan seterusnya

def remove_emoji(text):
    # Hapus semua karakter dengan code point > 0xFFFF (4-byte UTF-8 di Lua 5.1)
    result = []
    for char in text:
        if ord(char) <= 0xFFFF:
            result.append(char)
        else:
            # Ganti emoji dengan teks kosong atau placeholder ASCII
            # Cek beberapa emoji umum
            emoji_map = {
                '\U0001F680': '[rocket]',  # 🚀
                '\U0001F464': '[user]',    # 👤
                '\U0001F4BB': '[laptop]',  # 💻
                '\U0001F4E6': '[package]', # 📦
                '\U0001F30D': '[globe]',   # 🌍
                '\U0001F511': '[key]',     # 🔑
                '\U0001F6E1': '[shield]',  # 🛡
                '\U0001F525': '[fire]',    # 🔥
                '\U00002705': '[check]',   # ✅
                '\U0001F4A1': '[bulb]',    # 💡
            }
            replacement = emoji_map.get(char, '')
            result.append(replacement)
    return ''.join(result)

new_content = remove_emoji(content)

# Hitung berapa emoji yang dihapus
removed = sum(1 for c in content if ord(c) > 0xFFFF)
print('Emoji/4-byte chars removed: ' + str(removed))

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'w', encoding='utf-8', newline='') as f:
    f.write(new_content)

print('File saved!')

# Verify no more 4-byte chars
with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'rb') as f:
    raw = f.read()

remaining = sum(1 for b in raw if b >= 0xF0)
print('Remaining 4-byte UTF-8 bytes (0xF0+): ' + str(remaining))
if remaining == 0:
    print('BERSIH! Tidak ada lagi emoji/4-byte chars')
else:
    print('MASIH ADA! Perlu dicek lagi')
