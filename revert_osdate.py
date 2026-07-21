# Revert os.date changes di tarung_v3.lua kembali ke versi tarung.lua yang bekerja
# Karena seluruhnya sudah dalam pcall, os.date tidak akan crash

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Revert os.date fix 1 (baris ~40)
old_fix1 = '''            local t = "Time"
            if os and type(os.date) == "function" then
                pcall(function() t = os.date("%Y-%m-%d %H:%M:%S") end)
            else
                t = tostring(math.floor(tick()))
            end'''

new_fix1 = '            local t = os.date("%Y-%m-%d %H:%M:%S")'

# Revert os.date fix 2 (baris ~133-141 - logAction function)
old_fix2 = '''local function logAction(action, text)
    local t = "Time"
    if os and type(os.date) == "function" then
        pcall(function() t = os.date("%H:%M:%S") end)
    else
        t = tostring(math.floor(tick() % 86400))
    end
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(logQueue, msg)
end'''

new_fix2 = '''local function logAction(action, text)
    local t = os.date("%H:%M:%S")
    local msg = string.format("[%s] %s | %s", t, action, text)
    table.insert(logQueue, msg)
end'''

count1 = content.count(old_fix1)
count2 = content.count(old_fix2)
print("Fix 1 found:", count1, "times")
print("Fix 2 found:", count2, "times")

if count1 > 0:
    content = content.replace(old_fix1, new_fix1)
    print("Fix 1 reverted!")
if count2 > 0:
    content = content.replace(old_fix2, new_fix2)
    print("Fix 2 reverted!")

with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'w', encoding='utf-8', newline='\r\n') as f:
    f.write(content)

print("Done!")

# Verify
with open('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()
print("Total lines now:", len(lines))
