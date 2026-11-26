param([switch]$Release)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$workspace = Split-Path $project -Parent
$localTools = Join-Path $workspace '.tools'
$flutter = Join-Path $localTools 'flutter/bin/flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) {
    $flutter = (Get-Command flutter -ErrorAction Stop).Source
}
$jdk = Get-ChildItem (Join-Path $localTools 'jdk') -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($jdk) { $env:JAVA_HOME = $jdk.FullName }
$sdk = Join-Path $localTools 'android-sdk'
if (Test-Path -LiteralPath $sdk) { $env:ANDROID_HOME = $sdk }
if (Test-Path -LiteralPath $localTools) { $env:GRADLE_USER_HOME = Join-Path $localTools 'gradle-cache' }
Push-Location $project
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }
    $mode = if ($Release) { '--release' } else { '--debug' }
    & $flutter build apk $mode --target-platform android-arm64
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed. Review the Gradle output.' }
    Write-Host 'APK output: build/app/outputs/flutter-apk/'
} finally { Pop-Location }
