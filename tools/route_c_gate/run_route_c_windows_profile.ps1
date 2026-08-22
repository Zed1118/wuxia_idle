param(
  [ValidateSet("1280x720", "1440x900")]
  [string]$Viewport = "1280x720",
  [ValidateRange(1, 20)]
  [int]$Repeat = 1,
  [Parameter(Mandatory = $true)]
  [string]$HostManifest,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedCommit,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedFixtureChecksum,
  [string]$ResultRoot = "",
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$HostManifest = (Resolve-Path $HostManifest).Path
if ([string]::IsNullOrWhiteSpace($ResultRoot)) {
  $ResultRoot = Join-Path $RepositoryRoot "build/route_c_windows_gate"
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
    -not $HostFacts.attestation.power_mode_confirmed_best_performance -or
    -not $HostFacts.device.gpu_is_integrated -or
    -not $HostFacts.device.plugged_in) {
  throw "CPU, GPU, RAM, power, integrated-GPU and plugged-in attestations must all pass."
}
if (-not $HostFacts.display.local_interactive_session -or
    $HostFacts.session.remote_desktop -or $HostFacts.session.virtual_machine) {
  throw "The Gate requires a local physical Console session."
}
if ($HostFacts.display.refresh_rate_hz -ne 60 -or $HostFacts.display.scale_percent -ne 100) {
  throw "The Gate requires 60Hz and 100% display scaling."
}
if ($HostFacts.runtime.renderer -match "FILL_|UNKNOWN") {
  throw "Record the actual Flutter renderer before running."
}

$ActualCommit = (& git -C $RepositoryRoot rev-parse HEAD | Out-String).Trim()
if ($ActualCommit -ne $ExpectedCommit) {
  throw "Commit mismatch. Expected $ExpectedCommit, found $ActualCommit."
}
$Dirty = (& git -C $RepositoryRoot status --porcelain | Out-String).Trim()
if (-not [string]::IsNullOrWhiteSpace($Dirty)) {
  throw "Physical Gate runs require a clean worktree."
}
$FixturePath = Join-Path $RepositoryRoot "data/phase0a_debug_battle.yaml"
$ActualFixtureChecksum = (Get-FileHash -Algorithm SHA256 $FixturePath).Hash.ToLowerInvariant()
if ($ActualFixtureChecksum -ne $ExpectedFixtureChecksum.ToLowerInvariant()) {
  throw "Production fixture checksum mismatch."
}

Set-Location $RepositoryRoot
if (-not $SkipBuild) {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  flutter build windows --profile
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
$Binary = Join-Path $RepositoryRoot "build/windows/x64/runner/Profile/wuxia_idle.exe"
if (-not (Test-Path $Binary)) { throw "Root production Profile binary not found: $Binary" }
$BinaryChecksum = (Get-FileHash -Algorithm SHA256 $Binary).Hash.ToLowerInvariant()
$HostChecksum = (Get-FileHash -Algorithm SHA256 $HostManifest).Hash.ToLowerInvariant()
$ViewportParts = $Viewport.Split("x")
$ExpectedWidth = [int]$ViewportParts[0]
$ExpectedHeight = [int]$ViewportParts[1]

for ($Index = 1; $Index -le $Repeat; $Index++) {
  $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  $RunId = "route-c-windows-$Viewport-r$Index-$Timestamp"
  $RunDirectory = Join-Path $ResultRoot $RunId
  New-Item -ItemType Directory -Force -Path $RunDirectory | Out-Null
  $Arguments = @(
    "--visual-route=phase0a_battle_profile",
    "--battle-profile-run-id=$RunId",
    "--battle-profile-output=$RunDirectory",
    "--battle-profile-sample-seconds=60",
    "--battle-profile-warmup-seconds=12",
    "--battle-profile-cooldown-seconds=30",
    "--battle-profile-viewport=$Viewport",
    "--battle-profile-auto-close=true"
  )
  & $Binary @Arguments 2>&1 | Tee-Object -FilePath (Join-Path $RunDirectory "run.log")
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $SummaryPath = Join-Path $RunDirectory "summary.json"
  if (-not (Test-Path $SummaryPath)) { throw "$RunId did not produce summary.json." }
  $Summary = Get-Content -Raw -Path $SummaryPath | ConvertFrom-Json
  $RssLimit = [double]$Summary.rss_start_bytes * 1.10 + 67108864
  $CompositePass =
    $Summary.sampled_frames -ge 3000 -and
    [double]$Summary.p99_total_span_ms -lt 16.6 -and
    $Summary.max_consecutive_severe_frames -le 1 -and
    $Summary.frame_streak_gate_passes -and
    $Summary.gc_telemetry_status -eq "GC_TELEMETRY_COLLECTED" -and
    [double]$Summary.logical_width -eq $ExpectedWidth -and
    [double]$Summary.logical_height -eq $ExpectedHeight -and
    [double]$Summary.device_pixel_ratio -eq 1.0 -and
    [double]$Summary.rss_end_bytes -le $RssLimit

  $Manifest = [ordered]@{
    schema = "route-c-windows-production-run-v1"
    run_id = $RunId
    app_package = "wuxia_idle"
    route_id = "phase0a_battle_profile"
    commit = $ActualCommit
    binary_sha256 = $BinaryChecksum
    fixture_sha256 = $ActualFixtureChecksum
    host_manifest_sha256 = $HostChecksum
    viewport = $Viewport
    minimum_spec_attested = [bool]$HostFacts.attestation.valid_for_minimum_spec_gate
    local_console = [bool]$HostFacts.display.local_interactive_session
    renderer = [string]$HostFacts.runtime.renderer
    composite_gate = $(if ($CompositePass) { "PASS" } else { "FAIL" })
    raw_evidence = [ordered]@{
      frames_jsonl = "frames.jsonl"
      memory_gc_jsonl = "memory_gc.jsonl"
      summary_json = "summary.json"
      run_log = "run.log"
    }
  }
  $Manifest | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $RunDirectory "manifest.json") -Encoding UTF8
  if (-not $CompositePass) { throw "$RunId failed the production composite Gate." }
  Write-Host "ROUTE_C_WINDOWS_RUN_PASS $RunDirectory"
}
