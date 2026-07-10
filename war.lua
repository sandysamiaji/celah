local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

local TARGET_REMOTES = {
    ["PlacementRequest"] = true,
    ["MissileLaunchRequest"] = true
}

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and method == "FireServer" and TARGET_REMOTES[self.Name] then
        local modified = false
        
        -- Loop melalui setiap argumen yang dikirim ke server
        for i, arg in ipairs(args) do
            if type(arg) == "number" then
                -- Jika server meminta pengurangan item (-1)
                -- Kita ubah jadi penambahan (99999) atau biarkan 0 agar tidak berkurang
                if arg == -1 or arg == 1 then
                    args[i] = 99999
                    modified = true
                end
            elseif type(arg) == "table" then
                -- Terkadang argumen dikirim di dalam table (misal: {amount = -1})
                for k, v in pairs(arg) do
                    if type(v) == "number" and (v == -1 or v == 1) then
                        -- Kita hindari mengubah koordinat (X, Y, Z) jika kebetulan bernilai 1 / -1
                        if k == "amount" or k == "qty" or k == "quantity" or type(k) == "number" then
                            arg[k] = 99999
                            modified = true
                        end
                    end
                end
            end
        end
        
        if modified then
            print("[+] Berhasil memodifikasi argumen " .. self.Name .. " menjadi 99999!")
        end
        
        return oldNamecall(self, unpack(args))
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
print("Missile Dupe/Infinite Script Loaded! Silakan coba letakkan/luncurkan misil.")
