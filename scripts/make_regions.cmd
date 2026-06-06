rem npm install -g mapshaper

python make_regions.py
mapshaper regions.json -simplify dp 10%% -clean -explode -o ../data/regions.json

