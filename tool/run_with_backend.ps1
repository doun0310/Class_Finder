param(
  [string]$EntryPoint = 'lib/main.dart',
  [string]$DeviceId,
  [string]$ApiBaseUrl,
  [int]$BackendPort = 3001,
  [switch]$KeepBackend
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$startScript = Join-Path $PSScriptRoot 'start_backend.ps1'
$stopScript = Join-Path $PSScriptRoot 'stop_backend.ps1'
$healthUrl = "http://127.0.0.1:$BackendPort/health"

function Test-BackendHealthy {
  param([string]$Url)

  try {
    $response = Invoke-RestMethod -Uri $Url -TimeoutSec 2
    return $response.ok -eq $true
  } catch {
    return $false
  }
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  if ($DeviceId -match '^emulator-') {
    $ApiBaseUrl = "http://10.0.2.2:$BackendPort"
  } else {
    $ApiBaseUrl = "http://localhost:$BackendPort"
  }
}

$startedBackend = $false
if (-not (Test-BackendHealthy -Url $healthUrl)) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $startScript -BackendPort $BackendPort
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to start backend.'
  }
  $startedBackend = $true
} else {
  Write-Host "Backend already running at $healthUrl"
}

$flutterArgs = @(
  'run',
  '--target',
  $EntryPoint,
  "--dart-define=API_BASE_URL=$ApiBaseUrl"
)

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $flutterArgs += @('-d', $DeviceId)
}

Write-Host "Launching Flutter with API_BASE_URL=$ApiBaseUrl"

Push-Location $repoRoot
try {
  & flutter @flutterArgs
  $flutterExitCode = $LASTEXITCODE
} finally {
  Pop-Location
  if ($startedBackend -and -not $KeepBackend) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $stopScript
  }
}

exit $flutterExitCode
