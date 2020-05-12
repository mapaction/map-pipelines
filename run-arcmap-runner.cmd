:: @echo off

set script_root=%~dp0
::remove the trailing slash
set script_root=%script_root:~0,-1%
::call %root%\build-fresh-data.cmd
echo %script_root%
if not defined py set py=D:\MapAction\ve-with-arcmap2\Scripts\python.exe 
::set py=C:/py27arcgis106/ArcGIS10.6/python.exe

rem Reset coverage measurement
if not exist %script_root%\..\.coverage del %script_root%\..\.coverage

if not defined tempoutputs set tempoutputs=%script_root%\tempoutputs
if not exist %tempoutputs% mkdir %tempoutputs%
if not defined outputmaps set outputmaps=%script_root%\..\outputmaps
if not exist %outputmaps% mkdir %outputmaps%

set "productlist="Country Overview with Admin 1 Boundaries and Topography", "Atlas Admin 1 Boundaries and P-Codes plus Admin 2 Boundaries""

echo %productlist%

for %%G in (%opidlist%) do (

	echo "checking layer files"
	%py% -m coverage run --append -m mapactionpy_controller.config_verify ^
		--cmf "%dest_root%\%%G\cmf_description.json" ^
		lp-vs-rendering ^
		--layer-file-extension lyr

	echo "checking config files"
	%py% -m coverage run --append -m mapactionpy_controller.config_verify ^
		--cmf "%dest_root%\%%G\cmf_description.json" ^
		lp-vs-cb

	echo "checking naming conventions"
	%py% -m coverage run --append -m mapactionpy_controller.check_naming_convention ^
		"%dest_root%\%%G\cmf_description.json" 

	for %%P in (%productlist%) do (
		echo "running mapchef"
		%py% -m coverage run --append -m mapactionpy_arcmap.arcmap_runner ^
			--eventConfigFile    "%dest_root%\%%G\event_description.json" ^
			--export ^
			--product %%P
		)

	rem Ugly hack to extract maps from CMFs whilst certain tools which won't deal with UNC paths
	robocopy %dest_root%\%%G\GIS\3_Mapping\34_Map_Products_MapAction %tempoutputs% *.jpg *.zip /mir
	if not exist %outputmaps%\%%G mkdir %outputmaps%\%%G
	forfiles -p %tempoutputs% -s -m *.* /c "cmd /c copy @path %outputmaps%\%%G\@file /y"
)



::"Country Overview with Admin 1 Boundaries and Topography"
::"Atlas Admin 1 Boundaries & P-Codes plus Admin 2 Boundaries"
::--template    "%root%\%%G\GIS\3_Mapping\32_Map_Templates\arcmap-10.6_reference_portrait_bottom.mxd" ^

%py% -m coverage html --include="D:/code/github/mapactionpy*"  --directory=%root%\htmlcov


