param(
  [string]$EntryPoint = 'lib/main.dart',
  [string]$DeviceId,
  [string]$ApiBaseUrl,
  [int]$BackendPort = 3001,
  [switch]$KeepBackend,
  [string]$SocialEnvPath = 'social-login.env',
  [string]$GoogleServerClientId,
  [string]$GoogleIosClientId,
  [string]$KakaoNativeAppKey,
  [string]$KakaoCustomScheme,
  [string]$AppleServiceId,
  [string]$AppleRedirectUri,
  [switch]$SkipSocialEnv,
  [switch]$SkipNativeConfig
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$startScript = Join-Path $PSScriptRoot 'start_backend.ps1'
$stopScript = Join-Path $PSScriptRoot 'stop_backend.ps1'
$socialConfigurator = Join-Path $PSScriptRoot 'configure_social_login.ps1'
$healthUrl = "http://127.0.0.1:$BackendPort/health"

function Convert-LinesToMap {
  param([string[]]$Lines)

  $map = @{}
  foreach ($line in $Lines) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
      continue
    }

    $parts = $trimmed -split '=', 2
    if ($parts.Length -eq 2) {
      $map[$parts[0].Trim()] = $parts[1].Trim()
    }
  }

  return $map
}

function Get-ConfiguredValue {
  param(
    [string]$CurrentValue,
    [hashtable]$Values,
    [string]$Key
  )

  if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
    return $CurrentValue
  }

  if ($Values.ContainsKey($Key)) {
    return $Values[$Key]
  }

  return $CurrentValue
}

function Test-BackendHealthy {
  param([string]$Url)

  try {
    $response = Invoke-RestMethod -Uri $Url -TimeoutSec 2
    return $response.ok -eq $true
  } catch {
    return $false
  }
}

$socialValues = @{}
if (-not $SkipSocialEnv) {
  $resolvedSocialEnvPath = if ([System.IO.Path]::IsPathRooted($SocialEnvPath)) {
    $SocialEnvPath
  } else {
    Join-Path $repoRoot $SocialEnvPath
  }

  if (Test-Path $resolvedSocialEnvPath) {
    $socialValues = Convert-LinesToMap -Lines (Get-Content $resolvedSocialEnvPath)
    Write-Host "Loaded social login settings from $resolvedSocialEnvPath"
  }
}

$ApiBaseUrl = Get-ConfiguredValue -CurrentValue $ApiBaseUrl -Values $socialValues -Key 'API_BASE_URL'
$GoogleServerClientId = Get-ConfiguredValue -CurrentValue $GoogleServerClientId -Values $socialValues -Key 'GOOGLE_SERVER_CLIENT_ID'
$GoogleIosClientId = Get-ConfiguredValue -CurrentValue $GoogleIosClientId -Values $socialValues -Key 'GOOGLE_IOS_CLIENT_ID'
$KakaoNativeAppKey = Get-ConfiguredValue -CurrentValue $KakaoNativeAppKey -Values $socialValues -Key 'KAKAO_NATIVE_APP_KEY'
$KakaoCustomScheme = Get-ConfiguredValue -CurrentValue $KakaoCustomScheme -Values $socialValues -Key 'KAKAO_CUSTOM_SCHEME'
$AppleServiceId = Get-ConfiguredValue -CurrentValue $AppleServiceId -Values $socialValues -Key 'APPLE_SERVICE_ID'
$AppleRedirectUri = Get-ConfiguredValue -CurrentValue $AppleRedirectUri -Values $socialValues -Key 'APPLE_REDIRECT_URI'

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  if ($DeviceId -match '^emulator-') {
    $ApiBaseUrl = "http://10.0.2.2:$BackendPort"
  } else {
    $ApiBaseUrl = "http://localhost:$BackendPort"
  }
}

if (-not $SkipNativeConfig) {
  $configureParams = @{}
  if (-not [string]::IsNullOrWhiteSpace($GoogleIosClientId)) {
    $configureParams.GoogleIosClientId = $GoogleIosClientId
  }
  if (-not [string]::IsNullOrWhiteSpace($KakaoNativeAppKey)) {
    $configureParams.KakaoNativeAppKey = $KakaoNativeAppKey
  }
  if (-not [string]::IsNullOrWhiteSpace($KakaoCustomScheme)) {
    $configureParams.KakaoCustomScheme = $KakaoCustomScheme
  }

  if ($configureParams.Count -gt 0) {
    & $socialConfigurator @configureParams
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

if (-not [string]::IsNullOrWhiteSpace($GoogleServerClientId)) {
  $flutterArgs += "--dart-define=GOOGLE_SERVER_CLIENT_ID=$GoogleServerClientId"
}
if (-not [string]::IsNullOrWhiteSpace($GoogleIosClientId)) {
  $flutterArgs += "--dart-define=GOOGLE_IOS_CLIENT_ID=$GoogleIosClientId"
}
if (-not [string]::IsNullOrWhiteSpace($KakaoNativeAppKey)) {
  $flutterArgs += "--dart-define=KAKAO_NATIVE_APP_KEY=$KakaoNativeAppKey"
}
if (-not [string]::IsNullOrWhiteSpace($KakaoCustomScheme)) {
  $flutterArgs += "--dart-define=KAKAO_CUSTOM_SCHEME=$KakaoCustomScheme"
}
if (-not [string]::IsNullOrWhiteSpace($AppleServiceId)) {
  $flutterArgs += "--dart-define=APPLE_SERVICE_ID=$AppleServiceId"
}
if (-not [string]::IsNullOrWhiteSpace($AppleRedirectUri)) {
  $flutterArgs += "--dart-define=APPLE_REDIRECT_URI=$AppleRedirectUri"
}

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
