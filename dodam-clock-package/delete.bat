@echo off
setlocal
powershell.exe -NoProfile -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent();$p=New-Object Security.Principal.WindowsPrincipal($id);if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 1}"
if errorlevel 1 (
  set "DODAM_REMOVE_BAT=%~f0"
  powershell.exe -NoProfile -Command "Start-Process -FilePath $env:ComSpec -ArgumentList ('/d /c ""' + $env:DODAM_REMOVE_BAT + '""') -Verb RunAs"
  exit /b
)
schtasks /Delete /TN "DodamClock-Start" /F
schtasks /Delete /TN "DodamClock-Shutdown" /F
echo DodamClock scheduled tasks have been removed. Package files have been kept.
pause
