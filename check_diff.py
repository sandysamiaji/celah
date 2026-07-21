import re
def get_features(file_path):
    features = set()
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            if 'createToggle(' in line:
                features.add(line.strip())
            m = re.search(r'\.Text\s*=\s*[\"\']([^\"\']+)[\"\']', line)
            if m:
                if 'Instance.new' not in line:
                    features.add(m.group(1))
    return features

v1 = get_features('d:/PROJECT_SANDY/iseng lua/tarung_v1.lua')
v3 = get_features('d:/PROJECT_SANDY/iseng lua/tarung_v3.lua')

print('Texts in v1 but not v3:')
for x in sorted(v1 - v3): print('  ', x)
