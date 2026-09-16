@echo off

for /f "usebackq delims=" %%a in (".env") do set %%a

set image=regions.png

python %MAPS_TOOLS%\regions.py "%image%" --skip-color "#333333" --dest-res 300000 --dx=-384375 --dy=365625  --simplify 10%% -o regions.json

