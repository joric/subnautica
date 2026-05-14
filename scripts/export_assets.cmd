@echo off

rem download CUE4Parse.CLI here: https://github.com/joric/CUE4Parse.CLI

set root=E:\Games\Subnautica2
set out=C:\Temp\Exports

set opt=-i "%root%" -m "%root%\Subnautica2.usmap" -g GAME_UE5_6 -o "%out%"

cue4parse %opt% -c assetlist.txt

