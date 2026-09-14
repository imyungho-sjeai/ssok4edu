@echo off
chcp 949 >nul
setlocal EnableExtensions
title SSOK4에듀파인 업무도우미 설치 및 실행

rem ============================================================
rem SSOK4에듀파인통합 설치 / 실행 프로그램
rem
rem [동작 규칙]
rem 1. 이 BAT 파일을 C:\ssok 밖에서 실행하면
rem    GitHub에서 배포 파일 전체를 다시 다운로드합니다.
rem
rem 2. 이 BAT 파일을 C:\ssok 안에서 실행하면
rem    다운로드하지 않고 기존 SSOK를 바로 실행합니다.
rem
rem 3. C:\ssok 안에서 실행했더라도 핵심 파일이 없으면
rem    복구를 위해 전체 파일을 다시 다운로드합니다.
rem
rem 4. 바탕화면의 SSOK 바로가기는 ssok.ahk를 직접 실행하므로
rem    평상시에는 이 BAT를 거치지 않고 다운로드도 하지 않습니다.
rem ============================================================

set "INSTALL=C:\ssok"
set "AHK=C:\ssok\AutoHotkeyU64.exe"
set "MAIN=C:\ssok\ssok.ahk"
set "BASE=https://raw.githubusercontent.com/imyungho-sjeai/ssok4edu/main"
set "FROM_SSOK=0"

rem ------------------------------------------------------------
rem 현재 BAT 파일이 C:\ssok 폴더 안에서 실행되었는지 확인
rem ------------------------------------------------------------
if /I "%~dp0"=="C:\ssok\" set "FROM_SSOK=1"

rem ------------------------------------------------------------
rem C:\ssok 안에서 실행한 경우
rem 핵심 파일이 모두 있으면 인터넷 접속 없이 바로 실행
rem ------------------------------------------------------------
if "%FROM_SSOK%"=="0" goto INSTALL_MODE
if not exist "%AHK%" goto INSTALL_MODE
if not exist "%MAIN%" goto INSTALL_MODE
goto LAUNCH

:INSTALL_MODE
echo.
echo ============================================================
echo        SSOK4EDU 설치 / 업데이트
echo ============================================================
echo.
echo GitHub에서 최신 배포 파일을 모두 다시 다운로드합니다.
echo 같은 이름의 기존 파일이 있어도 새 파일로 덮어씁니다.
echo.

rem ------------------------------------------------------------
rem 관리자 권한 확인
rem ------------------------------------------------------------
net session >nul 2>&1
if "%errorlevel%"=="0" goto ADMIN_OK

set "SSOK_ELEVATE_BAT=%~f0"
echo [+] 설치를 위해 관리자 권한을 요청합니다...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:SSOK_ELEVATE_BAT -Verb RunAs"
endlocal
exit /b

:ADMIN_OK
rem ------------------------------------------------------------
rem C:\ssok 폴더 생성
rem ------------------------------------------------------------
if exist "%INSTALL%" goto HAVE_INSTALL_DIR
echo [+] C:\ssok 폴더를 생성합니다...
mkdir "%INSTALL%"
if not exist "%INSTALL%" goto FOLDER_FAIL

:HAVE_INSTALL_DIR
rem ------------------------------------------------------------
rem 임시 폴더 생성
rem 먼저 모든 파일을 임시 폴더에 받은 후 성공하면 적용합니다.
rem ------------------------------------------------------------
set "TMPDIR=%TEMP%\SSOK4EDU_%RANDOM%_%RANDOM%"
if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%"
mkdir "%TMPDIR%"
if not exist "%TMPDIR%" goto FOLDER_FAIL

echo.
echo [+] GitHub에서 최신 파일을 다운로드합니다...
echo.

call :DOWNLOAD AutoHotkeyU64.exe
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok.ahk
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok.ico
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_ai_report.ahk
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_ai_report1_template.hwtx
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_ai_report2_template.hwtx
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_capture.ahk
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_doc.ahk
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_index1.tsv
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_index2.tsv
if errorlevel 1 goto DOWNLOAD_FAIL
call :DOWNLOAD ssok_travel.ahk
if errorlevel 1 goto DOWNLOAD_FAIL

echo.
echo [+] 모든 파일 다운로드가 완료되었습니다.
echo [+] 새 파일을 C:\ssok에 적용합니다...

rem ------------------------------------------------------------
rem C:\ssok의 AutoHotkeyU64.exe로 실행된 SSOK만 종료
rem 다른 AutoHotkey 프로그램은 종료하지 않습니다.
rem ------------------------------------------------------------
set "SSOK_AHK_PATH=%AHK%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process -Filter \"Name='AutoHotkeyU64.exe'\" -ErrorAction SilentlyContinue | Where-Object { $_.ExecutablePath -and ($_.ExecutablePath -ieq $env:SSOK_AHK_PATH) } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

timeout /t 1 /nobreak >nul 2>&1

