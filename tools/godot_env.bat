@echo off
set "PROJECT_DIR=%~dp0.."

if not defined GODOT_CONSOLE_EXE (
  call :find_console_exe
)

if not defined GODOT_EDITOR_EXE (
  call :find_editor_exe
)

if not exist "%GODOT_CONSOLE_EXE%" (
  echo Godot console executable not found:
  echo %GODOT_CONSOLE_EXE%
  echo.
  echo Set GODOT_CONSOLE_EXE to your Godot console executable path.
  exit /b 1
)

exit /b 0

:find_console_exe
for %%G in (
  "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.3-stable_win64_console.exe"
  "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"
  "%USERPROFILE%\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe"
  "%USERPROFILE%\Downloads\Godot_v4.3-stable_win64_console.exe"
  "C:\Godot\Godot_v4.3-stable_win64_console.exe"
) do (
  if exist "%%~G" (
    set "GODOT_CONSOLE_EXE=%%~G"
    exit /b 0
  )
)
for /f "delims=" %%G in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64_console.exe" 2^>nul') do (
  set "GODOT_CONSOLE_EXE=%%G"
  exit /b 0
)
exit /b 0

:find_editor_exe
for %%G in (
  "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.3-stable_win64.exe"
  "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"
  "%USERPROFILE%\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64.exe"
  "%USERPROFILE%\Downloads\Godot_v4.3-stable_win64.exe"
  "C:\Godot\Godot_v4.3-stable_win64.exe"
) do (
  if exist "%%~G" (
    set "GODOT_EDITOR_EXE=%%~G"
    exit /b 0
  )
)
for /f "delims=" %%G in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64.exe" 2^>nul') do (
  set "GODOT_EDITOR_EXE=%%G"
  exit /b 0
)
set "CANDIDATE_EDITOR=%GODOT_CONSOLE_EXE:_console.exe=.exe%"
if exist "%CANDIDATE_EDITOR%" set "GODOT_EDITOR_EXE=%CANDIDATE_EDITOR%"
exit /b 0
