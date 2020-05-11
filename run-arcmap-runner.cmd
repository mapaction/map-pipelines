:: @echo off

set script_root=%~dp0
::remove the trailing slash
set script_root=%script_root:~0,-1%
::call %root%\build-fresh-data.cmd
echo %script_root%
if not defined py set py=D:\MapAction\ve-with-arcmap2\Scripts\python.exe 
::set py=C:/py27arcgis106/ArcGIS10.6/python.exe

:: C:\py27arcgis106\ArcGIS10.6\python.exe -c 'import sys; print('\n'.join(sys.path)); import arcpy'
%py% -m coverage run -c 'import sys; print('\n'.join(sys.path)); import arcpy'


::set "productlist=("Country Overview with Admin 1 Boundaries and Topography", "Atlas Admin 1 Boundaries & P-Codes plus Admin 2 Boundaries""
rem set "productlist="Country Overview with Admin 1 Boundaries and Topography", "Atlas Admin 1 Boundaries & P-Codes plus Admin 2 Boundaries""

set "productlist="Country Overview with Admin 1 Boundaries and Topography", "Atlas Admin 1 Boundaries and P-Codes plus Admin 2 Boundaries""

echo %productlist%
::for %%G in (2019lka01 2019mli01 2019slv01) do (

::set opidlist=2019lka01 2019mli01 2019slv01
::set opidlist=2019lka01

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
)

rem -m coverage run  --append

::		%py% run --append -m mapactionpy_arcmap.arcmap_runner ^
::			--cookbook    "%root%\%%G\GIS\3_Mapping\31_Resources\316_Automation\mapCookbook.json" ^
::			--layerConfig "%root%\%%G\GIS\3_Mapping\31_Resources\316_Automation\layerProperties.json" ^
::			--cmf         "%root%\%%G\cmf_description.json" ^
::			--layerDirectory "%root%\%%G\GIS\3_Mapping\31_Resources\312_Layer_files" ^
::			--export ^
::			--product %%P
::		)

::"Country Overview with Admin 1 Boundaries and Topography"
::"Atlas Admin 1 Boundaries & P-Codes plus Admin 2 Boundaries"
::--template    "%root%\%%G\GIS\3_Mapping\32_Map_Templates\arcmap-10.6_reference_portrait_bottom.mxd" ^

%py% -m coverage html --include="D:/code/github/mapactionpy*"  --directory=%root%\htmlcov


