@echo off
chcp 65001 >nul
setlocal EnableExtensions
title 쏙 설치 및 업데이트

rem ============================================================
rem SSOK4EDU GitHub-safe installer / launcher
rem Plain BAT. Short command lines only.
rem ============================================================

set "INSTALL=C:\ssok"
set "AHK=C:\ssok\AutoHotkeyU64.exe"
set "MAIN=C:\ssok\ssok.ahk"
set "SSOK_UPDATE_PID=%~1"
set "BASE=https://raw.githubusercontent.com/imyungho-sjeai/ssok4edu/main"

rem Always download from GitHub, including when launched inside C:\ssok.
goto UPDATE

:UPDATE
echo.
echo ============================================================
echo 쏙(Sejong Smart One Key) for Edu 설치
echo ============================================================
echo.
echo 깃허브(github)에서 최신 파일을 내려받습니다.
echo 기존 파일은 최신 파일로 교체됩니다.
echo.

rem Request administrator rights only for install/update.
net session >nul 2>&1
if "%errorlevel%"=="0" goto ADMIN_OK
echo 관리자 권한을 요청합니다...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -ArgumentList (' ' + $env:SSOK_UPDATE_PID) -Verb RunAs -ErrorAction Stop } catch { Write-Error $_; exit 1 }"
exit /b

:ADMIN_OK
if not exist "%INSTALL%" mkdir "%INSTALL%"
if not exist "%INSTALL%" goto FAIL_FOLDER

set "SSOK_UPDATE_TEMP=%TEMP%\SSOK4EDU_UPDATE_%RANDOM%_%RANDOM%"
mkdir "%SSOK_UPDATE_TEMP%"
if not exist "%SSOK_UPDATE_TEMP%" goto FAIL_FOLDER

echo 실행 중인 쏙을 종료합니다...

set "SSOK_AHK_PATH=%AHK%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { ($_.ExecutablePath -ieq $env:SSOK_AHK_PATH) -or (($_.ProcessId -eq $env:SSOK_UPDATE_PID) -and ($_.Name -like 'AutoHotkey*.exe' -or $_.Name -ieq 'ssok.exe')) -or ($_.ExecutablePath -ieq ($env:INSTALL + '\ssok.exe')) -or ($_.ExecutablePath -ieq ($env:INSTALL + '\ssok_budget.exe')) } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop }; exit 0 } catch { exit 1 }"
if errorlevel 1 goto FAIL_STOP

timeout /t 1 /nobreak >nul 2>&1

call :GET AutoHotkeyU64.exe
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_budget.exe
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
call :GET ssok_travel.ahk optional
if errorlevel 3 goto TRAVEL_UNAVAILABLE
if errorlevel 1 goto FAIL_DOWNLOAD
goto TRAVEL_READY
:TRAVEL_UNAVAILABLE
echo 안내: 깃허브에 여비 파일이 없어 기존 파일을 유지합니다.
:TRAVEL_READY
call :GET ssok_tool.ahk
if errorlevel 1 goto FAIL_DOWNLOAD
call :GET ssok_tool_expense.ahk
if errorlevel 1 goto FAIL_DOWNLOAD

echo.
echo 다운로드 완료. C:\ssok 폴더에 파일을 복사합니다...
copy /Y "%SSOK_UPDATE_TEMP%\*" "%INSTALL%\" >nul
if errorlevel 1 goto FAIL_COPY

rmdir /s /q "%SSOK_UPDATE_TEMP%" >nul 2>&1

rem Keep a local copy of this launcher. Preserve its downloaded filename.
echo %~n0 | findstr /B /I "SSOK4EDU_Update_" >nul
if errorlevel 1 if /I not "%~dp0"=="C:\ssok\" copy /Y "%~f0" "%INSTALL%\%~nx0" >nul 2>&1

rem Windows startup launches SSOK directly, not this updater BAT.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SSOK4EDU" /t REG_SZ /d "\"%AHK%\" \"%MAIN%\"" /f >nul

echo.
echo ============================================================
echo 설치 및 업데이트가 완료되었습니다.
echo ============================================================
echo.
goto START_SSOK

:GET
set "FILE=%~1"
set "DL_OPTIONAL=%~2"
echo 다운로드 중: %FILE%
set "DL_URL=%BASE%/%FILE%"
set "DL_OUT=%SSOK_UPDATE_TEMP%\%FILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { $w=New-Object Net.WebClient; $w.Headers['Cache-Control']='no-cache'; $w.DownloadFile($env:DL_URL,$env:DL_OUT); if ((Get-Item $env:DL_OUT).Length -le 0) { exit 2 }; exit 0 } catch { $downloadException=$_.Exception; $downloadStatus=0; while ($null -ne $downloadException) { if ($downloadException -is [Net.WebException] -and $null -ne $downloadException.Response) { $downloadStatus=[int]$downloadException.Response.StatusCode; break }; $downloadException=$downloadException.InnerException }; if ($env:DL_OPTIONAL -eq 'optional' -and $downloadStatus -eq 404) { Remove-Item -LiteralPath $env:DL_OUT -ErrorAction SilentlyContinue; exit 3 }; [Console]::WriteLine('다운로드 실패: ' + $env:FILE + ' / ' + $_.Exception.Message); exit 1 }"
exit /b %errorlevel%

:START_SSOK
if not exist "%AHK%" goto FAIL_CORE
if not exist "%MAIN%" goto FAIL_CORE
cd /d "%INSTALL%"
echo 쏙을 다시 실행합니다...
start "" "%AHK%" "%MAIN%"
endlocal
exit /b 0

:FAIL_DOWNLOAD
echo.
echo 오류: %FILE% 파일을 깃허브에서 내려받지 못했습니다.
echo C:\ssok의 기존 파일은 변경되지 않았습니다.
if exist "%SSOK_UPDATE_TEMP%" rmdir /s /q "%SSOK_UPDATE_TEMP%" >nul 2>&1
echo 창을 닫으려면 아무 키나 누르세요.
pause >nul
endlocal
exit /b 1

:FAIL_COPY
echo.
echo 오류: C:\ssok 폴더에 파일을 복사하지 못했습니다.
if exist "%SSOK_UPDATE_TEMP%" rmdir /s /q "%SSOK_UPDATE_TEMP%" >nul 2>&1
echo 창을 닫으려면 아무 키나 누르세요.
pause >nul
endlocal
exit /b 1

:FAIL_FOLDER
echo.
echo 오류: 설치 또는 임시 폴더를 만들지 못했습니다.
echo 창을 닫으려면 아무 키나 누르세요.
pause >nul
endlocal
exit /b 1

:FAIL_CORE
echo.
echo 오류: AutoHotkeyU64.exe 또는 ssok.ahk 파일이 없습니다.
echo 창을 닫으려면 아무 키나 누르세요.
pause >nul
endlocal
exit /b 1

:FAIL_STOP
echo 오류: 실행 중인 쏙을 종료하지 못했습니다. 기존 파일은 변경되지 않았습니다.
if exist "%SSOK_UPDATE_TEMP%" rmdir /s /q "%SSOK_UPDATE_TEMP%" >nul 2>&1
echo 창을 닫으려면 아무 키나 누르세요.
pause >nul
endlocal
exit /b 1
