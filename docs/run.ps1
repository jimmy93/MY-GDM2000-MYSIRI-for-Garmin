# 1. Get SDK path and clean trailing slashes/spaces
$sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg").Trim().TrimEnd('\')

# 2. Define script paths
$connectiqBat = Join-Path $sdk "bin\connectiq.bat"
$monkeydoBat   = Join-Path $sdk "bin\monkeydo.bat"

# 3. Start simulator if not already running
if (-not (Get-Process "connectiq*" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting Garmin Connect IQ Simulator..." -ForegroundColor Cyan
    
    # Launch connectiq.bat directly
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$connectiqBat`"" -WindowStyle Hidden
    
    Start-Sleep -Seconds 5  # Allow simulator time to boot
}

# 4. Set directory to project root so build\ references work
Set-Location -Path "$PSScriptRoot\.."

# 5. Push app files to the simulator
# & $monkeydoBat "build\rso_widget.iq" fenix3
# & $monkeydoBat "build\rso_datafield.iq" fenix3

# & $sdk\bin\monkeydo.bat "build\rso_widget.prg" fenix3
& $sdk\bin\monkeydo.bat "build\rso_datafield.prg" fenix3