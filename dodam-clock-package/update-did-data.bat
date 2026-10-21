@echo off
setlocal
cd /d "%~dp0"
if exist "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" (
  "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" "%~dp0update-did-data.py"
) else (
  py -3 "%~dp0update-did-data.py"
)
echo.
echo Copy the updated dodam-clock-did.html to the DID.
echo For web hosting, upload dodam-weather.json and dodam-weather-feed.js too.
pause
