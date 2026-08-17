param(
  [ValidateSet("desktop_1280x720", "desktop_1440x900")]
  [string]$Viewport = "desktop_1280x720",
  [ValidateRange(1, 20)]
  [int]$Repeat = 1,
  [double]$DurationScale = 1.0,
  [Parameter(Mandatory = $true)]
  [string]$HostManifest,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedCommit,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedScenarioChecksum,
  [string]$ResultRoot = "",
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
if ([math]::Abs($DurationScale - 1.0) -gt 0.000001) {
  throw "The physical Gate runner only accepts DurationScale=1.0. Use a separate smoke command for shortened runs."
}

$ProbeDir = Split-Path -Parent $PSScriptRoot
$RepositoryRoot = (Resolve-Path (Join-Path $ProbeDir "../..")).Path
$HostManifest = (Resolve-Path $HostManifest).Path
if ([string]::IsNullOrWhiteSpace($ResultRoot)) {
  $ResultRoot = Join-Path $ProbeDir "build/windows_gate_results"
}
New-Item -ItemType Directory -Force -Path $ResultRoot | Out-Null

$HostFacts = Get-Content -Raw -Path $HostManifest | ConvertFrom-Json
if ($HostFacts.status -ne "RECORDED") { throw "Host manifest status must be RECORDED." }
if (-not $HostFacts.attestation.valid_for_minimum_spec_gate) {
  throw "Host manifest is not attested for the minimum-spec Gate."
}
if (-not $HostFacts.attestation.cpu_at_or_below_target -or
    -not $HostFacts.attestation.gpu_at_or_below_target -or
    -not $HostFacts.attestation.ram_matches_target -or
    -not $HostFacts.attestation.power_mode_confirmed_best_performance) {
  throw "CPU, GPU, RAM, and best-performance power attestations must all be true."
}
if (-not $HostFacts.device.gpu_is_integrated -or -not $HostFacts.device.plugged_in) {
  throw "The active GPU must be integrated and the machine must be plugged in."
}
if ($HostFacts.display.refresh_rate_hz -ne 60 -or $HostFacts.display.scale_percent -ne 100) {
  throw "The physical Gate requires 60Hz and 100% Windows display scaling."
}
if ($HostFacts.session.remote_desktop -or $HostFacts.session.virtual_machine) {
  throw "RDP and virtual-machine sessions cannot sign the physical Gate."
}
if (-not $HostFacts.display.local_interactive_session) {
  throw "The Gate must run in a local interactive console session."
}
if ($HostFacts.runtime.renderer -match "FILL_|COLLECT_MANUALLY|UNKNOWN") {
  throw "Record the actual Flutter renderer in the host manifest before running."
}

$ActualCommit = (& git -C $RepositoryRoot rev-parse HEAD | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw "Unable to read repository commit." }
if ($ActualCommit -ne $ExpectedCommit) {
  throw "Commit mismatch. Expected $ExpectedCommit, found $ActualCommit."
}
$Dirty = (& git -C $RepositoryRoot status --porcelain | Out-String).Trim()
if (-not [string]::IsNullOrWhiteSpace($Dirty)) {
  throw "The repository is dirty. Physical Gate runs require a clean worktree."
}
$ScenarioPath = Join-Path $ProbeDir "assets/probe_scenarios.yaml"
$ActualScenarioChecksum = (Get-FileHash -Algorithm SHA256 $ScenarioPath).Hash.ToLowerInvariant()
if ($ActualScenarioChecksum -ne $ExpectedScenarioChecksum.ToLowerInvariant()) {
  throw "Scenario checksum mismatch. Expected $ExpectedScenarioChecksum, found $ActualScenarioChecksum."
}

Set-Location $ProbeDir
if (-not $SkipBuild) {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  flutter build windows --profile
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
$Binary = Join-Path $ProbeDir "build/windows/x64/runner/Profile/phase0minus_probe.exe"
if (-not (Test-Path $Binary)) { throw "Profile binary not found: $Binary" }
$BinaryChecksum = (Get-FileHash -Algorithm SHA256 $Binary).Hash.ToLowerInvariant()
$HostChecksum = (Get-FileHash -Algorithm SHA256 $HostManifest).Hash.ToLowerInvariant()
$FlutterVersion = [string]$HostFacts.runtime.flutter_version
$DartVersion = [string]$HostFacts.runtime.dart_version
$Renderer = [string]$HostFacts.runtime.renderer

for ($Index = 1; $Index -le $Repeat; $Index++) {
  $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  $RunId = "phase0a-replay-windows-$Viewport-r$Index-$Timestamp"
  $env:PROBE_MODE = "phase0a_replay"
  $env:PROBE_VIEWPORT = $Viewport
  $env:PROBE_RUN_ID = $RunId
  $env:PROBE_DURATION_SCALE = "1.0"
  $env:PROBE_OUTPUT_ROOT = $ResultRoot
  $env:PROBE_REPOSITORY_ROOT = $RepositoryRoot
  $env:PROBE_AUTO_CLOSE = "true"
  $env:PROBE_EXPECTED_REFRESH_RATE = "60"
  $env:PROBE_EXPECTED_DPR = "1"
  $ExecutionCommand = "$Binary [PROBE_MODE=phase0a_replay PROBE_VIEWPORT=$Viewport PROBE_RUN_ID=$RunId PROBE_DURATION_SCALE=1.0 PROBE_EXPECTED_REFRESH_RATE=60 PROBE_EXPECTED_DPR=1]"
  $TemporaryLog = Join-Path $ResultRoot "$RunId.run.log"
  & $Binary 2>&1 | Tee-Object -FilePath $TemporaryLog
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $RunDirectory = Join-Path (Join-Path $ResultRoot "phase0a-replays") $RunId
  $ManifestPath = Join-Path $RunDirectory "manifest.json"
  if (-not (Test-Path $ManifestPath)) {
    throw "Run did not produce manifest.json: $RunDirectory"
  }
  Move-Item -Force $TemporaryLog (Join-Path $RunDirectory "run.log")
  $Manifest = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json
  $Manifest | Add-Member -NotePropertyName gate_mode -NotePropertyValue "phase0a_replay" -Force
  $Manifest | Add-Member -NotePropertyName host_manifest_sha256 -NotePropertyValue $HostChecksum -Force
  $Manifest | Add-Member -NotePropertyName duration_scale -NotePropertyValue 1.0 -Force
  $Manifest | Add-Member -NotePropertyName execution_command -NotePropertyValue $ExecutionCommand -Force
  $Manifest | Add-Member -NotePropertyName build_command -NotePropertyValue "flutter build windows --profile" -Force
  $Manifest | Add-Member -NotePropertyName flutter_version -NotePropertyValue $FlutterVersion -Force
  $Manifest | Add-Member -NotePropertyName dart_version -NotePropertyValue $DartVersion -Force
  $Manifest | Add-Member -NotePropertyName binary_sha256 -NotePropertyValue $BinaryChecksum -Force
  $Manifest.renderer = $Renderer
  $Manifest | ConvertTo-Json -Depth 20 | Set-Content -Path $ManifestPath -Encoding UTF8
  Write-Host "PHASE0A_WINDOWS_RUN_RECORDED $RunDirectory"
}
