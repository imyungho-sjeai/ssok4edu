$ErrorActionPreference = 'Stop'
$collector = Join-Path $PSScriptRoot 'portrait-did-collector\PortraitCollector.exe'
& $collector $PSScriptRoot
if ($LASTEXITCODE -ne 0) { throw 'Some portrait content sources could not be refreshed.' }
