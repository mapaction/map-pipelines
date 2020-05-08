:: @echo off

set script_root=%~dp0
::remove the trailing slash
set script_root=%script_root:~0,-1%

if not defined data_src set data_src=D:\MapAction\metis\test-data
echo "data_src="
echo %data_src%

if not defined dest_root set dest_root=D:\MapAction\metis\test-suite
echo "dest_root="
echo %dest_root%

if not defined default_cmf set default_cmf=D:\code\github\default-crash-move-folder
echo "default_cmf="
echo %default_cmf%

if not defined opidlist set opidlist=2019lka01 2019mli01 2019slv01
echo "opidlist="
echo %opidlist%


for %%G in (%opidlist%) do (
	echo %%G
	echo "%dest_root%\%%G"
	
	:: Create 
	if not exist "%dest_root%\%%G" mkdir "%dest_root%\%%G"
	::call "%script_root%\refresh-default-cmf.cmd" "%dest_root%\%%G" 20YYiso3nn
	
	:: Copy everything non-country specific from the default-cmf
	robocopy ^
		%default_cmf%/20YYiso3nn ^
		%dest_root%\%%G ^
		/mir ^
		/log:%dest_root%\%%G\refresh-country-cmf.log ^
		/xd .git ^
		/xf .gitattributes ^
		/xf .gitignore ^
		/xf gocd.yaml ^
		/xf enable-empty-dir-in-github.txt ^
		/xd deploy-to-fileserver.cmd ^
		/xf deploy-to-fileserver.log ^
		/xf event_description.json ^
		/xd 2_Active_Data ^
		/xd 34_Map_Products_MapAction ^
		/xf refresh-country-cmf.log
	 
	:: Check the error code (anything less than 8 is OK.
	:: Greater or equal to 8 is a fail)
	if %errorlevel% geq 8 goto quit_error

	:: Copy `200_data_name_lookup` from the default-cmf
	robocopy ^
		%default_cmf%/20YYiso3nn/GIS/2_Active_Data/200_data_name_lookup ^
		%dest_root%\%%G/GIS/2_Active_Data/200_data_name_lookup ^
		/mir ^
		/log+:%dest_root%\%%G\refresh-country-cmf.log ^
		/xd .git ^
		/xf .gitattributes ^
		/xf .gitignore ^
		/xf enable-empty-dir-in-github.txt

	:: Check the error code (anything less than 8 is OK.
	:: Greater or equal to 8 is a fail)
	if %errorlevel% geq 8 goto quit_error

	:: Copy the country specific data into 2_Active_Data
	robocopy ^
		%data_src%\%%G\GIS\2_Active_Data ^
		%dest_root%\%%G\GIS\2_Active_Data ^
		/log+:%dest_root%\%%G\refresh-country-cmf.log ^
		/xd 200_data_name_lookup ^
		/xf event_description.json ^
		/mir
		
	if %errorlevel% geq 8 goto quit_error

	:: Copy the event description
	robocopy ^
		%data_src%\%%G ^
		%dest_root%\%%G event_description.json ^
		/log+:%dest_root%\%%G\refresh-country-cmf.log

	if %errorlevel% geq 8 goto quit_error

)


:finish
exit /b 0

:quit_error
exit /b %errorlevel%
