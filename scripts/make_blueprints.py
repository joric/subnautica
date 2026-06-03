exports='C:/Temp/Exports/'

dirs = [
    'Subnautica2/Content/Blueprints/',
    ]

outfile = '../data/blueprints.json'

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

                name = None
                prop = {}

                for o in data:
                    if o['Type']=='BlueprintGeneratedClass':
                        name = o['Name']
                    elif o['Type']=='UWEAssetUserData':
                        assets = o.get('Properties', {}).get('DataAssets', [])
                        if isinstance(assets, list):
                            matches = [da['ObjectName'].split("'")[-2] for da in assets if da and 'ObjectName' in da and 'ScanData' in da['ObjectName']]
                            if matches:
                                prop['item'] = matches[0]
                                break

                if name and prop:
                    out[name] = prop

if __name__ == '__main__':


    for d in dirs:
        path = os.path.join(exports, d)
        read_files(path)

    print('collected', len(out), 'records')

    with open(outfile, 'w', encoding='utf-8') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
