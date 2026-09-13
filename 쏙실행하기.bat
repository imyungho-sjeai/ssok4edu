@echo off
chcp 949 >nul
setlocal EnableExtensions
title SSOK (에듀파인 도우미 쏙) 설치 및 실행

set "SourceDir=%~dp0"
set "BatName=%~nx0"
set "CleanTarget=%SourceDir:~0,-1%"

:: 1. 진짜 압축 파일(ZIP 임시 폴더) 내부 실행 여부 검사
set "IsZipRun=0"
echo "%SourceDir%" | findstr /I "\\AppData\\Local\\Temp\\ Temp1_ \\Temp\\" >nul
if not errorlevel 1 set "IsZipRun=1"

if "%IsZipRun%"=="1" goto ZipErrorBlock
goto CheckInstallDir

:ZipErrorBlock
cls
echo =======================================================================
echo                   [ SSOK (에듀파인 도우미 쏙) 설치 안내 ]
echo.
echo   현재 압축 파일(ZIP) 안에서 바로 실행되었습니다.
echo   압축을 풀지 않으면 프로그램을 설치하거나 실행할 수 없습니다.
echo.
echo   [해결 방법]
echo   1. 다운로드받은 압축 파일(.zip)을 마우스 오른쪽 버튼으로 클릭합니다.
echo   2. [압축 풀기](또는 '여기에 풀기')를 선택하여 압축을 완전히 풉니다.
echo   3. 압축이 풀린 새 폴더 안에 있는 [쏙실행하기.bat]을 다시 실행해 주세요!
echo =======================================================================
echo.
mshta "javascript:alert('압축 파일(ZIP) 안에서는 바로 실행할 수 없습니다.\n\n[해결 방법]\n1. 다운로드받은 압축 파일(.zip) 마우스 우클릭\n2. [압축 풀기]를 선택하여 압축 해제\n3. 압축 풀린 폴더의 [쏙실행하기.bat] 다시 실행');close();" 2>nul
pause
exit /b 1

:CheckInstallDir
:: 2. 설치 대상 폴더 결정 (기본 C:\SSOK -> 권한 없으면 %LOCALAPPDATA%\SSOK 로 Fallback)
set "InstallDir=C:\SSOK"
if not exist "%InstallDir%" mkdir "%InstallDir%" 2>nul

:: C:\SSOK 쓰기 권한 테스트 (실제 임시 파일 생성 및 존재 여부 검사)
echo test > "%InstallDir%\_permtest.tmp" 2>nul
if exist "%InstallDir%\_permtest.tmp" (
  del /f /q "%InstallDir%\_permtest.tmp" >nul 2>&1
  goto SetPaths
)

echo [안내] C:\ 드라이브 권한 제한으로 인해 사용자 로컬 폴더로 설치합니다.
set "InstallDir=%LOCALAPPDATA%\SSOK"
if not exist "%InstallDir%" mkdir "%InstallDir%" 2>nul

:SetPaths
set "AhkExe=%InstallDir%\AutoHotkeyU64.exe"
set "MainScript=%InstallDir%\ssok.ahk"

:: 3. '여기에 풀기' 시 개인 파일 보호 검사 (바탕화면, 다운로드 루트, 개발 폴더 등)
set "IsUnsafeSource=0"
if /I "%SourceDir%"=="%USERPROFILE%\Desktop\" set "IsUnsafeSource=1"
if /I "%SourceDir%"=="%USERPROFILE%\OneDrive\바탕 화면\" set "IsUnsafeSource=1"
if /I "%SourceDir%"=="%USERPROFILE%\OneDrive\Desktop\" set "IsUnsafeSource=1"
if /I "%SourceDir%"=="%USERPROFILE%\Downloads\" set "IsUnsafeSource=1"
if /I "%SourceDir%"=="%USERPROFILE%\Documents\" set "IsUnsafeSource=1"
if /I "%SourceDir%"=="%SystemDrive%\" set "IsUnsafeSource=1"

echo "%SourceDir%" | findstr /I "antigravity autohotky" >nul
if not errorlevel 1 set "IsUnsafeSource=1"

:: 4. 프로그램 파일 설치 (기본: C:\SSOK로 깔끔하게 전체 이동 / 위험 위치: 안전 복사)
if /I "%SourceDir%"=="%InstallDir%\" goto LaunchSSOK

echo.
echo =======================================================================
echo   SSOK (에듀파인 도우미 쏙) 프로그램 파일을 설치 중입니다...
echo   - 설치 경로: %InstallDir%
echo =======================================================================
echo.

if "%IsUnsafeSource%"=="1" (
  :: [예외: 위험 위치] 개인 파일 보호를 위해 SSOK 관련 파일만 안전하게 복사
  robocopy "%SourceDir%." "%InstallDir%" AutoHotkeyU64.exe ssok.ahk ssok.ico ssok.ini ssok_index1.tsv ssok_index2.tsv *.hwtx *.tsv *.ahk *.xlsm /IS /IT /R:2 /W:1 /NP >nul
  copy /y "%SourceDir%%BatName%" "%InstallDir%\" >nul 2>&1
) else (
  :: [기본: 안전한 전용 폴더] C:\SSOK 로 완전 이동(MOVE) 및 다운로드 폴더 자동 삭제 정리
  robocopy "%SourceDir%." "%InstallDir%" /E /MOVE /IS /IT /XF "%BatName%" /COPY:DAT /DCOPY:T /R:2 /W:1 /NP >nul
  copy /y "%SourceDir%%BatName%" "%InstallDir%\" >nul 2>&1
  start "" /b cmd /c "cd /d %SystemRoot% & ping 127.0.0.1 -n 4 >nul & rd /s /q \"%CleanTarget%\""
)

:LaunchSSOK
:: 작업 디렉토리를 설치 폴더로 변경
cd /d "%InstallDir%"

if not exist "%AhkExe%" (
  echo.
  echo [오류] AutoHotkeyU64.exe 파일이 설치 폴더에 없습니다.
  echo 설치 경로: %InstallDir%
  pause
  exit /b 1
)

if not exist "%MainScript%" (
  echo.
  echo [오류] ssok.ahk 파일이 설치 폴더에 없습니다.
  echo 설치 경로: %InstallDir%
  pause
  exit /b 1
)

:: 5. SSOK 실행 및 사용자 친절 피드백
cls
echo =======================================================================
echo                 [ SSOK (에듀파인 도우미 쏙) 실행 ]
echo.
echo   SSOK가 성공적으로 실행되었습니다!
echo.
echo   - 화면 오른쪽 아래(시계 옆) [작업표시줄 트레이]를 확인해 주세요.
echo   - 주요 단축키:
echo     * [Win + F2] : 쏙 메인 메뉴 / 원키 정리
echo     * [Win + F1] : 빠른 입력 도우미
echo.
echo   (이 창은 3초 후 자동으로 닫힙니다...)
echo =======================================================================

start "" "%AhkExe%" "%MainScript%"

timeout /t 3 >nul 2>&1
if errorlevel 1 ping 127.0.0.1 -n 4 >nul
endlocal
