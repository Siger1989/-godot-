@echo off
setlocal

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "SCENE=res://scenes/mvp/FourRoomMVP.tscn"
set "SCENE_FILE=%PROJECT_DIR%\scenes\mvp\FourRoomMVP.tscn"
set "GODOT_EXE=C:\Users\sigeryang\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"
set "LOG_DIR=%PROJECT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\open_mvp_monster_room.log"

if not exist "%PROJECT_DIR%\project.godot" (
    echo project.godot was not found in:
    echo %PROJECT_DIR%
    pause
    exit /b 1
)

if not exist "%GODOT_EXE%" (
    echo Godot 4.6.2 GUI executable was not found at:
    echo %GODOT_EXE%
    pause
    exit /b 1
)

if not exist "%SCENE_FILE%" (
    echo MVP monster room scene was not found:
    echo %SCENE_FILE%
    pause
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo Opening FourRoomMVP editable monster room scene.
echo Project: %PROJECT_DIR%
echo Scene: %SCENE%
echo Log: %LOG_FILE%
echo.

start "" "%GODOT_EXE%" --editor --path "%PROJECT_DIR%" --scene "%SCENE%" --log-file "%LOG_FILE%"

endlocal & exit /b 0
