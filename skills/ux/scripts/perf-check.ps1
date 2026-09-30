param(
    [Parameter(Mandatory=$true)][string]$Url
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Get-HeaderValue($Response, [string]$Name) {
    $values = $null
    if ($Response.Headers.TryGetValues($Name, [ref]$values)) {
        return ($values -join ", ")
    }
    if ($Response.Content.Headers.TryGetValues($Name, [ref]$values)) {
        return ($values -join ", ")
    }
    return $null
}

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $false
$handler.AutomaticDecompression = [System.Net.DecompressionMethods]::None
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds(30)

$currentUri = [Uri]$Url
$redirects = 0
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    while ($true) {
        $request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $currentUri)
        [void]$request.Headers.TryAddWithoutValidation("Accept-Encoding", "gzip, deflate, br")
        $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        $status = [int]$response.StatusCode
        if ($status -ge 300 -and $status -lt 400 -and $response.Headers.Location -and $redirects -lt 10) {
            $currentUri = New-Object Uri($currentUri, $response.Headers.Location)
            $redirects++
            $response.Dispose()
            continue
        }
        break
    }
    $ttfbMs = $stopwatch.ElapsedMilliseconds
    $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    $totalMs = $stopwatch.ElapsedMilliseconds
} catch {
    [Console]::Error.WriteLine("ERROR: request to $Url failed. $($_.Exception.GetBaseException().Message)")
    exit 1
} finally {
    $stopwatch.Stop()
}

$encoding = Get-HeaderValue $response "Content-Encoding"
$cacheControl = Get-HeaderValue $response "Cache-Control"

Write-Output "PERFORMANCE CHECK: $Url"
Write-Output "========================"
Write-Output "HTTP_STATUS: $status"
Write-Output "FINAL_URL: $($currentUri.AbsoluteUri)"
Write-Output "REDIRECTS: $redirects"
Write-Output "CONNECT_MS: n/a"
Write-Output "TLS_MS: n/a"
Write-Output "TTFB_MS: $ttfbMs"
Write-Output "TOTAL_MS: $totalMs"
Write-Output "TRANSFER_BYTES: $($bytes.Length)"

if ($encoding) {
    Write-Output "COMPRESSION: enabled ($encoding)"
} else {
    Write-Output "COMPRESSION: disabled"
}

if ($cacheControl) {
    Write-Output "CACHE_CONTROL: $cacheControl"
} else {
    Write-Output "CACHE_CONTROL: missing"
}

if ($ttfbMs -le 800) {
    Write-Output "TTFB_RATING: good"
} elseif ($ttfbMs -le 1800) {
    Write-Output "TTFB_RATING: needs_improvement"
} else {
    Write-Output "TTFB_RATING: poor"
}
