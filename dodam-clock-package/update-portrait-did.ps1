$ErrorActionPreference = 'Stop'
$collector = Join-Path $PSScriptRoot 'portrait-did-collector\PortraitCollector.exe'
& $collector $PSScriptRoot
if ($LASTEXITCODE -ne 0) { throw 'Some portrait content sources could not be refreshed.' }

# Remove cached images that are no longer referenced by the successfully refreshed data.
$dataPath = Join-Path $PSScriptRoot 'portrait-did-data.json'
$imageRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'portrait-did-images'))
$data = Get-Content -LiteralPath $dataPath -Raw | ConvertFrom-Json
$referenced = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($collection in @('books','movies','contests','exhibitions')) {
    foreach ($item in @($data.$collection)) {
        if ($item.image -and $item.image -match '^portrait-did-images/([^/\\]+)$') {
            [void]$referenced.Add($Matches[1])
        }
    }
}
Get-ChildItem -LiteralPath $imageRoot -File | ForEach-Object {
    $resolved = [IO.Path]::GetFullPath($_.FullName)
    if ($resolved.StartsWith($imageRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and -not $referenced.Contains($_.Name)) {
        Remove-Item -LiteralPath $resolved -Force
    }
}
