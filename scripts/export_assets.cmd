@echo off

rem download CUE4Parse.CLI here: https://github.com/joric/CUE4Parse.CLI

set root=E:\Games\Subnautica 2
set out=C:\Temp\Exports

set opt=-i "%root%" -m "%root%\Subnautica2\Binaries\Win64\ue4ss\Subnautica2-5.6.1-112084+++Project+SN2-Release-Hotfix-dd6777a8.usmap" -g GAME_UE5_6 -o "%out%"

cue4parse %opt% -c assetlist.txt

