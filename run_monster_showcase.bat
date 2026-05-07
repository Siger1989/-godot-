@echo off
setlocal

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "SCENE=res://scenes/tests/Test_MonsterShowcase.tscn"
set "SCENE_FILE=%PROJECT_DIR%\scenes\tests\Test_MonsterShowcase.tscn"
set "LOG_DIR=%PROJECT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\run_monster_showcase.log"

call "%PROJECT_DIR%\_godot_env.bat"
if errorlevel 1 (
    pause
    exit /b 1
)

if not exist "%PROJECT_DIR%\project.godot" (
    echo project.godot was not found in:
    echo %PROJECT_DIR%
    pause
    exit /b 1
)

if not exist "%GODOT_CONSOLE_EXE%" (
    echo Godot console executable was not found at:
    echo %GODOT_CONSOLE_EXE%
    pause
    exit /b 1
)

if not exist "%SCENE_FILE%" (
    echo Monster showcase scene was not found:
    echo %SCENE_FILE%
    pause
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo Running monster showcase and global size/orientation editor.
echo Project: %PROJECT_DIR%
echo Scene: %SCENE%
echo Log: %LOG_FILE%
echo.
"%GODOT_CONSOLE_EXE%" --path "%PROJECT_DIR%" --scene "%SCENE%" --log-file "%LOG_FILE%"

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Godot exited with code %EXIT_CODE%.
    echo Log: %LOG_FILE%
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path -LiteralPath '%LOG_FILE%') { Get-Content -LiteralPath '%LOG_FILE%' -Tail 80 }"
    pause
)

endlocal & exit /b %EXIT_CODE%
