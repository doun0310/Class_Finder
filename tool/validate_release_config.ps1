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
    [string]$AndroidKeyPropertiesPath = "android\key.properties",
    [switch]$RequireGoogle,
    [switch]$RequireKakao,
    [switch]$RequireApple,
    [switch]$CheckBackendEnv,
    [switch]$AllowDebugSigning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-IfBlank {
    param(
        [string]$Value,
        [string]$Message,
        [ref]$Errors
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $Errors.Value += $Message
    }
}

function Test-LocalHostUrl {
    param([string]$Value)

    return $Value -match '^https?://(localhost|127\.0\.0\.1|10\.0\.2\.2|0\.0\.0\.0)(:\d+)?(/|$)'
}

function Convert-LinesToMap {
    param([string[]]$Lines)

    $map = @{}
    foreach ($line in $Lines) {
        $parts = $line -split '=', 2
        if ($parts.Length -eq 2) {
            $map[$parts[0].Trim()] = $parts[1].Trim()
        }
    }

    return $map
}

function Read-PropertyFile {
    param([string]$Path)

    $lines = Get-Content $Path | Where-Object {
        $_ -and -not $_.TrimStart().StartsWith('#')
    }
    return Convert-LinesToMap -Lines $lines
}

$workspace = Split-Path -Parent $PSScriptRoot
$errors = @()
$warnings = @()

switch ($Target) {
    "web" {
        if (-not (Test-Path (Join-Path $workspace "web"))) {
            $errors += "Target 'web' is not enabled for this Flutter project. Run 'flutter create . --platforms web' before building for web."
        }
    }
    default {
        if (-not (Test-Path (Join-Path $workspace "android"))) {
            $errors += "Android platform files were not found for target '$Target'."
        }
    }
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $errors += "API_BASE_URL is empty."
} elseif (Test-LocalHostUrl -Value $ApiBaseUrl) {
    $errors += "API_BASE_URL points to a local host. A public HTTPS API URL is required for release."
} elseif ($ApiBaseUrl -notmatch '^https://') {
    $warnings += "API_BASE_URL is not using HTTPS."
}

if ($RequireGoogle) {
    if ([string]::IsNullOrWhiteSpace($GoogleServerClientId) -and [string]::IsNullOrWhiteSpace($GoogleIosClientId)) {
        $errors += "Google login is required but both GOOGLE_SERVER_CLIENT_ID and GOOGLE_IOS_CLIENT_ID are missing."
    } elseif ([string]::IsNullOrWhiteSpace($GoogleServerClientId)) {
        $warnings += "GOOGLE_SERVER_CLIENT_ID is empty. This may block server-side token verification."
    } elseif ([string]::IsNullOrWhiteSpace($GoogleIosClientId)) {
        $warnings += "GOOGLE_IOS_CLIENT_ID is empty. iOS Google Sign-In will not be ready."
    }
}

if ($RequireKakao) {
    Add-IfBlank -Value $KakaoNativeAppKey -Message "Kakao login is required but KAKAO_NATIVE_APP_KEY is missing." -Errors ([ref]$errors)
    if (-not [string]::IsNullOrWhiteSpace($KakaoNativeAppKey) -and [string]::IsNullOrWhiteSpace($KakaoCustomScheme)) {
        $warnings += "KAKAO_CUSTOM_SCHEME is empty. The native app key will be used to derive the callback scheme."
    }
}

if ($RequireApple) {
    Add-IfBlank -Value $AppleServiceId -Message "Apple login is required but APPLE_SERVICE_ID is missing." -Errors ([ref]$errors)
    Add-IfBlank -Value $AppleRedirectUri -Message "Apple login is required but APPLE_REDIRECT_URI is missing." -Errors ([ref]$errors)
}

if ($CheckBackendEnv) {
    $backendEnvFullPath = Join-Path $workspace $BackendEnvPath
    if (-not (Test-Path $backendEnvFullPath)) {
        $errors += "Backend environment file was not found: $BackendEnvPath"
    } else {
        $backendMap = Read-PropertyFile -Path $backendEnvFullPath
        Add-IfBlank -Value $backendMap['DATABASE_URL'] -Message "DATABASE_URL is empty in the backend environment file." -Errors ([ref]$errors)
        Add-IfBlank -Value $backendMap['CORS_ORIGIN'] -Message "CORS_ORIGIN is empty in the backend environment file." -Errors ([ref]$errors)
        if ($backendMap.ContainsKey('CORS_ORIGIN') -and $backendMap['CORS_ORIGIN'] -match 'localhost|127\.0\.0\.1') {
            $warnings += "CORS_ORIGIN still contains a local host address."
        }
    }
}

if ($Target -in @("apk", "appbundle")) {
    $androidKeyPropertiesFullPath = Join-Path $workspace $AndroidKeyPropertiesPath

    if ($AllowDebugSigning) {
        $warnings += "AllowDebugSigning is enabled. Android release output may be signed with the debug keystore."
    } elseif (-not (Test-Path $androidKeyPropertiesFullPath)) {
        $errors += "Android release signing is not configured. Create $AndroidKeyPropertiesPath from android/key.properties.example."
    } else {
        $keyMap = Read-PropertyFile -Path $androidKeyPropertiesFullPath
        Add-IfBlank -Value $keyMap['storeFile'] -Message "storeFile is empty in $AndroidKeyPropertiesPath." -Errors ([ref]$errors)
        Add-IfBlank -Value $keyMap['storePassword'] -Message "storePassword is empty in $AndroidKeyPropertiesPath." -Errors ([ref]$errors)
        Add-IfBlank -Value $keyMap['keyAlias'] -Message "keyAlias is empty in $AndroidKeyPropertiesPath." -Errors ([ref]$errors)
        Add-IfBlank -Value $keyMap['keyPassword'] -Message "keyPassword is empty in $AndroidKeyPropertiesPath." -Errors ([ref]$errors)

        $storeFilePath = $keyMap['storeFile']
        if (-not [string]::IsNullOrWhiteSpace($storeFilePath)) {
            $androidDir = Split-Path -Parent $androidKeyPropertiesFullPath
            $resolvedStoreFile = if ([System.IO.Path]::IsPathRooted($storeFilePath)) {
                $storeFilePath
            } else {
                Join-Path $androidDir $storeFilePath
            }

            if (-not (Test-Path $resolvedStoreFile)) {
                $errors += "Android keystore file was not found: $resolvedStoreFile"
            }
        }
    }
}

Write-Host ""
Write-Host "Release Configuration Check"
Write-Host "Target: $Target"
Write-Host "API_BASE_URL: $ApiBaseUrl"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach ($warning in $warnings) {
        Write-Host " - $warning"
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    foreach ($errorMessage in $errors) {
        Write-Host " - $errorMessage"
    }
    throw "Release configuration is invalid."
}

Write-Host ""
Write-Host "Release configuration looks valid."
