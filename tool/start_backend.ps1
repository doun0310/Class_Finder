param(
  [int]$BackendPort = 3001,
  [switch]$SkipMigrate
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot 'backend'
$dartToolDir = Join-Path $repoRoot '.dart_tool'
$pidFile = Join-Path $dartToolDir 'backend.pid'
$stdoutLog = Join-Path $dartToolDir 'backend.stdout.log'
$stderrLog = Join-Path $dartToolDir 'backend.stderr.log'
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

function Invoke-BackendCommand {
  param(
    [string]$FilePath,
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  return $LASTEXITCODE
}

function Invoke-MigrateDeploy {
  Write-Host 'Applying Prisma migrations...'
  $exitCode = Invoke-BackendCommand -FilePath 'npx.cmd' -Arguments @('prisma', 'migrate', 'deploy')
  return $exitCode -eq 0
}

function Ensure-DatabaseReady {
  if (Invoke-MigrateDeploy) {
    return
  }

  Write-Host 'Migration failed. Attempting to start PostgreSQL with docker compose...'
  $dockerExitCode = Invoke-BackendCommand -FilePath 'docker' -Arguments @('compose', 'up', '-d')
  if ($dockerExitCode -ne 0) {
    throw 'Prisma migration failed and Docker PostgreSQL could not be started. Start Docker Desktop or another PostgreSQL server, then retry.'
  }

  $deadline = (Get-Date).AddSeconds(40)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    if (Invoke-MigrateDeploy) {
      return
    }
  }

  throw 'PostgreSQL did not become ready in time for prisma migrate deploy.'
}

if (Test-BackendHealthy -Url $healthUrl) {
  Write-Host "Backend already running at $healthUrl"
  exit 0
}

New-Item -ItemType Directory -Force $dartToolDir | Out-Null

Push-Location $backendDir
try {
  if (-not (Test-Path (Join-Path $backendDir 'node_modules'))) {
    Write-Host 'Installing backend dependencies...'
    & npm.cmd install
    if ($LASTEXITCODE -ne 0) {
      throw 'npm install failed.'
    }
  }

  Write-Host 'Generating Prisma client...'
  & npx.cmd prisma generate
  if ($LASTEXITCODE -ne 0) {
    throw 'Prisma client generation failed.'
  }

  if (-not $SkipMigrate) {
    Ensure-DatabaseReady
  }
} finally {
  Pop-Location
}

Set-Content -Path $stdoutLog -Value ''
Set-Content -Path $stderrLog -Value ''

$process = Start-Process `
  -FilePath 'npm.cmd' `
  -ArgumentList @('run', 'start:dev') `
  -WorkingDirectory $backendDir `
  -WindowStyle Hidden `
  -RedirectStandardOutput $stdoutLog `
  -RedirectStandardError $stderrLog `
  -PassThru

Set-Content -Path $pidFile -Value $process.Id

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
  $process.Refresh()
  if ($process.HasExited) {
    break
  }

  if (Test-BackendHealthy -Url $healthUrl) {
    Write-Host "Backend started at $healthUrl"
    exit 0
  }

  Start-Sleep -Milliseconds 750
}

$stderrTail = ''
if (Test-Path $stderrLog) {
  $stderrTail = (Get-Content -Path $stderrLog -Tail 20) -join [Environment]::NewLine
}

throw "Backend failed to start. Check logs:`n$stdoutLog`n$stderrLog`n$stderrTail"
