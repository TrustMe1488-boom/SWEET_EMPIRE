[CmdletBinding()]
param(
    [string]$GodotPath,
    [ValidateSet('headless','gpu','ipc','camera')] [string]$Mode = 'headless',
    [string[]]$Suite = @()
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Test-GodotResult.ps1')
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runDirectory = $null
$lock = $null
try {
    $catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'suites.json') -Raw | ConvertFrom-Json
    $selected = @($catalog.suites | Where-Object { $_.mode -eq $Mode -and $_.enabled })
    if ($Suite.Count -gt 0) {
        $selected = @()
        foreach ($id in $Suite) {
            $found = @($catalog.suites | Where-Object { $_.id -ceq $id -and $_.mode -eq $Mode })
            if ($found.Count -ne 1) { throw "Unknown suite/mode: $id / $Mode" }
            if (-not $found[0].enabled) { throw "Suite blocked: $id. $($found[0].reason)" }
            if (@($selected | Where-Object { $_.id -ceq $id }).Count) { throw "Duplicate suite: $id" }
            $selected += $found[0]
        }
    }
    if ($Mode -ne 'headless' -and $Suite.Count -eq 0) { throw 'Non-headless mode requires explicit -Suite selection' }
    if ($selected.Count -eq 0) { throw 'No runnable suites selected' }
    if (-not $GodotPath) { throw 'Supply the absolute path to the installed Godot console exe' }
    if (-not [IO.Path]::IsPathRooted($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw 'Godot executable not found at absolute path' }
    if ([IO.Path]::GetFileName($GodotPath) -notmatch '^Godot.*console\.exe$') { throw 'Expected Godot console executable' }
    # Conservative exclusion: refuse while any Godot process is present; no process is killed here.
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'Godot*' }).Count) { throw 'Close all Godot processes before running' }
    $outputRoot = Join-Path $project '.local/testing'
    [IO.Directory]::CreateDirectory($outputRoot) | Out-Null
    $lock = [IO.File]::Open((Join-Path $outputRoot 'runner.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    $runDirectory = Join-Path $outputRoot ([guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($runDirectory) | Out-Null
    $results = @()
    foreach ($entry in $selected) {
        $directory = Join-Path $runDirectory $entry.id
        [IO.Directory]::CreateDirectory($directory) | Out-Null
        $stdout = Join-Path $directory 'stdout.log'; $stderr = Join-Path $directory 'stderr.log'; $log = Join-Path $directory 'godot.log'
        $started = [datetime]::UtcNow; $timedOut = $false; $launchError = ''; $code = $null; $process = $null
        try {
            if ($entry.script -notmatch '^tests/[a-zA-Z0-9_]+\.gd$' -or -not (Test-Path -LiteralPath (Join-Path $project $entry.script))) { throw 'Invalid/missing suite script' }
            $arguments = @('--path', ('"' + $project + '"'), '--log-file', ('"' + $log + '"'), '--script', $entry.script)
            if ($Mode -in @('headless','ipc')) { $arguments = @('--headless') + $arguments }
            $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WorkingDirectory $project -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
            if (-not $process.WaitForExit([int]$entry.timeoutSeconds * 1000)) {
                $timedOut = $true
                $process.Kill()
                if (-not $process.WaitForExit(5000)) { throw 'Timed-out Godot could not be stopped; aborting remaining suites' }
            }
            $process.WaitForExit()
            $code = [int]$process.ExitCode
        } catch { $launchError = $_.Exception.Message }
        $verdict = Test-GodotResult -StdoutPath $stdout -StderrPath $stderr -LogPath $log -Marker $entry.marker -Format $entry.format -StartedUtc $started -ExitCode $code -TimedOut $timedOut -LaunchError $launchError
        $row = [pscustomobject]@{ Suite=$entry.id; Mode=$Mode; ExitCode=$code; TimedOut=$timedOut; Passed=$verdict.Passed; Reasons=$verdict.Reasons; Result=$verdict.Result; Artifacts=$directory }
        $results += $row
        $row | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $directory 'result.json') -Encoding UTF8
        Write-Output (('{0}: {1}' -f $entry.id, @('FAIL','PASS')[[int]$verdict.Passed]))
        foreach ($reason in $verdict.Reasons) { Write-Output "  $reason" }
        if ($null -ne $process -and -not $process.HasExited) { throw 'Godot still running; no further launch allowed' }
        if ($null -ne $process) { $process.Dispose() }
    }
    $results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runDirectory 'summary.json') -Encoding UTF8
    Write-Output "Artifacts: $runDirectory"
    if (@($results | Where-Object { -not $_.Passed }).Count) { exit 1 }
    exit 0
} catch {
    Write-Output "RUNNER FAIL: $($_.Exception.Message)"
    if ($runDirectory) { $_.Exception.ToString() | Set-Content -LiteralPath (Join-Path $runDirectory 'runner-error.txt') -Encoding UTF8 }
    exit 1
} finally { if ($null -ne $lock) { $lock.Dispose() } }
