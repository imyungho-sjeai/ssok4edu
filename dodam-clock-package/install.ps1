try {
$ErrorActionPreference = 'Stop'
Write-Host '[1/4] Checking display account...'
$user = $env:DODAM_INSTALL_USER
if ([string]::IsNullOrWhiteSpace($user)) { $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name }
if ([string]::IsNullOrWhiteSpace($user)) { throw 'Log on to the display account before installing so the start task is assigned to that interactive session.' }
Write-Host '[2/4] Checking files in the current package folder...'
$dest = $PSScriptRoot
$requiredFiles = @('DodamClock.exe','dodam-clock.html','run-display.ps1','run-shutdown.ps1','holidays.txt','school-crest.jpg','school-campus-sign-fixed.png','fonts\Gaegu-Bold.ttf')
function Assert-DodamPayload {
    foreach ($name in $requiredFiles) {
        $target = Join-Path $dest $name
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Installed file missing: $target" }
    }
}
Assert-DodamPayload
Write-Host "Verified installation directory: $dest"
Write-Host '[3/4] Configuring power settings...'
# Keep the plugged-in display awake during opening hours, and allow scheduled wake timers.
& "$env:WINDIR\System32\powercfg.exe" /change standby-timeout-ac 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /change monitor-timeout-ac 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /change hibernate-timeout-ac 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 | Out-Null
& "$env:WINDIR\System32\powercfg.exe" /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP RTCWAKE 1 | Out-Null
# Disable the sign-in prompt after the scheduled wake while plugged in.
& "$env:WINDIR\System32\powercfg.exe" /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not disable sign-in after wake while plugged in.' }
& "$env:WINDIR\System32\powercfg.exe" /SETACTIVE SCHEME_CURRENT | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not activate the updated power scheme.' }
Write-Host '[4/4] Registering scheduled tasks...'
$launchAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\run-display.ps1`""
$shutdownAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\run-shutdown.ps1`""
$days = @('Monday','Tuesday','Wednesday','Thursday','Friday')
$launchTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $days -At '8:30AM'
$shutdownTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $days -At '4:30PM'
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 3)
Register-ScheduledTask -TaskName 'DodamClock-Start' -Description '평일 오전 8시 30분 도담중학교 시계·날씨 현황판 실행' -Action $launchAction -Trigger $launchTrigger -Principal $principal -Settings $settings -Force | Out-Null
$systemPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'DodamClock-Shutdown' -Description '평일 오후 4시 30분 디스플레이 PC 절전' -Action $shutdownAction -Trigger $shutdownTrigger -Principal $systemPrincipal -Settings $settings -Force | Out-Null
Assert-DodamPayload
foreach ($taskName in @('DodamClock-Start','DodamClock-Shutdown')) { Get-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null }
$desktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $desktop '도담 현황판.lnk'))
$shortcut.TargetPath = Join-Path $dest 'DodamClock.exe'
$shortcut.WorkingDirectory = $dest
$shortcut.IconLocation = (Join-Path $dest 'DodamClock.exe') + ',0'
$shortcut.Save()
Write-Host "설치 완료: $dest" -ForegroundColor Green
Write-Host '평일 16:30 절전, 다음 평일 08:30 예약 깨우기/현황판 실행으로 설정했습니다.' -ForegroundColor Green
Write-Host '전원 연결 중 절전 해제 시 다시 로그인 요구를 해제했습니다.' -ForegroundColor Green
Start-Sleep -Seconds 4

} catch {
    Write-Host ('INSTALL FAILED: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
