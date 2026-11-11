$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:exe /out:PortraitCollector.exe /reference:System.Web.Extensions.dll /reference:System.Drawing.dll PortraitCollector.cs
    if ($LASTEXITCODE -ne 0) { throw 'Portrait collector build failed.' }
} finally { Pop-Location }
