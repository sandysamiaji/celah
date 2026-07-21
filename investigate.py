# Strategy baru: AMBIL tarung_v3.lua tapi KEMBALIKAN bagian os.date ke versi tarung.lua (working)
# Karena masalahnya mungkin dari perubahan os.date yang menambah baris dan menggeser struktur

with open('d:/PROJECT_SANDY/iseng lua/tarung.lua', 'r', encoding='utf-8') as f:
    working_lines = f.readlines()

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    v3_lines = f.readlines()

# Dari diff, perbedaan dimulai di baris 40
# tarung.lua baris 40: local t = os.date(...)
# tarung_v3.lua baris 40-45: kode fix os.date yang lebih panjang

# Cari di v3 di mana bagian os.date fix berakhir (kembali sinkron dengan tarung.lua)
# Di tarung.lua setelah os.date ada: "-- Mendapatkan Executor Name" di baris 42
# Di v3.lua hal yang sama ada di baris 47

# Cek berapa baris offset-nya
print("tarung.lua baris 40-50:")
for i in range(39, 50):
    print(f"  {i+1}: {working_lines[i].rstrip()}")

print()
print("tarung_v3.lua baris 40-50:")
for i in range(39, 50):
    print(f"  {i+1}: {v3_lines[i].rstrip()}")
