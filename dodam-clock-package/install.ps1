$ErrorActionPreference = 'Stop'
$user = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
if ([string]::IsNullOrWhiteSpace($user)) { throw 'Log on to the display account before installing so the start task is assigned to that interactive session.' }
$dest = Join-Path $env:ProgramData 'DodamClock'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Name -notin @('install.ps1','install.bat','delete.bat') } | Copy-Item -Destination $dest -Force
# Keep the plugged-in display awake during opening hours, and allow scheduled wake timers.
& "$env:WINDIR\System32\powercfg.exe" /change standby-timeout-ac 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /change monitor-timeout-ac 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /change hibernate-timeout-ac 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP RTCWAKE 1 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /SETACTIVE SCHEME_CURRENT | Out-Null
$launchAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\run-display.ps1`""
$shutdownAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\run-shutdown.ps1`""
$days = @('Monday','Tuesday','Wednesday','Thursday','Friday')
$launchTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $days -At '8:00AM'
$shutdownTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $days -At '4:30PM'
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 3)
Register-ScheduledTask -TaskName 'DodamClock-Start' -Description '평일 오전 8시 도담중학교 시계·날씨 현황판 실행' -Action $launchAction -Trigger $launchTrigger -Principal $principal -Settings $settings -Force | Out-Null
$systemPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'DodamClock-Shutdown' -Description '평일 오후 4시 30분 디스플레이 PC 절전' -Action $shutdownAction -Trigger $shutdownTrigger -Principal $systemPrincipal -Settings $settings -Force | Out-Null
Write-Host "설치 완료: $dest" -ForegroundColor Green
Write-Host '평일 16:30 절전, 다음 평일 08:00 예약 깨우기/현황판 실행으로 설정했습니다.' -ForegroundColor Green
Write-Host '안내문에서 절전 해제 시 로그인 및 자동 로그인을 확인하세요.' -ForegroundColor Yellow
Start-Sleep -Seconds 4
