param(
    [string]$Path = ".",
    [string]$Ports = "3000,3001,4000,4200,5000,5173,5174,8000,8080,8081,8888,9000"
)

if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    [Console]::Error.WriteLine("ERROR: project directory $Path does not exist.")
    exit 1
}

if ($Ports -notmatch '^[0-9]+(,[0-9]+)*$') {
    [Console]::Error.WriteLine("ERROR: ports must be a comma-separated list of numbers, got '$Ports'.")
    exit 1
}

$root = (Resolve-Path -LiteralPath $Path).Path

function Get-Text([string]$Name) {
    $p = Join-Path $root $Name
    if (Test-Path -LiteralPath $p -PathType Leaf) { return [System.IO.File]::ReadAllText($p) }
    return $null
}

function Test-File([string]$Name) {
    return (Test-Path -LiteralPath (Join-Path $root $Name) -PathType Leaf)
}

$pkg = Get-Text "package.json"
function Test-Dep([string]$Name) {
    if ($null -eq $pkg) { return $false }
    return ($pkg -match ('"' + [regex]::Escape($Name) + '"\s*:'))
}

$stack = New-Object System.Collections.Generic.List[string]

if ($null -ne $pkg) {
    $stack.Add("node")
    foreach ($dep in @("next", "vite", "react-scripts", "@angular/core", "nuxt", "@sveltejs/kit", "@remix-run/dev", "express", "fastify", "@nestjs/core")) {
        if (Test-Dep $dep) { $stack.Add($dep) }
    }
}
$req = Get-Text "requirements.txt"
$pyproject = Get-Text "pyproject.toml"
if (($null -ne $req) -or ($null -ne $pyproject) -or (Test-File "manage.py")) {
    $stack.Add("python")
    foreach ($fw in @("django", "flask", "fastapi")) {
        $inReq = ($null -ne $req) -and ($req -imatch "(?m)^$fw")
        $inPy = ($null -ne $pyproject) -and ($pyproject -imatch "`"?$fw")
        if ($inReq -or $inPy) { $stack.Add($fw) }
    }
}
if (Test-File "go.mod") { $stack.Add("go") }
$gemfile = Get-Text "Gemfile"
if ($null -ne $gemfile) {
    $stack.Add("ruby")
    if ($gemfile -imatch "gem ['`"]rails['`"]") { $stack.Add("rails") }
}
$composer = Get-Text "composer.json"
if ($null -ne $composer) {
    $stack.Add("php")
    if ($composer -imatch "laravel/framework") { $stack.Add("laravel") }
}
if ((Test-File "pom.xml") -or (Test-File "build.gradle") -or (Test-File "build.gradle.kts")) { $stack.Add("java") }

$devCommand = "none"
if (Test-Dep "dev") { $devCommand = "npm run dev" }
elseif (Test-Dep "start") { $devCommand = "npm start" }
elseif (Test-File "manage.py") { $devCommand = "python manage.py runserver" }
elseif ($null -ne $gemfile) { $devCommand = "bin/rails server" }
elseif (Test-File "artisan") { $devCommand = "php artisan serve" }

Write-Output "DEV_DETECT: $root"
if ($stack.Count -eq 0) {
    Write-Output "STACK: unknown"
} else {
    Write-Output "STACK: $($stack -join ', ')"
}
Write-Output "DEV_COMMAND: $devCommand"

Add-Type -AssemblyName System.Net.Http
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(2)

$count = 0
$first = "none"
foreach ($port in ($Ports -split ',')) {
    $url = "http://127.0.0.1:$port/"
    try {
        $response = $client.GetAsync($url).GetAwaiter().GetResult()
        $status = [int]$response.StatusCode
        $response.Dispose()
        Write-Output "LISTENING: http://127.0.0.1:$port (HTTP $status)"
        $count++
        if ($first -eq "none") { $first = "http://127.0.0.1:$port" }
    } catch {
    }
}

Write-Output "LISTENING_COUNT: $count"
Write-Output "SUGGESTED_TARGET: $first"
