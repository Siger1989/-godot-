@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
    echo Python was not found. Please install Python or add it to PATH.
    pause
    exit /b 1
)

echo Starting Backrooms texture tool...
echo Browser URL: http://127.0.0.1:8765
echo Close this window when you are done.
python codex_tools\texture_tool\texture_tool_server.py

endlocal
