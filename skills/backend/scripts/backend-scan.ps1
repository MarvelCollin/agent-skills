param(
    [Parameter(Mandatory=$true)][string]$Path
)

if (-not (Test-Path -LiteralPath $Path)) {
    [Console]::Error.WriteLine("ERROR: $Path does not exist.")
    exit 1
}

$target = (Resolve-Path -LiteralPath $Path).Path
$excludedDirs = @("node_modules", ".git", "dist", "build", ".next", "vendor", "coverage", ".venv", "venv", "__pycache__", "target", "bin", "obj", "test", "tests", "__tests__", "spec", "e2e")
$extensions = @(".js", ".mjs", ".cjs", ".ts", ".py", ".rb", ".php", ".go", ".java", ".kt", ".cs", ".sql", ".prisma")
$excludedNames = @("*.min.*", "*.d.ts", "*.test.*", "*.spec.*", "*_test.go", "*_test.py", "test_*.py", "*_spec.rb", "*Test.java", "*Tests.cs")

if (Test-Path -LiteralPath $target -PathType Container) {
    $root = $target.TrimEnd('\', '/')
    $files = @(Get-ChildItem -LiteralPath $target -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
        $relative = $_.FullName.Substring($root.Length) -replace '\\', '/'
        $segments = $relative.TrimStart('/') -split '/'
        $dirSegments = if ($segments.Count -gt 1) { $segments[0..($segments.Count - 2)] } else { @() }
        $name = $_.Name
        ($extensions -contains $_.Extension.ToLower()) -and
        -not ($dirSegments | Where-Object { $excludedDirs -contains $_ }) -and
        $relative -notmatch '/storage/framework/' -and
        -not ($excludedNames | Where-Object { $name -like $_ })
    })
} else {
    $root = Split-Path -Parent $target
    $files = @(Get-Item -LiteralPath $target)
}
$sqlFiles = @($files | Where-Object { $_.Extension -eq ".sql" })

$results = New-Object System.Collections.Generic.List[string]

function Get-RelativePath([string]$FullPath) {
    return $FullPath.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
}

function Format-Code([string]$Code) {
    $text = $Code.TrimEnd("`r").TrimStart(" ", "`t")
    if ($text.Length -gt 120) { $text = $text.Substring(0, 120) }
    return $text
}

function Find-Lines($FileSet, [string]$Pattern, [switch]$IgnoreCase) {
    if (@($FileSet).Count -eq 0) { return @() }
    $paths = @($FileSet | ForEach-Object { $_.FullName })
    if ($IgnoreCase) {
        return @(Select-String -LiteralPath $paths -Pattern $Pattern -Encoding UTF8)
    }
    return @(Select-String -LiteralPath $paths -Pattern $Pattern -Encoding UTF8 -CaseSensitive)
}

function Add-Findings($Found, [string]$Rule, [string]$Check, [string]$Exclude = "") {
    foreach ($match in @($Found)) {
        if ($null -eq $match) { continue }
        if ($Exclude -and $match.Line -match $Exclude) { continue }
        $results.Add("$Rule $Check $(Get-RelativePath $match.Path):$($match.LineNumber): $(Format-Code $match.Line)")
    }
}

$q = '["''`]'
$money = '(price|amount|balance|cost|subtotal|fee|salary|total)'

Add-Findings (Find-Lines $files 'pass(word|wd)?.*(md5|sha1|sha256|sha512|createhash)|(md5|sha1|sha256|sha512|createhash).*pass(word|wd)?' -IgnoreCase) "B1" "weak-password-hash"

Add-Findings (Find-Lines $files '(findById|findByPk|findUnique|findOne|findFirst|get_object_or_404|objects[.]get|[.]find)[(][^)]*(req[.](params|query|body)|request[.](args|params|GET|POST|query_params|path_params)|params\[)' -IgnoreCase) "B2" "unscoped-lookup" 'owner|tenant|user_?id|account_?id|org_?id|current_?user|req[.]user|request[.]user'
Add-Findings (Find-Lines $files "(req[.]body|request[.](json|data|form|POST))([.]|\[$q?)(role|is_?admin|tenant_?id|owner_?id|user_?id|account_?id|permissions?)([^a-z_]|$)" -IgnoreCase) "B2" "client-authority"
Add-Findings (Find-Lines $files '(create|update|insert|build|assign|fill|updateOne|insertOne|update_attributes|merge)[(][^)]*req[.]body\s*[),}]|[*][*]request[.](data|json|POST|form)|params[.]permit!') "B2" "mass-assignment"

