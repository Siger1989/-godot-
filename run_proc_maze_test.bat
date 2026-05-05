@echo off
setlocal

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "SCENE=res://scenes/tests/Test_ProcMazeMap.tscn"
set "GODOT_EXE=C:\Users\sigeryang\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"
set "LOG_DIR=%PROJECT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\run_proc_maze_test.log"

if not exist "%PROJECT_DIR%\project.godot" (
    echo project.godot was not found in:
    echo %PROJECT_DIR%
    pause
    exit /b 1
)

if not exist "%GODOT_EXE%" (
    echo Godot 4.6.2 was not found at:
    echo %GODOT_EXE%
    pause
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo Running procedural maze test scene.
echo Project: %PROJECT_DIR%
echo Scene: %SCENE%
echo Log: %LOG_FILE%
echo.
"%GODOT_EXE%" --path "%PROJECT_DIR%" --scene "%SCENE%" --log-file "%LOG_FILE%"

set "EXIT_CODE=%ERRORLEVEL%"
echo.
echo Godot exited with code %EXIT_CODE%.
echo Log: %LOG_FILE%
echo.
if not "%EXIT_CODE%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path -LiteralPath '%LOG_FILE%') { Get-Content -LiteralPath '%LOG_FILE%' -Tail 80 }"
)
pause
endlocal & exit /b %EXIT_CODE%
