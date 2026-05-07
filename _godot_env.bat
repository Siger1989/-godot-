@echo off
rem Resolve Godot executables for the current Windows user/machine.
rem Optional overrides:
rem   set GODOT_GUI_EXE=C:\path\to\Godot_v4.6.2-stable_win64.exe
rem   set GODOT_CONSOLE_EXE=C:\path\to\Godot_v4.6.2-stable_win64_console.exe
rem   set GODOT_EXE=C:\path\to\Godot_v4.6.2-stable_win64_console.exe

if not "%GODOT_GUI_EXE%"=="" if not exist "%GODOT_GUI_EXE%" set "GODOT_GUI_EXE="
if not "%GODOT_CONSOLE_EXE%"=="" if not exist "%GODOT_CONSOLE_EXE%" set "GODOT_CONSOLE_EXE="

if not "%GODOT_EXE%"=="" if exist "%GODOT_EXE%" (
    if "%GODOT_GUI_EXE%"=="" set "GODOT_GUI_EXE=%GODOT_EXE%"
    if "%GODOT_CONSOLE_EXE%"=="" set "GODOT_CONSOLE_EXE=%GODOT_EXE%"
)

set "_WINGET_GODOT_DIR=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"

if "%GODOT_GUI_EXE%"=="" if exist "%_WINGET_GODOT_DIR%\Godot_v4.6.2-stable_win64.exe" set "GODOT_GUI_EXE=%_WINGET_GODOT_DIR%\Godot_v4.6.2-stable_win64.exe"
if "%GODOT_CONSOLE_EXE%"=="" if exist "%_WINGET_GODOT_DIR%\Godot_v4.6.2-stable_win64_console.exe" set "GODOT_CONSOLE_EXE=%_WINGET_GODOT_DIR%\Godot_v4.6.2-stable_win64_console.exe"

call :find_where GODOT_GUI_EXE Godot_v4.6.2-stable_win64.exe
call :find_where GODOT_CONSOLE_EXE Godot_v4.6.2-stable_win64_console.exe
call :find_where GODOT_GUI_EXE Godot.exe
call :find_where GODOT_CONSOLE_EXE godot.exe

if "%GODOT_GUI_EXE%"=="" if not "%GODOT_CONSOLE_EXE%"=="" set "GODOT_GUI_EXE=%GODOT_CONSOLE_EXE%"
if "%GODOT_CONSOLE_EXE%"=="" if not "%GODOT_GUI_EXE%"=="" set "GODOT_CONSOLE_EXE=%GODOT_GUI_EXE%"

if "%GODOT_GUI_EXE%"=="" (
    echo Godot was not found on this machine.
    echo Install Godot 4.6.2 with winget, or set GODOT_GUI_EXE/GODOT_CONSOLE_EXE before running this launcher.
    exit /b 1
)

exit /b 0

:find_where
if defined %~1 exit /b 0
for /f "delims=" %%P in ('where %~2 2^>nul') do (
    if not defined %~1 set "%~1=%%P"
)
exit /b 0
