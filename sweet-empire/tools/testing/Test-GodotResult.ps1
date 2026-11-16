Set-StrictMode -Version Latest

function Test-GodotResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$StdoutPath,
        [Parameter(Mandatory)] [string]$StderrPath,
        [Parameter(Mandatory)] [string]$LogPath,
        [Parameter(Mandatory)] [string]$Marker,
        [ValidateSet('counts','checks')] [string]$Format = 'counts',
        [Parameter(Mandatory)] [datetime]$StartedUtc,
        [AllowNull()] [object]$ExitCode,
        [bool]$TimedOut = $false,
        [string]$LaunchError = ''
    )
    $reasons = [System.Collections.Generic.List[string]]::new()
    if ($LaunchError) { $reasons.Add("Launch error: $LaunchError") }
    if ($TimedOut) { $reasons.Add('Process timed out') }
    if ($null -eq $ExitCode -or $ExitCode -isnot [int] -or $ExitCode -ne 0) {
        $reasons.Add("Invalid/nonzero exit code: $ExitCode")
    }
    if ($Marker -notmatch '^[A-Z0-9_]*RESULT$') { $reasons.Add('Invalid marker configuration') }
    $texts = @{}
    foreach ($item in @(@('stdout',$StdoutPath),@('stderr',$StderrPath),@('godot',$LogPath))) {
        $name = $item[0]; $path = $item[1]
        try {
            $file = Get-Item -LiteralPath $path -ErrorAction Stop
            if ($file.PSIsContainer -or $file.LastWriteTimeUtc -lt $StartedUtc) {
                $reasons.Add("Stale/invalid artifact: $name")
            }
            $texts[$name] = [System.IO.File]::ReadAllText($file.FullName)
        } catch { $reasons.Add("Missing/unreadable artifact ${name}: $($_.Exception.Message)"); $texts[$name] = '' }
    }
    if ([string]::IsNullOrWhiteSpace($texts.godot)) { $reasons.Add('Empty Godot log') }
    # No error allowlist: engine and script errors are fatal even after RESULT.
    $critical = '(?im)^.*(?:\b(?:SCRIPT\s+ERROR|ERROR|FATAL(?:\s+ERROR)?|Parse\s+Error|Compile\s+Error)\s*:|Failed to (?:load|open|instantiate)\b|\b(?:CrashHandler|Segmentation fault|Unhandled exception)\b).*$'
    foreach ($name in @('stdout','stderr','godot')) {
        foreach ($hit in [regex]::Matches($texts[$name], $critical)) { $reasons.Add("Critical ${name}: $($hit.Value.Trim())") }
    }
    $escaped = [regex]::Escape($Marker)
    $pattern = if ($Format -eq 'counts') {
        "^${escaped}: (?<passed>\d+) passed, (?<failed>\d+) failed$"
    } else { "^${escaped}: checks=(?<total>\d+) failed=(?<failed>\d+)$" }
    $canonical = $null
    foreach ($name in @('stdout','stderr','godot')) {
        $lines = @($texts[$name] -split '\r?\n' | Where-Object { $_ -match '\b[A-Z0-9_]*RESULT\b' })
        # Godot mirrors stdout into its own log. Require one canonical stdout result;
        # permit its identical mirror once, never count it as an extra test result.
        if ($name -eq 'stdout' -and $lines.Count -ne 1) { $reasons.Add('Expected exactly one stdout RESULT') }
        if ($name -ne 'stdout' -and $lines.Count -gt 1) { $reasons.Add("Duplicate RESULT in $name") }
        if ($name -eq 'stderr' -and $lines.Count -gt 0) { $reasons.Add('Unexpected RESULT on stderr') }
        foreach ($line in $lines) {
            $match = [regex]::Match($line, $pattern)
            if (-not $match.Success) { $reasons.Add("Malformed/unexpected RESULT in ${name}: $line"); continue }
            try {
                $failures = [long]::Parse($match.Groups['failed'].Value)
                $total = if ($Format -eq 'counts') { [decimal]::Parse($match.Groups['passed'].Value) + $failures } else { [long]::Parse($match.Groups['total'].Value) }
                if ($failures -ne 0 -or $total -le 0) { $reasons.Add("Failed/empty checks in $name") }
            } catch { $reasons.Add("Invalid RESULT numbers in $name") }
            if ($name -eq 'stdout') { $canonical = $line }
            elseif ($name -eq 'godot' -and $line -cne $canonical) { $reasons.Add('Godot RESULT differs from stdout') }
        }
    }
    [pscustomobject]@{ Passed = ($reasons.Count -eq 0); Reasons = @($reasons.ToArray()); Result = $canonical }
}
