@echo off
call "%~dp0tools\godot_env.bat"
if errorlevel 1 (
  pause
  exit /b 1
)
if not exist "%GODOT_EDITOR_EXE%" (
  echo Godot editor executable not found:
  echo %GODOT_EDITOR_EXE%
  echo.
  echo Set GODOT_EDITOR_EXE to your Godot editor executable path.
  pause
  exit /b 1
)
"%GODOT_EDITOR_EXE%" --editor --path "%PROJECT_DIR%"
