# build.ps1 -- Build both MY RSO Grid app types for the Connect IQ simulator/device.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File build.ps1
#   powershell -ExecutionPolicy Bypass -File build.ps1 -Device fenix3
#   powershell -ExecutionPolicy Bypass -File build.ps1 -Device fenix3 -Selftest
#
# Locates the installed Connect IQ SDK via the Garmin SDK Manager config,
# finds the bundled/available Java, and compiles the data field + widget.

param(
    [string]$Device = "fenix3",
    [switch]$Selftest
)

$ErrorActionPreference = "Stop"

# --- Locate SDK ---
$cfg = "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
if (-not (Test-Path $cfg)) { throw "SDK not found: $cfg" }
$sdk = (Get-Content $cfg | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
Write-Host "SDK: $sdk"

# --- Locate Java (monkeyc needs java on PATH) ---
$javaCandidates = @(
    "$env:JAVA_HOME\bin\java.exe",
    "C:\Program Files\Android\jdk\jdk-8.0.302.8-hotspot\jdk8u302-b08\bin\java.exe",
    "C:\Program Files\Eclipse Adoptium\*\bin\java.exe",
    "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\*\bin\java.exe"
)
$java = $null
foreach ($c in $javaCandidates) {
    $resolved = Get-Item $c -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($resolved) { $java = $resolved.FullName; break }
}
if (-not $java) {
    $cmd = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($cmd) { $java = $cmd.Source }
}
if (-not $java) { throw "Java not found. Install a JRE/JDK (monkeyc requires it)." }
Write-Host "Java: $java"
$env:JAVA_HOME = Split-Path (Split-Path $java -Parent) -Parent
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

$monkeyc = Join-Path $sdk "bin\monkeyc.bat"
if (-not (Test-Path $monkeyc)) { $monkeyc = Join-Path $sdk "bin\monkeyc" }
Write-Host "monkeyc: $monkeyc"

# --- Developer key (create if missing) ---
$key = Join-Path $PSScriptRoot "developer_key.der"
if (-not (Test-Path $key)) {
    Write-Host "No developer key found -- generating one with openssl..."
    $openssl = "C:\Program Files\Git\usr\bin\openssl.exe"
    if (-not (Test-Path $openssl)) { $openssl = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" }
    if (-not (Test-Path $openssl)) { throw "openssl not found to create the developer key" }
    & $openssl genrsa -out developer_key.pem 4096
    & $openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
    Write-Host "Generated developer_key.der"
}

# --- Build both targets ---
$out = Join-Path $PSScriptRoot "build"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$targets = @(
    @{ Jungle = "monkey_datafield.jungle"; Out = "rso_datafield.iq";  Tag = "datafield" },
    @{ Jungle = "monkey_widget.jungle";    Out = "rso_widget.iq";     Tag = "widget" }
)

foreach ($t in $targets) {
    $jungle = Join-Path $PSScriptRoot $t.Jungle
    $o = Join-Path $out $t.Out
    Write-Host ""
    Write-Host "=== Building $($t.Tag): $($t.Out) ==="
    $args = @("-d", $Device, "-o", $o, "-f", $jungle, "-y", $key)
    if ($Selftest) { $args += "-w" }
    # Tests require -t; enable when -Selftest is requested.
    if ($Selftest -and ($t.Tag -eq "widget")) { $args += "-t" }
    & $monkeyc @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BUILD FAILED: $($t.Out) (exit $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
    Write-Host "OK: $o"
}

Write-Host ""
Write-Host "All builds succeeded. Artifacts in $out"
