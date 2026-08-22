param(
  [Parameter(Mandatory = $true)]
  [string]$HostManifest,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedCommit,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedFixtureChecksum,
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  $OutputRoot = Join-Path $RepositoryRoot "build/route_c_windows_matrix/$Timestamp"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$FrozenHost = Join-Path $OutputRoot "host_manifest.json"
Copy-Item -Force (Resolve-Path $HostManifest).Path $FrozenHost

$Runner = Join-Path $PSScriptRoot "run_route_c_windows_profile.ps1"
& $Runner -Viewport "1280x720" -Repeat 3 -HostManifest $FrozenHost `
  -ExpectedCommit $ExpectedCommit -ExpectedFixtureChecksum $ExpectedFixtureChecksum `
  -ResultRoot $OutputRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$BuiltPayload = Join-Path $RepositoryRoot "build/windows/x64/runner/Profile/data/app.so"
Copy-Item -Force $BuiltPayload (Join-Path $OutputRoot "app.so")
Copy-Item -Force (Join-Path $RepositoryRoot "data/phase0a_debug_battle.yaml") `
  (Join-Path $OutputRoot "phase0a_debug_battle.yaml")
& $Runner -Viewport "1440x900" -Repeat 3 -HostManifest $FrozenHost `
  -ExpectedCommit $ExpectedCommit -ExpectedFixtureChecksum $ExpectedFixtureChecksum `
  -ResultRoot $OutputRoot -SkipBuild
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location $RepositoryRoot
$PreflightPath = Join-Path $OutputRoot "preflight.json"
dart run tool/route_c_gate_preflight.dart --candidate $ExpectedCommit `
  --windows-dir $OutputRoot --output $PreflightPath
if ($LASTEXITCODE -notin @(0, 2)) { exit $LASTEXITCODE }

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
Compress-Archive -Path (Join-Path $OutputRoot "*") -DestinationPath $ArchivePath
Write-Host "ROUTE_C_WINDOWS_MATRIX_MECHANICAL_PASS $OutputRoot"
Write-Host "Route C external Gate archive: $ArchivePath"
