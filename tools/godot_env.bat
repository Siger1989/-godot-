@echo off
set "PROJECT_DIR=%~dp0.."

if not defined GODOT_CONSOLE_EXE (
  set "GODOT_CONSOLE_EXE=C:\Users\bodean\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe"
)

if not defined GODOT_EDITOR_EXE (
  set "GODOT_EDITOR_EXE=C:\Users\bodean\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64.exe"
)

if not exist "%GODOT_CONSOLE_EXE%" (
  echo Godot console executable not found:
  echo %GODOT_CONSOLE_EXE%
  echo.
  echo Set GODOT_CONSOLE_EXE to your Godot console executable path.
  exit /b 1
)

exit /b 0
