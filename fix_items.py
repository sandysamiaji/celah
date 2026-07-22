import re

with open('tarung_menu_gift.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# The original ALL_GAME_ITEMS in tarung_v3.lua
correct_items = '''local ALL_GAME_ITEMS = {
    "Semua Item",
    "Wood", "Stone", "Rock", "Iron Ore", "Gold Ore",
    "Fiber", "Leaves", "Plant", "Raw Meat", "Cooked Meat",
    "Sun Fruit", "Blood Fruit", "Blue Fruit", "Jelly",
    "Ice", "Coconut", "Fish", "Cooked Fish", "Water",
    "Corn", "Berries", "Crystal", "Magnetite", "Steel",
    "Adurite", "Essence", "Crystal Chunk", "Steel Chunk",
    "God Rock", "Coin", "Coins", "Token", "Tokens", "Survivor Token", "Survivor Tokens",
    "Fiber Seeds", "Berry Seeds", "Corn Seeds",
    "Sun Fruit Seeds", "Blood Fruit Seeds", "Blue Fruit Seeds", "Animal Hide"
}'''

# Replace the giant ALL_GAME_ITEMS block with the original one
pattern = re.compile(r'local ALL_GAME_ITEMS = \{.*?\n\}', re.DOTALL)
content = re.sub(pattern, correct_items, content)

with open('tarung_menu_gift.lua', 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted ALL_GAME_ITEMS to tarung_v3.lua's original list.")
