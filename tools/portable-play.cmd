@echo off
setlocal
cd /d "%~dp0"
if not exist "userdata" mkdir "userdata"
set "APPDATA=%~dp0userdata"
set "LOCALAPPDATA=%~dp0userdata"
"%~dp0TaiwanFighter.exe" --main-pack "%~dp0TaiwanFighter.pck" --rendering-method gl_compatibility --rendering-driver opengl3
endlocal
