$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://api.open-meteo.com/v1/forecast?latitude=36.4800&longitude=127.2890&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code&hourly=temperature_2m,weather_code,precipitation_probability&daily=temperature_2m_max,temperature_2m_min&timezone=Asia%2FSeoul&past_days=0&forecast_days=2'
$data = Invoke-RestMethod -Uri $url -TimeoutSec 25
$kst = [DateTimeOffset]::UtcNow.AddHours(9)
$today = $kst.ToString('yyyy-MM-dd') + 'T15:00'
$tomorrow = $kst.AddDays(1).ToString('yyyy-MM-dd') + 'T09:00'
if ($null -eq $data.current.temperature_2m -or $data.hourly.time -notcontains $today -or $data.hourly.time -notcontains $tomorrow) { throw 'Incomplete current/today/tomorrow forecast; previous weather preserved.' }
$encoded = @{ savedAt=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); data=$data } | ConvertTo-Json -Depth 20 -Compress
$encoded = $encoded.Replace('<','\u003c')
$utf8 = New-Object Text.UTF8Encoding($false)
function Save-WeatherFile([string]$name,[string]$content) {
    $path = Join-Path $PSScriptRoot $name
    $temp = $path + '.portrait-weather.tmp'
    [IO.File]::WriteAllText($temp,$content,$utf8)
    if ([IO.File]::Exists($path)) { [IO.File]::Replace($temp,$path,[NullString]::Value) } else { [IO.File]::Move($temp,$path) }
}
Save-WeatherFile 'dodam-weather.json' ($encoded + "`n")
Save-WeatherFile 'dodam-weather-feed.js' ('window.DODAM_WEATHER_RESPONSE=' + $encoded + ";`n")
# The 1080x520 original HTML is deliberately never written.
$top = Join-Path $PSScriptRoot 'dodam-clock-portrait-top.html'
if (Test-Path -LiteralPath $top) {
    $html = [IO.File]::ReadAllText($top)
    $pattern = 'window\.DODAM_WEATHER_SEED=[^\r\n]*;'
    if ([regex]::Matches($html,$pattern).Count -ne 1) { throw 'Expected exactly one portrait weather seed.' }
    $html = [regex]::Replace($html,$pattern,[Text.RegularExpressions.MatchEvaluator]{param($match) 'window.DODAM_WEATHER_SEED=' + $encoded + ';'})
    Save-WeatherFile 'dodam-clock-portrait-top.html' $html
}
Write-Output ('Weather ready: ' + $today + ' / ' + $tomorrow)
