param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot '.dart_tool\backend.pid'

if (-not (Test-Path $pidFile)) {
  Write-Host 'No tracked backend process.'
  exit 0
}

$rawPid = Get-Content -Path $pidFile -Raw
$backendPid = 0

if (-not [int]::TryParse($rawPid.Trim(), [ref]$backendPid)) {
  Remove-Item -Path $pidFile -ErrorAction SilentlyContinue
  throw 'Invalid backend pid file.'
}

try {
  $process = Get-Process -Id $backendPid -ErrorAction Stop
  Stop-Process -Id $process.Id -Force
  Write-Host "Stopped backend process $backendPid"
} catch {
  Write-Host "Backend process $backendPid is not running."
} finally {
  Remove-Item -Path $pidFile -ErrorAction SilentlyContinue
}
