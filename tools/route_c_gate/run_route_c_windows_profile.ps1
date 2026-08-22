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
if (-not $HostFacts.attestation.valid_for_windows_physical_gate) {
  throw "Host manifest is not attested for the Windows physical Gate."
}
if (-not $HostFacts.attestation.physical_machine_confirmed -or
    -not $HostFacts.attestation.local_console_confirmed -or
    -not $HostFacts.attestation.power_mode_confirmed_best_performance -or
    -not $HostFacts.device.plugged_in) {
  throw "Physical-machine, local-console, power and plugged-in attestations must all pass."
}
if (-not $HostFacts.display.local_interactive_session -or
    $HostFacts.session.remote_desktop -or $HostFacts.session.virtual_machine) {
  throw "The Gate requires a local physical Console session."
}
$ActualSessionName = [string]$env:SESSIONNAME
$ProcessSessionId = (Get-Process -Id $PID).SessionId
if ($ProcessSessionId -le 0 -or
    (-not [string]::IsNullOrWhiteSpace($ActualSessionName) -and
      $ActualSessionName -ne "Console") -or
    [string]$HostFacts.session.session_name -ne "Console") {
  throw "The Gate runner must execute in the recorded visible Console session, not an SSH service or RDP session."
}
if ($HostFacts.display.refresh_rate_hz -le 0 -or $HostFacts.display.scale_percent -ne 100) {
  throw "The Gate requires a recorded refresh rate and 100% display scaling."
}
if ([string]::IsNullOrWhiteSpace($HostFacts.runtime.renderer) -or
    $HostFacts.runtime.renderer -match "FILL_|UNKNOWN") {
  throw "Record the actual Flutter renderer before running."
}
$RecordedHostValues = @(
  $HostFacts.device.os_caption,
  $HostFacts.device.os_version,
  $HostFacts.device.os_build,
  $HostFacts.device.cpu_model,
  $HostFacts.device.gpu_name,
  $HostFacts.device.gpu_driver_version,
  $HostFacts.device.storage_type,
  $HostFacts.device.power_mode
  $HostFacts.session.session_name
)
if ($HostFacts.device.ram_gib -le 0 -or
    ($RecordedHostValues | Where-Object {
      [string]::IsNullOrWhiteSpace($_) -or $_ -match "FILL_|UNKNOWN"
    })) {
  throw "Record all physical Windows host facts before running."
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
$Launcher = Join-Path $RepositoryRoot "build/windows/x64/runner/Profile/wuxia_idle.exe"
$AppPayload = Join-Path $RepositoryRoot "build/windows/x64/runner/Profile/data/app.so"
if (-not (Test-Path $Launcher)) { throw "Root production Profile launcher not found: $Launcher" }
if (-not (Test-Path $AppPayload)) { throw "Root production Profile AOT payload not found: $AppPayload" }
$BinaryChecksum = (Get-FileHash -Algorithm SHA256 $AppPayload).Hash.ToLowerInvariant()
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
    "--battle-profile-native-content-viewport=true",
    "--battle-profile-auto-close=true"
  )
  & $Launcher @Arguments 2>&1 | Tee-Object -FilePath (Join-Path $RunDirectory "run.log")
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
    schema = "route-c-windows-production-run-v2"
    run_id = $RunId
    app_package = "wuxia_idle"
    route_id = "phase0a_battle_profile"
    commit = $ActualCommit
    binary_sha256 = $BinaryChecksum
    fixture_sha256 = $ActualFixtureChecksum
    host_manifest_sha256 = $HostChecksum
    viewport = $Viewport
    windows_physical_attested = [bool]$HostFacts.attestation.valid_for_windows_physical_gate
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
