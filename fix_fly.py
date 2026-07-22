import re

with open('tarung_menu_cheats.lua', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''          if State.Fly and root and hum then
              if not fakeFloor then
                  fakeFloor = Instance.new("Part")
                  fakeFloor.Size = Vector3.new(5, 1, 5)
                  fakeFloor.Anchored = true
                  fakeFloor.Transparency = 1
                  fakeFloor.CanCollide = true
                  fakeFloor.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                  fakeFloor.Parent = workspace
              end
              if not bbg then
                  bbg = Instance.new("BodyGyro")
                  bbg.P = 9e4
                  bbg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                  bbg.Parent = root
              end
              if not bve then
                  bve = Instance.new("BodyVelocity")
                  bve.maxForce = Vector3.new(9e9, 9e9, 9e9)
                  bve.Parent = root
              end'''

replacement = '''          if State.Fly and root and hum then
              if not fakeFloor or not fakeFloor.Parent then
                  if fakeFloor then fakeFloor:Destroy() end
                  fakeFloor = Instance.new("Part")
                  fakeFloor.Size = Vector3.new(5, 1, 5)
                  fakeFloor.Anchored = true
                  fakeFloor.Transparency = 1
                  fakeFloor.CanCollide = true
                  fakeFloor.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                  fakeFloor.Parent = workspace
              end
              if not bbg or bbg.Parent ~= root then
                  if bbg then bbg:Destroy() end
                  bbg = Instance.new("BodyGyro")
                  bbg.P = 9e4
                  bbg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                  bbg.Parent = root
              end
              if not bve or bve.Parent ~= root then
                  if bve then bve:Destroy() end
                  bve = Instance.new("BodyVelocity")
                  bve.maxForce = Vector3.new(9e9, 9e9, 9e9)
                  bve.Parent = root
              end'''

content = content.replace(target, replacement)

with open('tarung_menu_cheats.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed Fly logic for character respawn")
