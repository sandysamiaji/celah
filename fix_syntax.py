import re

with open('tarung_menu_farm.lua', 'r', encoding='utf-8') as f:
    content = f.read()

bad_string = "end-- Farm loops (AutoEat, AutoHeal, AutoCook, AuraHarvest) have been moved to tarung_menu_farm.luand"

correct_ending = '''
                        end
                    end
                end
            end
        end
    end
end

spawn(function()
    while true do
        wait(1)
        if State.AuraHarvest then
            if not auraHarvestThread or coroutine.status(auraHarvestThread) == "dead" then
                auraHarvestThread = coroutine.create(auraHarvestLoop)
                coroutine.resume(auraHarvestThread)
            end
        end
    end
end)
'''

if bad_string in content:
    content = content.replace(bad_string, correct_ending)
    with open('tarung_menu_farm.lua', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed syntax error in tarung_menu_farm.lua")
else:
    print("Could not find the bad string.")
