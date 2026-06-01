import rasterio
import numpy as np
import rasterio.features
import json

base = 'regions'
INPUT = f'{base}.png'
GEOJSON = f'{base}.json'

src_res = 4096
chunk_size = 9375
dest_res = 32*chunk_size

SCALE_FACTOR = dest_res/src_res

dx = -41*chunk_size
dy = 39*chunk_size

colorMap = {
    '#eae600': { 'name': 'DA_CGShallows',      'title': 'Shallows'        },
    '#0055c4': { 'name': 'DA_CGPlateaus',      'title': 'Plateaus'        },
    '#720b0b': { 'name': 'DA_CGGraveyard',     'title': 'Graveyard'       },
    '#c4008f': { 'name': 'DA_CGAnemoneHills',  'title': 'Anemone Hills'   },
    '#d67fff': { 'name': 'DA_CGTufaTowers',    'title': 'Tufa Towers'     },
    '#079140': { 'name': 'DA_CGNorthRaceway',  'title': 'North Raceway'   },
    '#3b7000': { 'name': 'DA_CGSouthRaceway',  'title': 'South Raceway'   },
    '#c1c199': { 'name': 'DA_CGBlightedCoral', 'title': 'Blighted Coral'  },
    '#c45201': { 'name': 'DA_CGLeadzone',      'title': 'Leadzone'        },
    '#009ead': { 'name': 'DA_AR-Observatory',  'title': 'Observatory'     },
    '#ff4e32': { 'name': 'DA_AR-PowerPlant',   'title': 'Power Plant'     },
    '#f3ee70': { 'name': 'DA_AR-RootCanyon',   'title': 'Root Canyon'     },
};

# Load image with rasterio
with rasterio.open(INPUT) as src:
    height, width = src.height, src.width
    print(f"Input: {width} x {height}")
    
    # Read the single band (indexed colors)
    if src.count == 1:
        # Use the index values directly as labels
        labels = src.read(1).astype(np.uint32)
    else:
        # If RGB, encode to integer
        r = src.read(1)
        g = src.read(2)
        b = src.read(3)
        labels = (r.astype(np.uint32) << 16) | \
                 (g.astype(np.uint32) << 8) | \
                 b.astype(np.uint32)
    
    # Extract polygons
    results = rasterio.features.shapes(labels, connectivity=8)
    
    # Build features
    features = []
    for i, (geom, value) in enumerate(results):
        if geom['type'] != 'Polygon':
            continue

        intvalue = int(value)
        color = f'#{intvalue:06x}'
        #print(color)

        scaled_coords = [
            [[(x * SCALE_FACTOR) + dx, (y * SCALE_FACTOR) + dy] for x, y in ring]
            for ring in geom['coordinates']
        ]
        
        features.append({
            "type": "Feature",
            "geometry": { "type": "Polygon", "coordinates": scaled_coords },
            "properties": { "color": color }
        })

        p = colorMap.get(color)
        if p:
            features[-1]['properties']['name'] = p['name']
            features[-1]['properties']['title'] = p['title']

# Save GeoJSON
geojson = {
    "type": "FeatureCollection",
    "features": features
}

with open(GEOJSON, "w") as f:
    json.dump(geojson, f)

print(f"Done: {len(features)} polygons, {GEOJSON}")
