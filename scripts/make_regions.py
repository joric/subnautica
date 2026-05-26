import rasterio
import numpy as np
import rasterio.features
import json

base = 'regions'
INPUT = f'{base}.png'
GEOJSON = f'regions.json'
SCALE_FACTOR = 1

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
        
        scaled_coords = [
            [[x * SCALE_FACTOR, y * SCALE_FACTOR] for x, y in ring]
            for ring in geom['coordinates']
        ]
        
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": scaled_coords
            },
            "properties": {"svgId": f"#{i}", "value": int(value)}
        })

# Save GeoJSON
geojson = {
    "type": "FeatureCollection",
    "features": features
}

with open(GEOJSON, "w") as f:
    json.dump(geojson, f)

print(f"Done: {len(features)} polygons, {GEOJSON}")
