param(
    [string]$ProjectPath = 'C:\GameDev\SweetEmpire'
)

# Read-only static checks. Does not launch Unity or prove compilation/test success.
$ErrorActionPreference = 'Stop'
$results = @()
foreach ($relative in @('Assets', 'Packages', 'ProjectSettings', 'Packages\manifest.json', 'ProjectSettings\ProjectVersion.txt')) {
    $results += [pscustomobject]@{ Check = $relative; Passed = (Test-Path -LiteralPath (Join-Path $ProjectPath $relative)) }
}
$manifestPath = Join-Path $ProjectPath 'Packages\manifest.json'
$hasUrp = $false
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $hasUrp = $null -ne $manifest.dependencies.'com.unity.render-pipelines.universal'
}
$results += [pscustomobject]@{ Check = 'URP dependency (pipeline assignment still requires Unity verification)'; Passed = $hasUrp }
$versionPath = Join-Path $ProjectPath 'ProjectSettings\ProjectVersion.txt'
$isUnity6 = $false
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
    $isUnity6 = [bool](Select-String -LiteralPath $versionPath -Pattern '^m_EditorVersion: 6000\.' -Quiet)
}
$results += [pscustomobject]@{ Check = 'Unity 6 version marker (LTS must be checked separately)'; Passed = $isUnity6 }
$results | Format-Table -AutoSize
Write-Output 'Static checks only. Unity opening, import, pipeline configuration, compilation and tests were not run.'
if ($results.Passed -contains $false) { exit 1 }
exit 0
