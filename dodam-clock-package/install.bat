@echo off
echo Dodam Clock installer started.
setlocal
echo [1/2] Checking administrator permission...
set "DODAM_INSTALL_USER=%USERDOMAIN%\%USERNAME%"
set "DODAM_INSTALL_BAT=%~f0"
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent());if($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 0};try{Start-Process -FilePath $env:ComSpec -ArgumentList ('/d /c ""' + $env:DODAM_INSTALL_BAT + '""') -Verb RunAs -ErrorAction Stop;exit 2}catch{Write-Host $_;exit 1}"
if errorlevel 2 exit /b
if errorlevel 1 goto failed
echo [2/2] Installing clock schedule...
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 goto failed
echo Installation completed.
pause
exit /b 0
:failed
echo Installation failed. Please send the message shown above.
pause
exit /b 1