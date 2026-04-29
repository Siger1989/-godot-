@echo off
call "%~dp0tools\godot_env.bat"
if errorlevel 1 (
  pause
  exit /b 1
)

set "FAILED=0"

call :run_script res://scripts/tools/ValidateMainScene.gd
call :run_script res://scripts/tools/ValidatePlayerModel.gd
call :run_script res://scripts/tools/ValidateMainClosedMemory.gd
call :run_script res://scripts/tools/ValidateFogTest.gd
call :run_script res://scripts/tools/ValidateRoomPrototype.gd
call :run_script res://scripts/tools/ValidateVisibilityBlendTest.gd
call :run_script res://scripts/tools/ValidateVisibilityClosedMemory.gd

if "%FAILED%"=="0" (
  echo.
  echo All validation scripts passed.
) else (
  echo.
  echo One or more validation scripts failed.
)

if not defined NO_PAUSE pause
exit /b %FAILED%

:run_script
echo.
echo === %~1 ===
"%GODOT_CONSOLE_EXE%" --headless --path "%PROJECT_DIR%" --rendering-driver opengl3 --script %~1
if errorlevel 1 set "FAILED=1"
exit /b 0
