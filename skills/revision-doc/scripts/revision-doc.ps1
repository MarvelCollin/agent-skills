param(
    [Parameter(Position = 0)][ValidateSet("init", "build", "check")][string]$Command,
    [Parameter(Position = 1)][string]$Path,
    [string]$Title,
    [ValidateSet("id", "en")][string]$Lang,
    [string]$Out,
    [string]$CopyTo
)

$ErrorActionPreference = "Stop"

if (-not $Command -or -not $Path) {
    Write-Output "Usage: revision-doc.ps1 init <folder> [-Title <title>] [-Lang id|en]"
    Write-Output "       revision-doc.ps1 build <folder> [-Out <file.docx>] [-CopyTo <folder>]"
    Write-Output "       revision-doc.ps1 check <file.docx>"
    exit 1
}

$python = $null
foreach ($candidate in @("python", "python3", "py")) {
    $found = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($found) {
        & $found.Source -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $python = $found.Source
            break
        }
    }
}

if (-not $python) {
    Write-Output "ERROR: Python 3.8 or newer is needed. Install it, then run: pip install python-docx pillow"
    exit 3
}

$script = Join-Path $PSScriptRoot "revision_doc.py"
$arguments = @($script, $Command, $Path)
if ($Title) { $arguments += @("--title", $Title) }
if ($Lang) { $arguments += @("--lang", $Lang) }
if ($Out) { $arguments += @("--out", $Out) }
if ($CopyTo) { $arguments += @("--copy-to", $CopyTo) }

& $python @arguments
exit $LASTEXITCODE
