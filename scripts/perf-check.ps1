param(
    [Parameter(Mandatory=$true)][string]$Url
)

Write-Output "PERFORMANCE CHECK: $Url"
Write-Output "========================"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30
    $stopwatch.Stop()

    Write-Output "HTTP_STATUS: $($response.StatusCode)"
    Write-Output "TTFB_MS: $($stopwatch.ElapsedMilliseconds)"
    Write-Output "SIZE_BYTES: $($response.Content.Length)"

    $headers = $response.Headers

    if ($headers["Content-Encoding"]) {
        Write-Output "COMPRESSION: enabled ($($headers["Content-Encoding"]))"
    } else {
        Write-Output "COMPRESSION: disabled"
    }

    if ($headers["Cache-Control"]) {
        Write-Output "CACHE: Cache-Control: $($headers["Cache-Control"])"
    } else {
        Write-Output "CACHE: no cache-control header"
    }

    if ($headers["Strict-Transport-Security"]) {
        Write-Output "HSTS: enabled"
    } else {
        Write-Output "HSTS: disabled"
    }

    Write-Output ""
    $ttfb = $stopwatch.ElapsedMilliseconds
    if ($ttfb -lt 200) {
        Write-Output "TTFB_RATING: excellent"
    } elseif ($ttfb -lt 500) {
        Write-Output "TTFB_RATING: good"
    } elseif ($ttfb -lt 1000) {
        Write-Output "TTFB_RATING: needs_improvement"
    } else {
        Write-Output "TTFB_RATING: poor"
    }
} catch {
    $stopwatch.Stop()
    Write-Error "Request failed: $($_.Exception.Message)"
    exit 1
}
