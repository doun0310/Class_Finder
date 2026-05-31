[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,
    [ValidateSet("apk", "appbundle", "web")]
    [string]$Target = "appbundle",
    [string]$GoogleServerClientId,
    [string]$GoogleIosClientId,
    [string]$KakaoNativeAppKey,
    [string]$KakaoCustomScheme,
    [string]$AppleServiceId,
    [string]$AppleRedirectUri,
    [string]$BackendEnvPath = "backend\.env.production",
    [switch]$RequireGoogle,
    [switch]$RequireKakao,
    [switch]$RequireApple,
    [switch]$SkipChecks,
    [switch]$CheckBackendEnv,
    [switch]$SkipNativeConfig,
    [switch]$AllowDebugSigning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$validator = Join-Path $PSScriptRoot "validate_release_config.ps1"
$socialConfigurator = Join-Path $PSScriptRoot "configure_social_login.ps1"

$validationParams = @{
    ApiBaseUrl = $ApiBaseUrl
    Target = $Target
    BackendEnvPath = $BackendEnvPath
}
if (-not [string]::IsNullOrWhiteSpace($GoogleServerClientId)) {
    $validationParams.GoogleServerClientId = $GoogleServerClientId
}
if (-not [string]::IsNullOrWhiteSpace($GoogleIosClientId)) {
    $validationParams.GoogleIosClientId = $GoogleIosClientId
}
if (-not [string]::IsNullOrWhiteSpace($KakaoNativeAppKey)) {
    $validationParams.KakaoNativeAppKey = $KakaoNativeAppKey
}
if (-not [string]::IsNullOrWhiteSpace($KakaoCustomScheme)) {
    $validationParams.KakaoCustomScheme = $KakaoCustomScheme
}
if (-not [string]::IsNullOrWhiteSpace($AppleServiceId)) {
    $validationParams.AppleServiceId = $AppleServiceId
}
if (-not [string]::IsNullOrWhiteSpace($AppleRedirectUri)) {
    $validationParams.AppleRedirectUri = $AppleRedirectUri
}

if ($RequireGoogle) { $validationParams.RequireGoogle = $true }
if ($RequireKakao) { $validationParams.RequireKakao = $true }
if ($RequireApple) { $validationParams.RequireApple = $true }
if ($CheckBackendEnv) { $validationParams.CheckBackendEnv = $true }
if ($AllowDebugSigning) { $validationParams.AllowDebugSigning = $true }

& $validator @validationParams

if (-not $SkipNativeConfig -and $Target -in @("apk", "appbundle")) {
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
    & $socialConfigurator @configureParams
}

Push-Location $workspace
try {
    if (-not $SkipChecks) {
        flutter analyze
        if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed with exit code $LASTEXITCODE." }

        flutter test
        if ($LASTEXITCODE -ne 0) { throw "flutter test failed with exit code $LASTEXITCODE." }

        Push-Location (Join-Path $workspace "backend")
        try {
            npm run build
            if ($LASTEXITCODE -ne 0) { throw "backend build failed with exit code $LASTEXITCODE." }

            npm run test:e2e
            if ($LASTEXITCODE -ne 0) { throw "backend e2e tests failed with exit code $LASTEXITCODE." }
        }
        finally {
            Pop-Location
        }
    }

    $dartDefines = @(
        "--dart-define=API_BASE_URL=$ApiBaseUrl"
    )
    if (-not [string]::IsNullOrWhiteSpace($GoogleServerClientId)) {
        $dartDefines += "--dart-define=GOOGLE_SERVER_CLIENT_ID=$GoogleServerClientId"
    }
    if (-not [string]::IsNullOrWhiteSpace($GoogleIosClientId)) {
        $dartDefines += "--dart-define=GOOGLE_IOS_CLIENT_ID=$GoogleIosClientId"
    }
    if (-not [string]::IsNullOrWhiteSpace($KakaoNativeAppKey)) {
        $dartDefines += "--dart-define=KAKAO_NATIVE_APP_KEY=$KakaoNativeAppKey"
    }
    if (-not [string]::IsNullOrWhiteSpace($KakaoCustomScheme)) {
        $dartDefines += "--dart-define=KAKAO_CUSTOM_SCHEME=$KakaoCustomScheme"
    }
    if (-not [string]::IsNullOrWhiteSpace($AppleServiceId)) {
        $dartDefines += "--dart-define=APPLE_SERVICE_ID=$AppleServiceId"
    }
    if (-not [string]::IsNullOrWhiteSpace($AppleRedirectUri)) {
        $dartDefines += "--dart-define=APPLE_REDIRECT_URI=$AppleRedirectUri"
    }

    $buildArgs = switch ($Target) {
        "apk" { @("build", "apk", "--release") }
        "appbundle" { @("build", "appbundle", "--release") }
        "web" { @("build", "web", "--release") }
    }

    flutter @buildArgs @dartDefines
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
