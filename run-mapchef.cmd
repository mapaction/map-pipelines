
set script_root=%~dp0
::remove the trailing slash
set script_root=%script_root:~0,-1%

rem "%MAPCHEF_EVENT_DESC%\event_description.json"

if not defined MAPCHEF_EVENT_DESC goto :failure

if not defined tempoutputs set tempoutputs=%script_root%\tempoutputs
if not exist %tempoutputs% mkdir %tempoutputs%
if not defined outputmaps set outputmaps=%script_root%\..\outputmaps
if not exist %outputmaps% mkdir %outputmaps%


set "productlist="Country Overview with Admin 1 Boundaries and Topography", "Atlas Admin 1 Boundaries and P-Codes plus Admin 2 Boundaries""

for %%P in (%productlist%) do (
	echo "running mapchef"
	%py% -m coverage run --append -m mapactionpy_arcmap.arcmap_runner ^
		--eventConfigFile "%MAPCHEF_EVENT_DESC%" ^
		--export ^
		--product %%P
	)

call :copy_maps_as_output %MAPCHEF_EVENT_DESC%
goto :eof

:failure
exit /999

:copy_maps_as_output
set MAPCHEF_CMF=%~dp1

rem Ugly hack to extract maps from CMFs whilst certain tools which won't deal with UNC paths
robocopy %MAPCHEF_CMF%\GIS\3_Mapping\34_Map_Products_MapAction %tempoutputs% *.jpg *.zip /mir > nul
if not exist %outputmaps% mkdir %outputmaps%
forfiles -p %tempoutputs% -s -m *.* /c "cmd /c copy @path %outputmaps%\@file /y" > nul
echo have probably just copied some files
exit /b