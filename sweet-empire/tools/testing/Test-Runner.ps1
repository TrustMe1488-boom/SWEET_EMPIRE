[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$failures = 0
foreach ($path in @('Run-GodotTests.ps1','Test-GodotResult.ps1','Test-Runner.ps1')) {
    $tokens = $null; $parseErrors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $path), [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { $failures++; Write-Output "STATIC FAIL: $path"; $parseErrors | ForEach-Object { Write-Output $_.Message } }
    else { Write-Output "STATIC PASS: $path" }
}
if ($failures) { exit 1 }
. (Join-Path $PSScriptRoot 'Test-GodotResult.ps1')
$catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'suites.json') -Raw | ConvertFrom-Json
$ids = @{}
foreach ($entry in $catalog.suites) {
    if ($ids.ContainsKey($entry.id) -or $entry.mode -notin @('headless','gpu','ipc','camera') -or
        $entry.timeoutSeconds -le 0 -or $entry.timeoutSeconds -gt 3600 -or
        $entry.script -cne ('tests/' + $entry.id + '.gd') -or
        -not (Test-Path -LiteralPath (Join-Path $project $entry.script)) -or
        $entry.format -notin @('counts','checks')) { throw "Invalid manifest entry: $($entry.id)" }
    $ids[$entry.id] = $true
    if ($entry.enabled -and -not ([IO.File]::ReadAllText((Join-Path $project $entry.script))).Contains($entry.marker)) { throw "Marker absent: $($entry.id)" }
    if ($entry.mode -eq 'headless' -and ([IO.File]::ReadAllText((Join-Path $project $entry.script))) -match 'gesture_bridge\.start\(|bridge\.start\(|OS\.(create_process|execute)\(') { throw "External process in headless suite: $($entry.id)" }
}
Write-Output "STATIC PASS: manifest ($($catalog.suites.Count) suites)"
$cases = Get-Content -LiteralPath (Join-Path $project 'tests/harness_fixtures/cases.json') -Raw | ConvertFrom-Json
$directory = Join-Path $project ('.local/testing/classifier/' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($directory) | Out-Null
$results = @()
foreach ($case in $cases) {
    $data = @{}; foreach ($property in $case.PSObject.Properties) { $data[$property.Name] = $property.Value }
    $caseDirectory = Join-Path $directory $case.name
    [IO.Directory]::CreateDirectory($caseDirectory) | Out-Null
    $started = [datetime]::UtcNow
    $stdout = Join-Path $caseDirectory 'stdout.log'; $stderr = Join-Path $caseDirectory 'stderr.log'; $log = Join-Path $caseDirectory 'godot.log'
    [IO.File]::WriteAllText($stdout, $case.stdout)
    [IO.File]::WriteAllText($stderr, [string]$data['stderr'])
    $logText = if ($data.ContainsKey('log')) { [string]$data.log } else { 'Godot Engine synthetic fixture' }
    [IO.File]::WriteAllText($log, $logText)
    # Remove only synthetic files just created in this case directory; no recursive cleanup.
    if ($data['missingLog']) { [IO.File]::Delete($log) }
    if ($data['missingStdout']) { [IO.File]::Delete($stdout) }
    if ($data['missingStderr']) { [IO.File]::Delete($stderr) }
    if ($data['stale']) { [IO.File]::SetLastWriteTimeUtc($log, $started.AddDays(-1)) }
    $code = if ($data['nullExit']) { $null } elseif ($data.ContainsKey('exit')) { [int]$data.exit } else { 0 }
    $format = if ($data.ContainsKey('format')) { $data.format } else { 'counts' }
    $verdict = Test-GodotResult -StdoutPath $stdout -StderrPath $stderr -LogPath $log -Marker 'FIXTURE_RESULT' -Format $format -StartedUtc $started -ExitCode $code -TimedOut ([bool]$data['timeout']) -LaunchError ([string]$data['launchError'])
    $correct = $verdict.Passed -eq $case.pass
    if (-not $correct) { $failures++ }
    Write-Output ('CLASSIFIER {0}: {1} (actual={2}, expected={3})' -f @('FAIL','PASS')[[int]$correct], $case.name, $verdict.Passed, $case.pass)
    $results += [pscustomobject]@{ Case=$case.name; Correct=$correct; Expected=$case.pass; Actual=$verdict.Passed; Reasons=$verdict.Reasons }
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $directory 'results.json') -Encoding UTF8
Write-Output "CLASSIFIER SUMMARY: $($cases.Count) cases, $failures failed; artifacts: $directory"
if ($failures) { exit 1 }
exit 0