Add-Findings (Find-Lines $files '[.](findMany|findAll)[(]\s*[)]|[.]find[(]\s*(\{\s*\})?\s*[)]|objects[.]all[(][)]|[.]query[(][^)]*[)][.]all[(][)]') "B5" "unbounded-query" 'limit|take|paginat|first|slice|\[:'
Add-Findings (Find-Lines $files 'select\s+[*]\s+from' -IgnoreCase) "B5" "select-star" 'exists\s*[(]'
Add-Findings (Find-Lines $files 'offset\s+([$][0-9]|:[a-z_]+|[?]|%s|[0-9]+)|[.](skip|offset)[(]' -IgnoreCase) "B5" "offset-pagination"

Add-Findings (Find-Lines $sqlFiles 'create\s+(unique\s+)?index\s' -IgnoreCase) "B6" "blocking-index" 'concurrently'
Add-Findings (Find-Lines $files 'add_index\s') "B6" "blocking-index" 'concurrently'

Add-Findings (Find-Lines $files '(requests|httpx)[.](get|post|put|patch|delete|head|request)[(]') "B8" "no-timeout" 'timeout'
Add-Findings (Find-Lines $files '(^|[^A-Za-z0-9_.])fetch[(]') "B8" "no-timeout" 'signal|timeout'
Add-Findings (Find-Lines $files 'axios[.](get|post|put|patch|delete|request)[(]') "B8" "no-timeout" 'timeout'
Add-Findings (Find-Lines $files 'http[.](Get|Post|Head|PostForm)[(]|&http[.]Client\{\}|http[.]DefaultClient') "B8" "no-timeout"

Add-Findings (Find-Lines $files 'console[.](log|info|debug|warn|error)[(]|^\s*print[(]|System[.](out|err)[.]print|fmt[.]Print(ln|f)?[(]|^\s*puts\s|var_dump[(]|print_r[(]|Console[.]Write(Line)?[(]') "B9" "unstructured-log"
Add-Findings (Find-Lines $files '(^|[^a-z0-9_])(log|logger|logging|console|print)([.][a-z]+)?[(].*[,(+{]\s*[a-z_.]*(password|passwd|secret|token|authorization|api_?key|card_?number|cvv|ssn)' -IgnoreCase) "B9" "sensitive-log" 'redact|mask'

Add-Findings (Find-Lines $files 'catch\s*([(][^)]*[)])?\s*\{\s*\}|except(\s[^:]*)?:\s*pass(\s|$)|[.]catch[(]\s*([(][^)]*[)]|[A-Za-z_]*)\s*=>\s*(\{\s*\}|null|undefined)\s*[)]|rescue\s+nil') "B11" "swallowed-error"
Add-Findings (Find-Lines $files '^\s*except\s*:') "B11" "bare-except"
Add-Findings (Find-Lines $files '(res[.]|return|Response|jsonify|reply[.]).*((err|error|e|ex)[.]stack|format_exc[(]|str[(](e|err|exc|ex|error)[)])|res[.](status[(][0-9]+[)][.])?(send|json)[(](err|error|e)[)]') "B11" "leaked-error"

Add-Findings (Find-Lines $files '(readFileSync|writeFileSync|appendFileSync|execSync|spawnSync|pbkdf2Sync|scryptSync|hashSync|compareSync)[(]|(^|[^A-Za-z0-9_])time[.]sleep[(]|Thread[.]sleep[(]|[.]Result([^A-Za-z(]|$)|[.]Wait[(][)]|GetAwaiter[(][)][.]GetResult') "B12" "blocking-call"

Add-Findings (Find-Lines $files '(mongodb([+]srv)?|postgres(ql)?|mysql|mariadb|rediss?|amqps?|mssql)://[^:/"''\s@]+:[^@/"''\s]+@' -IgnoreCase) "B13" "credentials-in-dsn" '[$][{]|process[.]env|environ|getenv|ENV\['
Add-Findings (Find-Lines $files "(secret|key|token|password|passwd)[a-z_]*\s*(\|\||[?][?])\s*$q[^""'``]+|(getenv|environ[.]get)[(]\s*[""'][a-z_]*(secret|key|token|password)[a-z_]*[""']\s*,\s*[""'][^""']+[""']" -IgnoreCase) "B13" "secret-fallback"

Add-Findings (Find-Lines $files "$money[a-z_]*\s*[:=]\s*(parsefloat|float)[(]|$money[a-z_]*\s+(float|double|real|float32|float64)([^a-z0-9]|$)|(float|double|float64)\s+$money|$money[a-z_]*\s*=\s*(models[.]floatfield|column[(]\s*float|db[.]column[(]\s*db[.]float|mapped_column[(]\s*float)" -IgnoreCase) "B14" "float-money"
Add-Findings (Find-Lines $files 'datetime[.](utcnow|now)[(]\s*[)]|DateTime[.]Now([^A-Za-z]|$)') "B14" "naive-datetime"
Add-Findings (Find-Lines $sqlFiles '\stimestamp(\s*,|\s+(not|null|default)|\s*$)' -IgnoreCase) "B14" "naive-datetime"

