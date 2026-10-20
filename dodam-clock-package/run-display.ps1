$ErrorActionPreference = 'SilentlyContinue'
$root = $PSScriptRoot
$now = Get-Date
function Suspend-DisplayPc {
  Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class DodamWakeGuard {
  [DllImport("powrprof.dll", SetLastError = true)]
  public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
}
'@
  [void][DodamWakeGuard]::SetSuspendState($false, $false, $false)
}
$isNonWorkday = $now.DayOfWeek -eq 'Saturday' -or $now.DayOfWeek -eq 'Sunday'
$today = $now.ToString('yyyy-MM-dd')
$holidayFile = Join-Path $root 'holidays.txt'
$isHoliday = $false
if (Test-Path -LiteralPath $holidayFile) {
  $isHoliday = [bool](Get-Content -LiteralPath $holidayFile | ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ -eq $today })
}
if ($isNonWorkday -or $isHoliday) { Suspend-DisplayPc; exit 0 }
$launcher = Join-Path $root 'DodamClock.exe'
if (Test-Path -LiteralPath $launcher) {
  Start-Process -FilePath $launcher -WorkingDirectory $root
  exit 0
}
$edgePaths = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
)
$edge = $edgePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $edge) { $edge = (Get-Command msedge.exe -ErrorAction SilentlyContinue).Source }
if (-not $edge) { exit 2 }
$page = (Resolve-Path (Join-Path $root 'dodam-clock.html')).Path
$uri = ([Uri]$page).AbsoluteUri
Start-Process -FilePath $edge -ArgumentList @('--kiosk', $uri, '--edge-kiosk-type=fullscreen', '--no-first-run', '--disable-features=msEdgeSidebarV2') -WindowStyle Maximized