rem ------------------------------------------------------------
rem 다운로드한 파일을 C:\ssok에 덮어쓰기
rem ------------------------------------------------------------
copy /Y "%TMPDIR%\AutoHotkeyU64.exe" "%INSTALL%\AutoHotkeyU64.exe" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok.ahk" "%INSTALL%\ssok.ahk" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok.ico" "%INSTALL%\ssok.ico" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_ai_report.ahk" "%INSTALL%\ssok_ai_report.ahk" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_ai_report1_template.hwtx" "%INSTALL%\ssok_ai_report1_template.hwtx" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_ai_report2_template.hwtx" "%INSTALL%\ssok_ai_report2_template.hwtx" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_capture.ahk" "%INSTALL%\ssok_capture.ahk" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_doc.ahk" "%INSTALL%\ssok_doc.ahk" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_index1.tsv" "%INSTALL%\ssok_index1.tsv" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_index2.tsv" "%INSTALL%\ssok_index2.tsv" >nul
if errorlevel 1 goto APPLY_FAIL
copy /Y "%TMPDIR%\ssok_travel.ahk" "%INSTALL%\ssok_travel.ahk" >nul
if errorlevel 1 goto APPLY_FAIL

rem 임시 다운로드 폴더 삭제
rmdir /s /q "%TMPDIR%" >nul 2>&1

rem ------------------------------------------------------------
rem 웹에서 받은 BAT를 C:\ssok에도 복사
rem C:\ssok 안에서 실행한 경우에는 다시 복사하지 않습니다.
rem ------------------------------------------------------------
if "%FROM_SSOK%"=="1" goto SKIP_SELF_COPY
copy /Y "%~f0" "%INSTALL%\%~nx0" >nul 2>&1

:SKIP_SELF_COPY
rem ------------------------------------------------------------
rem Windows 시작프로그램 등록
rem BAT가 아니라 ssok.ahk를 직접 실행하므로 부팅 때 다운로드하지 않음
rem ------------------------------------------------------------
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SSOK4EDU" /t REG_SZ /d "\"%AHK%\" \"%MAIN%\"" /f >nul

echo.
echo ============================================================
echo        SSOK4EDU 설치 / 업데이트 완료
echo ============================================================
echo.
goto LAUNCH

rem ============================================================
rem 파일 다운로드 함수
rem ============================================================
:DOWNLOAD
set "DLFILE=%~1"
echo     다운로드 중 : %DLFILE%
set "SSOK_DL_URL=%BASE%/%DLFILE%"
set "SSOK_DL_OUT=%TMPDIR%\%DLFILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $wc=New-Object Net.WebClient; $wc.DownloadFile($env:SSOK_DL_URL,$env:SSOK_DL_OUT); if ((Get-Item $env:SSOK_DL_OUT).Length -le 0) { exit 2 }; exit 0 } catch { exit 1 }"
if errorlevel 1 exit /b 1
exit /b 0

rem ============================================================
rem SSOK 실행
rem ============================================================
:LAUNCH
if not exist "%AHK%" goto CORE_FAIL
if not exist "%MAIN%" goto CORE_FAIL
cd /d "%INSTALL%"
echo [+] SSOK4EDU를 실행합니다...
start "" "%AHK%" "%MAIN%"
endlocal
exit /b 0

rem ============================================================
rem 다운로드 실패
rem 임시 폴더에만 받았으므로 기존 C:\ssok 파일은 유지됩니다.
rem ============================================================
:DOWNLOAD_FAIL
echo.
echo ============================================================
echo [오류] 파일 다운로드에 실패했습니다.
echo 기존 C:\ssok 파일은 변경하지 않았습니다.
echo 인터넷 연결 또는 GitHub 접속 상태를 확인해 주세요.
echo ============================================================
if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%" >nul 2>&1
pause
endlocal
exit /b 1

rem ============================================================
rem 파일 적용 실패
rem ============================================================
:APPLY_FAIL
echo.
echo ============================================================
echo [오류] 새 파일을 C:\ssok에 적용하지 못했습니다.
echo 실행 중인 SSOK 또는 보안 프로그램을 확인한 후 다시 실행해 주세요.
echo ============================================================
if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%" >nul 2>&1
pause
endlocal
exit /b 1

rem ============================================================
rem 폴더 생성 실패
rem ============================================================
:FOLDER_FAIL
echo.
echo ============================================================
echo [오류] 설치에 필요한 폴더를 만들 수 없습니다.
echo 관리자 권한이나 보안 설정을 확인해 주세요.
echo ============================================================
pause
endlocal
exit /b 1

rem ============================================================
rem 핵심 실행 파일 누락
rem ============================================================
:CORE_FAIL
echo.
echo ============================================================
echo [오류] AutoHotkeyU64.exe 또는 ssok.ahk 파일이 없습니다.
echo 웹페이지에서 설치 BAT를 다시 받아 실행해 주세요.
echo ============================================================
pause
endlocal
exit /b 1
