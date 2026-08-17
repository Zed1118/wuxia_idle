param(
  [Parameter(Mandatory = $true)]
  [string]$HostManifest,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedCommit,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedScenarioChecksum,
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
$ProbeDir = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  $OutputRoot = Join-Path $ProbeDir "build/windows_gate_matrix/$Timestamp"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$FrozenHostManifest = Join-Path $OutputRoot "host_manifest.json"
Copy-Item -Force (Resolve-Path $HostManifest).Path $FrozenHostManifest

$Runner = Join-Path $PSScriptRoot "run_phase0a_windows_profile.ps1"
& $Runner -Viewport desktop_1280x720 -Repeat 3 `
  -HostManifest $FrozenHostManifest `
  -ExpectedCommit $ExpectedCommit `
  -ExpectedScenarioChecksum $ExpectedScenarioChecksum `
  -ResultRoot $OutputRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Runner -Viewport desktop_1440x900 -Repeat 3 `
  -HostManifest $FrozenHostManifest `
  -ExpectedCommit $ExpectedCommit `
  -ExpectedScenarioChecksum $ExpectedScenarioChecksum `
  -ResultRoot $OutputRoot -SkipBuild
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location $ProbeDir
$ValidatorArgs = @(
  "run", "tool/validate_phase0a_windows_results.dart",
  "--results-root", $OutputRoot,
  "--host-manifest", $FrozenHostManifest,
  "--expected-commit", $ExpectedCommit,
  "--expected-checksum", $ExpectedScenarioChecksum,
  "--output-root", (Join-Path $OutputRoot "validation")
)
& dart @ValidatorArgs
if ($LASTEXITCODE -ne 0) {
  Write-Error "Windows Gate matrix validation failed. The result remains FAIL/INVALID, not PASS."
  exit $LASTEXITCODE
}

$ChecksumsPath = Join-Path $OutputRoot "SHA256SUMS.txt"
Get-ChildItem -Path $OutputRoot -Recurse -File |
  Where-Object { $_.FullName -ne $ChecksumsPath } |
  Sort-Object FullName |
  ForEach-Object {
    $Relative = $_.FullName.Substring($OutputRoot.Length).TrimStart("\")
    $Hash = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLowerInvariant()
    "$Hash  $Relative"
  } | Set-Content -Path $ChecksumsPath -Encoding UTF8
$ArchivePath = "$OutputRoot.zip"
if (Test-Path $ArchivePath) { Remove-Item -Force $ArchivePath }
Compress-Archive -Path (Join-Path $OutputRoot "*") -DestinationPath $ArchivePath
Write-Host "PHASE0A_WINDOWS_MATRIX_PASS $OutputRoot"
Write-Host "Archive: $ArchivePath"
