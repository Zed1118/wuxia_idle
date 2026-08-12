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

for ($Index = 1; $Index -le $Repeat; $Index++) {
  $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  $RunId = "windows-$Viewport-$Tier-r$Index-$Timestamp"
  flutter run -d windows --profile `
    --dart-define="PROBE_VIEWPORT=$Viewport" `
    --dart-define="PROBE_TIER=$Tier" `
    --dart-define="PROBE_RUN_ID=$RunId" `
    --dart-define="PROBE_DURATION_SCALE=$DurationScale" `
    --dart-define="PROBE_OUTPUT_ROOT=$ProbeDir/build/results" `
    --dart-define="PROBE_REPOSITORY_ROOT=$RepositoryRoot" `
    --dart-define=PROBE_AUTO_CLOSE=true
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