$db = 'prisma[.][A-Za-z_]+[.][A-Za-z]+[(]|[.]objects[.](get|filter|exclude|count|create)[(]|session[.](query|get|execute|scalar|scalars)[(]|cursor[.]execute[(]|[.](query|execute|raw)[(]|[.](findOne|findById|findByPk|findUnique|findFirst|findMany|findAll|find_by|countDocuments|aggregate|populate|where)[(]|[Rr]epo(sitory)?[.](find|get|count|exists|load)|(ToListAsync|FirstOrDefaultAsync|SingleOrDefaultAsync|FindAsync|CountAsync)[(]|db[.](First|Find|Where|Raw|Get|Select|Query|QueryRow|Exec)[(]|knex[(]|[A-Z][A-Za-z0-9_]*[.](find|find_by)[(]'
$http = '(^|[^A-Za-z0-9_.])fetch[(]|axios([.](get|post|put|patch|delete|request))?[(]|(requests|httpx)[.](get|post|put|patch|delete)[(]|http[.](Get|Post)[(]|[.](GetAsync|PostAsync|getForObject|getForEntity)[(]'
$cb = '[.](forEach|map|flatMap|each|each_with_index|find_each|for_each)[ \t]*[({]|[.]each[ \t]+do'
$stmt = '^[ \t]*(async[ \t]+)?(for|foreach|while)([ \t(]|$)'
$comp = '[ \t]for[ \t]+[A-Za-z_][A-Za-z0-9_, ]*[ \t]in[ \t]'

function Find-LoopHit([string]$Text) {
    if ($Text -cmatch $db) { return "query-in-loop" }
    if ($Text -cmatch $http) { return "http-in-loop" }
    return ""
}

foreach ($file in $files) {
    $relPath = Get-RelativePath $file.FullName
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $loopLine = 0
    $loopIndent = 0
    $prev = ""
    $prevNumber = 0
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $number = $i + 1
        $line = $lines[$i].TrimEnd("`r")
        if ($line -match '^[ \t]*$') { continue }
        $indent = $line.Length - $line.TrimStart(" ", "`t").Length
        if ($loopLine -gt 0 -and ($indent -le $loopIndent -or $number - $loopLine -gt 12)) { $loopLine = 0 }
        $hit = ""
        if ($loopLine -gt 0) { $hit = Find-LoopHit $line }
        if (-not $hit) {
            $cbMatch = [regex]::Match($line, $cb)
            if ($cbMatch.Success) { $hit = Find-LoopHit $line.Substring($cbMatch.Index + $cbMatch.Length) }
        }
        if (-not $hit -and $line -cnotmatch $stmt -and $line -cmatch $comp) { $hit = Find-LoopHit $line }
        if ($hit) { $results.Add("B4 $hit ${relPath}:${number}: $(Format-Code $line)") }
        if ($line -cmatch $stmt -or $line -cmatch $cb) {
            $loopLine = $number
            $loopIndent = $indent
        }
        if ($line -cmatch '^[ \t]*(pass|\})[ \t]*$') {
            if (($line -cmatch 'pass' -and $prev -cmatch '^[ \t]*except[^:]*:[ \t]*$') -or ($line -cmatch '\}' -and $prev -cmatch 'catch[ \t]*([(][^)]*[)])?[ \t]*\{[ \t]*$')) {
                $results.Add("B11 swallowed-error ${relPath}:${prevNumber}: $(Format-Code $prev)")
            }
        }
        $prev = $line
        $prevNumber = $number
    }
}

$rules = @("B1", "B2", "B4", "B5", "B6", "B8", "B9", "B11", "B12", "B13", "B14")

Write-Output "BACKEND SCAN: $Path"
Write-Output "FILES_SCANNED: $($files.Count)"
Write-Output ""
$results | Sort-Object @{ Expression = { [int]($_.Split(' ')[0].Substring(1)) } }, @{ Expression = { $_.Split(' ')[1] } }, @{ Expression = { $_.Split(' ')[2] } } | ForEach-Object { Write-Output $_ }
Write-Output ""
Write-Output "FINDINGS: $($results.Count)"
foreach ($rule in $rules) {
    $count = @($results | Where-Object { $_.StartsWith("$rule ") }).Count
    Write-Output "${rule}: $count"
}
Write-Output ""
Write-Output "Each line is a lead, not a confirmed finding. Read it in context before reporting."
