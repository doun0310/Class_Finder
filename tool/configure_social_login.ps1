[CmdletBinding()]
param(
    [string]$GoogleIosClientId,
    [string]$KakaoNativeAppKey,
    [string]$KakaoCustomScheme,
    [string]$AndroidConfigPath = "android\social-login.properties",
    [string]$IosConfigPath = "ios\Flutter\SocialLogin.local.xcconfig"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ReversedGoogleClientId {
    param([string]$ClientId)

    if ([string]::IsNullOrWhiteSpace($ClientId)) {
        return "classfinder-google-disabled"
    }

    $parts = $ClientId.Split('.')
    [array]::Reverse($parts)
    return ($parts -join '.')
}

function Get-KakaoScheme {
    param(
        [string]$NativeAppKey,
        [string]$CustomScheme
    )

    if (-not [string]::IsNullOrWhiteSpace($CustomScheme)) {
        return $CustomScheme
    }

    if (-not [string]::IsNullOrWhiteSpace($NativeAppKey)) {
        return "kakao$NativeAppKey"
    }

    return "classfinder-kakao-disabled"
}

function Set-Utf8NoBomContent {
    param(
        [string]$Path,
        [string[]]$Value
    )

    [System.IO.File]::WriteAllLines(
        $Path,
        $Value,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$workspace = Split-Path -Parent $PSScriptRoot
$androidTarget = Join-Path $workspace $AndroidConfigPath
$iosTarget = Join-Path $workspace $IosConfigPath

$googleIosScheme = Get-ReversedGoogleClientId -ClientId $GoogleIosClientId
$kakaoScheme = Get-KakaoScheme -NativeAppKey $KakaoNativeAppKey -CustomScheme $KakaoCustomScheme

$androidDir = Split-Path -Parent $androidTarget
if (-not (Test-Path $androidDir)) {
    New-Item -ItemType Directory -Path $androidDir | Out-Null
}

$iosDir = Split-Path -Parent $iosTarget
if (-not (Test-Path $iosDir)) {
    New-Item -ItemType Directory -Path $iosDir | Out-Null
}

Set-Utf8NoBomContent -Path $androidTarget -Value @(
    "kakaoScheme=$kakaoScheme"
)

Set-Utf8NoBomContent -Path $iosTarget -Value @(
    "GOOGLE_IOS_URL_SCHEME=$googleIosScheme"
    "KAKAO_IOS_URL_SCHEME=$kakaoScheme"
)

Write-Host ""
Write-Host "Social login native config files were generated."
Write-Host "Android: $androidTarget"
Write-Host "iOS: $iosTarget"
