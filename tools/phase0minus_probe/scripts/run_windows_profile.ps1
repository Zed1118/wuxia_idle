param(
  [ValidateSet("desktop_1280x720", "desktop_1440x900")]
  [string]$Viewport = "desktop_1280x720",
  [ValidateSet("baseline_10", "target_20_plus_1", "stress_30")]
  [string]$Tier = "stress_30",
  [int]$Repeat = 1,
  [double]$DurationScale = 1.0
)

$ErrorActionPreference = "Stop"
$ProbeDir = Split-Path -Parent $PSScriptRoot
$RepositoryRoot = (Resolve-Path (Join-Path $ProbeDir "../..")).Path
Set-Location $ProbeDir
flutter build windows --profile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$Binary = Join-Path $ProbeDir "build/windows/x64/runner/Profile/phase0minus_probe.exe"
if (-not (Test-Path $Binary)) { throw "Profile binary not found: $Binary" }

for ($Index = 1; $Index -le $Repeat; $Index++) {
  $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  $RunId = "windows-$Viewport-$Tier-r$Index-$Timestamp"
  $env:PROBE_VIEWPORT = $Viewport
  $env:PROBE_TIER = $Tier
  $env:PROBE_RUN_ID = $RunId
  $env:PROBE_DURATION_SCALE = $DurationScale.ToString(
    [Globalization.CultureInfo]::InvariantCulture
  )
  $env:PROBE_OUTPUT_ROOT = Join-Path $ProbeDir "build/results"
  $env:PROBE_REPOSITORY_ROOT = $RepositoryRoot
  $env:PROBE_AUTO_CLOSE = "true"
  $env:PROBE_EXPECTED_REFRESH_RATE = "60"
  $env:PROBE_EXPECTED_DPR = "1"
  & $Binary
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
