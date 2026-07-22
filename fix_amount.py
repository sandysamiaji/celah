import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                            local newArgs = {}
                            local foundPos = false
                            for i, v in ipairs(State.GiftArgs) do
                                if typeof(v) == "CFrame" then
                                    newArgs[i] = CFrame.new(targetPos)
                                    foundPos = true
                                elseif typeof(v) == "Vector3" then
                                    newArgs[i] = targetPos
                                    foundPos = true
                                else
                                    newArgs[i] = v
                                end
                            end'''

replacement = '''                            local newArgs = {}
                            local foundPos = false
                            local overrideAmount = tonumber(dropAmountInput.Text)
                            for i, v in ipairs(State.GiftArgs) do
                                if typeof(v) == "CFrame" then
                                    newArgs[i] = CFrame.new(targetPos)
                                    foundPos = true
                                elseif typeof(v) == "Vector3" then
                                    newArgs[i] = targetPos
                                    foundPos = true
                                elseif type(v) == "number" and overrideAmount then
                                    newArgs[i] = overrideAmount
                                else
                                    newArgs[i] = v
                                end
                            end'''

content = content.replace(target, replacement)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated GiftArgs processing to use overrideAmount")
