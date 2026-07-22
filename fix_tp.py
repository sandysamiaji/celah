import re

with open('tarung_menu_teleport.lua', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('local HttpService = game:GetService(\"HttpService\")', 'local HttpService = game:GetService(\"HttpService\")\nlocal Lighting = game:GetService(\"Lighting\")\nlocal workspace = game:GetService(\"Workspace\")')
content = content.replace('spawn(function()', 'task.spawn(function()')
content = re.sub(r'(logFlingAnalytics\([^)]*\))', r'-- \1', content)

with open('tarung_menu_teleport.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed syntax errors')
