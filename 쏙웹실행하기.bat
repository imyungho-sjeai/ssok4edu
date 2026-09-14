@echo off
setlocal EnableExtensions
title SSOK4EDU Installer

rem ============================================================
rem SSOK4EDU GitHub-safe installer / launcher
rem Plain BAT. Short command lines only.
rem ============================================================

set "INSTALL=C:\ssok"
set "AHK=C:\ssok\AutoHotkeyU64.exe"
set "MAIN=C:\ssok\ssok.ahk"
set "BASE=https://raw.githubusercontent.com/imyungho-sjeai/ssok4edu/main"

rem If this BAT is already inside C:\ssok, launch without download.
if /I "%~dp0"=="C:\ssok\" goto LOCAL_RUN
goto UPDATE

:LOCAL_RUN
if not exist "%AHK%" goto UPDATE
if not exist "%MAIN%" goto UPDATE
start "" "%AHK%" "%MAIN%"
exit /b 0

:UPDATE
echo.
echo ============================================================
echo SSOK4EDU INSTALL / UPDATE
echo ============================================================
echo.
echo Downloading all current files from GitHub.
echo Existing files will be overwritten.
echo.

rem Request administrator rights only for install/update.
net session >nul 2>&1
if "%errorlevel%"=="0" goto ADMIN_OK
echo Requesting administrator permission...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ADMIN_OK
if not exist "%INSTALL%" mkdir "%INSTALL%"
if not exist "%INSTALL%" goto FAIL_FOLDER

set "TMP=%TEMP%\SSOK4EDU_UPDATE_%RANDOM%_%RANDOM%"
if exist "%TMP%" rmdir /s /q "%TMP%" >nul 2>&1
mkdir "%TMP%"
if not exist "%TMP%" goto FAIL_FOLDER

call :GET AutoHotkeyU64.exe
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok.ahk
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok.ico
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_ai_report.ahk
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_ai_report1_template.hwtx
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_ai_report2_template.hwtx
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_capture.ahk
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_doc.ahk
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_index1.tsv
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_index2.tsv
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_travel.ahk
if errorlevel 1 goto FAIL_DOWNLOAD

echo.
echo Download complete.
echo Stopping the currently running SSOK process if needed...

set "SSOK_AHK_PATH=%AHK%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'AutoHotkeyU64.exe' -and $_.ExecutablePath -ieq $env:SSOK_AHK_PATH } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

timeout /t 1 /nobreak >nul 2>&1

copy /Y "%TMP%\*" "%INSTALL%\" >nul
if errorlevel 1 goto FAIL_COPY

rmdir /s /q "%TMP%" >nul 2>&1

rem Keep a local copy of this launcher. Preserve its downloaded filename.
copy /Y "%~f0" "%INSTALL%\%~nx0" >nul 2>&1

rem Windows startup launches SSOK directly, not this updater BAT.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SSOK4EDU" /t REG_SZ /d "\"%AHK%\" \"%MAIN%\"" /f >nul

echo.
echo ============================================================
echo INSTALL / UPDATE COMPLETE
echo ============================================================
echo.
goto START_SSOK

:GET
set "FILE=%~1"
echo Downloading: %FILE%
set "DL_URL=%BASE%/%FILE%"
set "DL_OUT=%TMP%\%FILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { $w=New-Object Net.WebClient; $w.Headers['Cache-Control']='no-cache'; $w.DownloadFile($env:DL_URL,$env:DL_OUT); if ((Get-Item $env:DL_OUT).Length -le 0) { exit 2 }; exit 0 } catch { exit 1 }"
exit /b %errorlevel%

:START_SSOK
if not exist "%AHK%" goto FAIL_CORE
if not exist "%MAIN%" goto FAIL_CORE
cd /d "%INSTALL%"
start "" "%AHK%" "%MAIN%"
endlocal
exit /b 0

:FAIL_DOWNLOAD
echo.
echo ERROR: A GitHub download failed.
echo The existing C:\ssok installation was not replaced.
if exist "%TMP%" rmdir /s /q "%TMP%" >nul 2>&1
pause
endlocal
exit /b 1

:FAIL_COPY
echo.
echo ERROR: Files could not be copied to C:\ssok.
if exist "%TMP%" rmdir /s /q "%TMP%" >nul 2>&1
pause
endlocal
exit /b 1

:FAIL_FOLDER
echo.
echo ERROR: Required folder could not be created.
pause
endlocal
exit /b 1

:FAIL_CORE
echo.
echo ERROR: AutoHotkeyU64.exe or ssok.ahk is missing.
pause
endlocal
exit /b 1
