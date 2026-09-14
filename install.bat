@echo off
chcp 65001 > nul
title SSOK4EDU 자동 설치 프로그램

echo ========================================================
echo        SSOK for K-에듀파인 프로그램 설치 시작
echo ========================================================
echo.

:: 1. C:\ssok 폴더 생성 (없을 경우)
if not exist "C:\ssok" (
    echo [+] C:\ssok 폴더를 생성합니다...
    mkdir "C:\ssok"
)

:: 2. GitHub Raw URL 기본 경로
set "BASE_URL=https://raw.githubusercontent.com/imyungho-sjeai/ssok4edu/main"

echo [+] C:\ssok 경로로 필요 파일 다운로드 중...

:: PowerShell을 사용하여 파일 다운로드
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/AutoHotkeyU64.exe', 'C:\ssok\AutoHotkeyU64.exe')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok.ahk', 'C:\ssok\ssok.ahk')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok.ico', 'C:\ssok\ssok.ico')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_ai_report.ahk', 'C:\ssok\ssok_ai_report.ahk')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_ai_report1_template.hwtx', 'C:\ssok\ssok_ai_report1_template.hwtx')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_ai_report2_template.hwtx', 'C:\ssok\ssok_ai_report2_template.hwtx')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_capture.ahk', 'C:\ssok\ssok_capture.ahk')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_doc.ahk', 'C:\ssok\ssok_doc.ahk')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_index1.tsv', 'C:\ssok\ssok_index1.tsv')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_index2.tsv', 'C:\ssok\ssok_index2.tsv')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%BASE_URL%/ssok_travel.ahk', 'C:\ssok\ssok_travel.ahk')"

echo.
echo [+] 시작프로그램 등록 중 (부팅 시 자동 실행)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SSOK4EDU" /t REG_SZ /d "\"C:\ssok\AutoHotkeyU64.exe\" \"C:\ssok\ssok.ahk\"" /f > nul

echo.
echo ========================================================
echo        설치가 완료되었습니다! SSOK를 실행합니다.
echo ========================================================
echo.

:: 3. 설치 직후 바로 실행
start "" "C:\ssok\AutoHotkeyU64.exe" "C:\ssok\ssok.ahk"

timeout /t 3 > nul
exit