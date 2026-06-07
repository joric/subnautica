rem npm install -g mapshaper

python make_regions.py

rem use Visvalingam / weighted area (by default) simplification to 10%

mapshaper regions.json -simplify 10%% -clean -explode -o prettify ../data/regions.json

