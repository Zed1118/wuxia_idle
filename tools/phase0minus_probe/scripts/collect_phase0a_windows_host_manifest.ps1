param(
  [string]$OutputPath = "",
  [string]$Operator = $env:USERNAME
)

$ErrorActionPreference = "Stop"
$ProbeDir = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $ProbeDir "config/windows_minimum_spec_manifest.captured.json"
}

$Cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$Gpus = @(Get-CimInstance Win32_VideoController)
$Gpu = $Gpus | Select-Object -First 1
$Computer = Get-CimInstance Win32_ComputerSystem
$Os = Get-CimInstance Win32_OperatingSystem
$Battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$VideoMode = $Gpus | Where-Object { $_.CurrentRefreshRate -gt 0 } | Select-Object -First 1
$RefreshRate = if ($null -ne $VideoMode) { [int]$VideoMode.CurrentRefreshRate } else { 0 }
$LogPixels = (Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name LogPixels -ErrorAction SilentlyContinue).LogPixels
$ScalePercent = if ($null -eq $LogPixels) { 100 } else { [math]::Round($LogPixels / 96 * 100) }
$PowerMode = (& powercfg /getactivescheme 2>$null | Out-String).Trim()
$StorageType = "UNKNOWN"
try {
  $StorageType = ((Get-PhysicalDisk | Select-Object -First 1).MediaType | Out-String).Trim()
} catch {
  $StorageType = "UNKNOWN"
}
$Flutter = flutter --version --machine | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw "flutter --version --machine failed." }
$DartVersion = (& dart --version 2>&1 | Out-String).Trim()
$SessionName = [string]$env:SESSIONNAME
$RemoteDesktop = $SessionName -match "^RDP-"
$LocalInteractive = -not $RemoteDesktop -and -not [string]::IsNullOrWhiteSpace($SessionName)
$ModelText = "$($Computer.Manufacturer) $($Computer.Model)"
$VirtualMachine = $ModelText -match "Virtual|VMware|VirtualBox|KVM|Hyper-V|Parallels"
$PluggedIn = if ($null -eq $Battery) {
  $true
} else {
  @($Battery | Where-Object { $_.BatteryStatus -in @(2, 6, 7, 8, 9, 11) }).Count -gt 0
}

$Manifest = [ordered]@{
  status = "CAPTURED_NOT_ATTESTED"
  operator = $Operator
  captured_at_utc = (Get-Date).ToUniversalTime().ToString("o")
  device = [ordered]@{
    os_caption = [string]$Os.Caption
    os_version = [string]$Os.Version
    os_build = [string]$Os.BuildNumber
    cpu_model = ([string]$Cpu.Name).Trim()
    cpu_physical_cores = [int]$Cpu.NumberOfCores
    cpu_logical_processors = [int]$Cpu.NumberOfLogicalProcessors
    gpu_name = ([string]$Gpu.Name).Trim()
    gpu_driver_version = [string]$Gpu.DriverVersion
    gpu_is_integrated = $false
    ram_gib = [math]::Round([double]$Computer.TotalPhysicalMemory / 1GB, 2)
    storage_type = $StorageType
    power_mode = $PowerMode
    plugged_in = $PluggedIn
  }
  display = [ordered]@{
    refresh_rate_hz = $RefreshRate
    scale_percent = $ScalePercent
    required_logical_viewports = @("1280x720", "1440x900")
    local_interactive_session = $LocalInteractive
  }
  session = [ordered]@{
    session_name = $SessionName
    remote_desktop = $RemoteDesktop
    virtual_machine = $VirtualMachine
  }
  runtime = [ordered]@{
    renderer = "FILL_FROM_FLUTTER_GPU_TRACE"
    flutter_version = [string]$Flutter.frameworkVersion
    flutter_channel = [string]$Flutter.channel
    dart_version = $DartVersion
  }
  attestation = [ordered]@{
    target_cpu_class = "Intel Core i5-8250U class or slower supported target"
    target_gpu_class = "Intel UHD Graphics 620 class integrated GPU"
    target_ram_gib = 8
    valid_for_minimum_spec_gate = $false
    cpu_at_or_below_target = $false
    gpu_at_or_below_target = $false
    ram_matches_target = $false
    power_mode_confirmed_best_performance = $false
    validation_notes = "FILL_AFTER_PHYSICAL_INSPECTION"
  }
}

$Parent = Split-Path -Parent $OutputPath
if (-not (Test-Path $Parent)) { New-Item -ItemType Directory -Path $Parent | Out-Null }
$Manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Captured host facts: $OutputPath"
Write-Host "Gate remains invalid until a human verifies the physical machine, renderer, integrated GPU, local console, and attestation fields."
