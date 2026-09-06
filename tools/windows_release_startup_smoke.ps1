param(
  [Parameter(Mandatory = $true)][string]$ReleaseDirectory,
  [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$releasePath = (Resolve-Path $ReleaseDirectory).Path
$null = New-Item -ItemType Directory -Force -Path $OutputDirectory
$outputPath = (Resolve-Path $OutputDirectory).Path
$executable = Join-Path $releasePath 'wuxia_idle.exe'
if (-not (Test-Path $executable)) { throw "Missing release executable: $executable" }

$result = [ordered]@{
  schema = 1
  source_sha = $env:GITHUB_SHA
  evidence_kind = 'windows_ci_release_startup_only'
  os = [System.Environment]::OSVersion.VersionString
  executable_sha256 = (Get-FileHash -Algorithm SHA256 $executable).Hash.ToLowerInvariant()
  started_at_utc = [DateTime]::UtcNow.ToString('o')
  status = 'FAIL'
  window_observed = $false
  sampled_seconds = 0
  limitation = 'No keyboard, audio, GPU performance or human acceptance is asserted.'
}
$child = $null
try {
  $child = Start-Process -FilePath $executable -WorkingDirectory $releasePath -PassThru `
    -RedirectStandardOutput (Join-Path $outputPath 'stdout.log') `
    -RedirectStandardError (Join-Path $outputPath 'stderr.log')
  $result.pid = $child.Id
  $watch = [Diagnostics.Stopwatch]::StartNew()
  $windowAt = $null
  while ($watch.Elapsed.TotalSeconds -lt 45) {
    $child.Refresh()
    if ($child.HasExited) { throw "Release exited during startup (code $($child.ExitCode))." }
    if ($child.MainWindowHandle -ne [IntPtr]::Zero) {
      if ($null -eq $windowAt) { $windowAt = $watch.Elapsed.TotalSeconds }
      $result.window_observed = $true
      $result.window_title = $child.MainWindowTitle
    }
    $result.sampled_seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 2)
    if ($null -ne $windowAt -and $watch.Elapsed.TotalSeconds - $windowAt -ge 15) {
      $result.status = 'PASS'
      break
    }
    Start-Sleep -Milliseconds 250
  }
  if ($result.status -ne 'PASS') { throw 'No stable native window within the startup deadline.' }
} catch {
  $result.error = $_.Exception.Message
} finally {
  # This fresh CI runner owns this child and its new save. Never enumerate or
  # terminate other processes by executable name.
  if ($null -ne $child) {
    $child.Refresh()
    if (-not $child.HasExited) { Stop-Process -Id $child.Id -Force }
  }
  $result.finished_at_utc = [DateTime]::UtcNow.ToString('o')
  $result | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $outputPath 'startup.json')
}
if ($result.status -ne 'PASS') { throw $result.error }
Write-Output "WINDOWS_RELEASE_STARTUP_PASS: $($result.sampled_seconds)s; $($result.window_title)"
