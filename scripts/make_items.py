exports='C:/Temp/Exports/'

dirs = [
    'Subnautica2/Content/Data/CraftingRecipes',
    'Subnautica2/Content/Data/ItemType',
    'Subnautica2/Content/Data/BaseBuilding',
    ]

outfile = '../data/items.json'

import os
import sys
import json

out = {}

def read_files(directory, extensions=['.json']):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if not any(file.endswith(ext) for ext in extensions): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8-sig', errors='ignore') as f:
                data = json.load(f)
                #print(f"--- {filepath} ---")
                #print(content[:500])  # preview first 500 chars
                #print()
                #print(filepath)

                for o in data:
                    key = o['Name']
                    p = o['Properties']
                    prop = {}
                    #prop['file'] = file
                    if 'Name' in p:
                        if 'TableId' in p['Name']:
                            prop['text_id'] = p['Name']['TableId'].split('.')[-1] + '/' + p['Name']['Key']
                        elif 'LocalizedString' in p['Name']:
                            prop['name'] = p['Name']['LocalizedString']
                    out[key] = prop

if __name__ == '__main__':


    for d in dirs:
        path = os.path.join(exports, d)
        read_files(path)

    print('collected', len(out), 'records')

    with open(outfile, 'w', encoding='utf-8') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)


