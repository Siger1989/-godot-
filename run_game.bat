@echo off
call "%~dp0tools\godot_env.bat"
if errorlevel 1 (
  pause
  exit /b 1
)
"%GODOT_CONSOLE_EXE%" --path "%PROJECT_DIR%" --rendering-driver opengl3
if errorlevel 1 pause
