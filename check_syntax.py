import sys
from luaparser import ast
from luaparser.astnodes import *

try:
    with open('rem.lua', 'r', encoding='utf-8') as f:
        src = f.read()
    tree = ast.parse(src)
    print("Syntax is OK!")
except Exception as e:
    print("Syntax Error!")
    print(str(e))
