$now = Get-Date
if ($now.DayOfWeek -eq 'Saturday' -or $now.DayOfWeek -eq 'Sunday') { exit 0 }
$today = $now.ToString('yyyy-MM-dd')
$holidayFile = Join-Path $PSScriptRoot 'holidays.txt'
if (Test-Path -LiteralPath $holidayFile) {
  $isHoliday = Get-Content -LiteralPath $holidayFile | ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ -eq $today }
  if ($isHoliday) { exit 0 }
}
# Stop the launcher and its display-maintenance timer before sleeping.
Get-Process -Name DodamClock -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
# Close the dedicated kiosk browser so the morning task starts one clean window.
Get-Process -Name msedge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
# Suspend to RAM (do not shut down or log out). The 08:30 task has WakeToRun enabled.
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class DodamPower {
  [DllImport("powrprof.dll", SetLastError = true)]
  public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
}
'@
[void][DodamPower]::SetSuspendState($false, $false, $false)
